import 'package:flutter/foundation.dart';
import '../brand/brand.dart';

enum AppEnvironment { dev, prod }

/// Brand × environment, composed.
///
/// These are two independent axes and must not be multiplexed through one string:
/// **brand** (which storefront) comes from the entry point via [Brand.current],
/// **environment** (which backend) comes from `--dart-define=ENV=dev|prod`.
///
/// The public fields are unchanged from the pre-flavour version so existing
/// consumers compile untouched.
class AppConfig {
  final Brand brand;
  final AppEnvironment environment;

  AppConfig({required this.brand, required this.environment});

  /// Window/tab title. Dev builds are suffixed so a dev tab is never mistaken
  /// for production.
  String get appTitle => environment == AppEnvironment.dev
      ? '${brand.displayName} Dev'
      : brand.displayName;

  /// Each brand is its own shop with its own catalogue, so each has its own
  /// backend.
  String get apiBaseUrl => environment == AppEnvironment.dev
      ? brand.apiBaseUrlDev
      : brand.apiBaseUrlProd;

  static AppConfig get current =>
      AppConfig(brand: Brand.current, environment: _environment);

  static AppEnvironment get _environment {
    // FLAVOR is the pre-flavour name for this define, kept working for one
    // release so existing CI scripts and launch configs do not break.
    const env = String.fromEnvironment('ENV', defaultValue: '');
    const legacy = String.fromEnvironment('FLAVOR', defaultValue: '');
    final token = (env.isNotEmpty ? env : legacy).trim().toLowerCase();

    switch (token) {
      case 'dev':
        return AppEnvironment.dev;
      case 'prod':
        return AppEnvironment.prod;
      case '':
        // Unset is the common case: debug builds want dev, release wants prod.
        return kReleaseMode ? AppEnvironment.prod : AppEnvironment.dev;
      default:
        // The old code silently resolved anything unrecognised to prod, so a typo
        // like ENV=prd pointed a dev build at the production database without a
        // word. Fail loudly in debug instead.
        assert(
          false,
          'Unknown ENV "$token". Expected "dev" or "prod".',
        );
        return kReleaseMode ? AppEnvironment.prod : AppEnvironment.dev;
    }
  }
}
