import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


// ─── Theme Mode ───────────────────────────────────────────────────────────────
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false) {
    _load();
  }

  static const _key = 'is_dark_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> setDark(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>(
  (ref) => ThemeNotifier(),
);

// ─── Language ─────────────────────────────────────────────────────────────────
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('language_code') ?? 'en';
  }

  Future<void> setLanguage(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>(
  (ref) => LanguageNotifier(),
);

// ─── Search History ───────────────────────────────────────────────────────────
class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('search_history') ?? [];
  }

  Future<void> add(String query) async {
    if (query.trim().isEmpty) return;
    final updated = [
      query,
      ...state.where((q) => q != query).take(19),
    ];
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', updated);
  }

  Future<void> remove(String query) async {
    state = state.where((q) => q != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', state);
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>(
  (ref) => SearchHistoryNotifier(),
);

// ─── Search Query ─────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

// ─── Product Comparison ───────────────────────────────────────────────────────
class ComparisonNotifier extends StateNotifier<List<String>> {
  ComparisonNotifier() : super([]);

  void toggle(String productId) {
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else if (state.length < 3) {
      state = [...state, productId];
    }
  }

  void clear() => state = [];
  bool contains(String id) => state.contains(id);
}

final comparisonProvider =
    StateNotifierProvider<ComparisonNotifier, List<String>>(
  (ref) => ComparisonNotifier(),
);

// ─── Connectivity Check ──────────────────────────────────────────────────────
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOfflineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.maybeWhen(
    data: (results) => results.isEmpty || results.contains(ConnectivityResult.none),
    orElse: () => false,
  );
});

