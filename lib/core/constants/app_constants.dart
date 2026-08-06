/// Global, compile-time application configuration.
///
/// Values here are intentionally kept free of any Flutter/plugin imports so the
/// file can be referenced from every layer (domain included) without breaking
/// the Clean Architecture dependency rule.
class AppConfig {
  const AppConfig._();

  /// Human readable application name (used in the AppBar / notifications).
  static const String appName = 'APX Tasks';

  /// When `true` the [MockInterceptor] short-circuits every Dio request and
  /// answers with in-memory demo data, so the whole app is explorable without a
  /// backend.
  ///
  /// Defaults to `false` because [ApiConstants.baseUrl] points at a real
  /// server. Run with `--dart-define=USE_MOCK_API=true` to browse the app
  /// against the built-in demo dataset instead (any email + a 6-character
  /// password signs in).
  static const bool useMockApi =
      bool.fromEnvironment('USE_MOCK_API', defaultValue: false);

  /// Toggles the verbose Dio request/response logger.
  static const bool enableNetworkLogs =
      bool.fromEnvironment('ENABLE_NETWORK_LOGS', defaultValue: true);

  /// Toggles Firebase Analytics event reporting.
  static const bool enableAnalytics =
      bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);

  /// Design canvas the UI was drawn against; consumed by ScreenUtil.
  static const double designWidth = 390;
  static const double designHeight = 844;

  /// Default page size used by every paginated list in the app.
  static const int defaultPageSize = 20;

  /// How long before the real expiry a token is already treated as expired.
  /// Prevents firing a request with a token that dies mid-flight.
  static const Duration tokenExpiryLeeway = Duration(seconds: 30);

  /// Debounce applied to search / rapid user input.
  static const Duration inputDebounce = Duration(milliseconds: 400);

  /// Minimum time the splash screen stays visible, so the branding does not
  /// flash for a single frame on fast devices.
  static const Duration splashMinimumDuration = Duration(milliseconds: 1200);
}
