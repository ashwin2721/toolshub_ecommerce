import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'presentation/providers/app_provider.dart';
import 'core/config/app_config.dart';
import 'core/brand/brand.dart';

/// Shared launch path for every brand.
///
/// Each entry point (`lib/main.dart`, `lib/main_toolshub.dart`) does nothing but
/// name its brand and call this, so there is exactly one copy of the startup
/// sequence and the brands cannot drift apart.
///
/// Brand comes from the entry point rather than a `--dart-define` string because
/// a wrong `-t` path is a build error, whereas a mistyped define would silently
/// ship the wrong storefront — the exact failure mode the old `AppConfig` had.
/// On Android the entry point is paired with a Gradle product flavour, which is
/// what sets the app name and bundle id.
Future<void> bootstrap(Brand brand) async {
  Brand.current = brand;

  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.current;
  debugPrint('=========================================');
  debugPrint('BRAND: ${brand.displayName} (${brand.key})');
  debugPrint('ENVIRONMENT: ${config.environment.name}');
  debugPrint('API BASE URL: ${config.apiBaseUrl}');
  debugPrint('=========================================');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    const ProviderScope(
      child: StoreApp(),
    ),
  );
}

class StoreApp extends ConsumerWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final languageCode = ref.watch(languageProvider);

    return MaterialApp.router(
      title: AppConfig.current.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Dark mode is temporarily locked off: switching themes triggers a
      // duplicate-widget-key crash that needs runtime debugging, and this
      // redesign is light-themed. Re-enable during the theme/polish pass.
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: Locale(languageCode),
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final isOffline = ref.watch(isOfflineProvider);
            return Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: isOffline
                      ? Material(
                          color: Colors.red[800],
                          child: SafeArea(
                            bottom: false,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Offline. Using cached database',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            );
          },
        );
      },
    );
  }
}
