/// API configuration with build-time environment injection.
/// Use --dart-define=API_BASE_URL=https://api.skillconnect.in/api to override.
/// Use --dart-define=APP_ENV=production to set environment.
class ApiConfig {
  // Build-time configurable via --dart-define=API_BASE_URL=...
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static bool get isProduction => _appEnv == 'production';
  static bool get isStaging => _appEnv == 'staging';
  static bool get isDev => _appEnv == 'dev';

  /// Enable verbose logging only in dev/staging
  static bool get enableLogging => !isProduction;

  // Web: relative path — same server serves app + API
  static const String webBaseUrl = '/api';

  // Default dev server (codespace or local)
  static const String _devAndroidUrl = 'https://bookish-tribble-4q7qxr5p5vvxh7vwg-8000.app.github.dev/api';
  static const String _stagingUrl = 'https://staging-api.skillconnect.in/api';
  static const String _productionUrl = 'https://api.skillconnect.in/api';

  /// Resolved Android/iOS base URL (dart-define overrides env default)
  static String get androidBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (isProduction) return _productionUrl;
    if (isStaging) return _stagingUrl;
    return _devAndroidUrl;
  }

  /// WebSocket URL derived from the base URL
  static String get wsBaseUrl {
    final base = androidBaseUrl;
    return base
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://')
        .replaceAll('/api', '');
  }
}
