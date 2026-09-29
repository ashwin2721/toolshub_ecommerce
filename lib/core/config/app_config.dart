import 'package:flutter/foundation.dart';

enum AppEnvironment {
  dev,
  prod,
}

class AppConfig {
  final String appTitle;
  final String apiBaseUrl;
  final AppEnvironment environment;

  AppConfig({
    required this.appTitle,
    required this.apiBaseUrl,
    required this.environment,
  });

  static AppConfig get current {
    const defaultFlavor = kReleaseMode ? 'prod' : 'dev';
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: defaultFlavor);
    switch (flavor) {
      case 'dev':
        return AppConfig(
          appTitle: 'ToolsHub Dev',
          apiBaseUrl: 'http://localhost:5005/api',
          environment: AppEnvironment.dev,
        );
      case 'prod':
      default:
        return AppConfig(
          appTitle: 'ToolsHub',
          apiBaseUrl: 'https://toolshub-ecommerce.onrender.com/api',
          environment: AppEnvironment.prod,
        );
    }
  }
}

