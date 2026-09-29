import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';

// ─── Dio Instance ────────────────────────────────────────────────────────────
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.current.apiBaseUrl,
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 45),
    sendTimeout: const Duration(seconds: 30),
  ));

  // 1. Auth token injection
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ));

  // 2. Auto-retry interceptor for cold starts & temporary network jitter
  dio.interceptors.add(InterceptorsWrapper(
    onError: (DioException err, handler) async {
      final isTimeoutOrNetwork =
          err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.connectionError;

      final isGet = err.requestOptions.method.toUpperCase() == 'GET';
      final retryCount = err.requestOptions.extra['retry_count'] as int? ?? 0;

      if (isTimeoutOrNetwork && isGet && retryCount < 2) {
        err.requestOptions.extra['retry_count'] = retryCount + 1;
        // Wait 2 seconds before retrying (gives cold-starting server time to spin up)
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        try {
          final res = await dio.fetch(err.requestOptions);
          return handler.resolve(res);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      }

      return handler.next(err);
    },
  ));

  return dio;
});

// ─── Auth State Stream (Dummy stream provider for compatibility) ──────────────────────
final authStateProvider = StreamProvider<dynamic>((ref) {
  return const Stream.empty();
});

// ─── Current User Entity ──────────────────────────────────────────────────────
final currentUserProvider = Provider<AsyncValue<UserEntity?>>((ref) {
  return ref.watch(authNotifierProvider);
});

// ─── Auth Notifier ────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  AuthNotifier(this._dio) : super(const AsyncValue.loading()) {
    _init();
  }

  final Dio _dio;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final response = await _dio.get('/auth/me');
      final user = UserModel.fromMap(response.data, response.data['id']);
      state = AsyncValue.data(user);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      final userData = response.data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      final user = UserModel.fromMap(userData, userData['id']);
      state = AsyncValue.data(user);
    } on DioException catch (e) {
      final data = e.response?.data;
      final errMsg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Authentication failed';
      state = AsyncValue.error(errMsg, StackTrace.current);
      throw errMsg;
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      });

      final token = response.data['token'];
      final userData = response.data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      final user = UserModel.fromMap(userData, userData['id']);
      state = AsyncValue.data(user);
    } on DioException catch (e) {
      final errMsg = e.response?.data['error'] ?? 'Registration failed';
      state = AsyncValue.error(errMsg, StackTrace.current);
      throw errMsg;
    }
  }

  Future<void> signInWithGoogle() async {
    throw StateError(
        'Google sign-in is not available. Please sign in with your email and password.');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthNotifier(ref.watch(dioProvider));
});
