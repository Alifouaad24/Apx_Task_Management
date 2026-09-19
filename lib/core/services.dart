import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/utils.dart';

// --------------------------------------------------------------------------
// Logger service
// --------------------------------------------------------------------------

/// App-wide logger.
///
/// Wrapped in a static facade so call sites stay short and the underlying
/// implementation (or a crash-reporting sink) can be swapped in one place.
/// Logging is muted in release builds to avoid leaking data through logcat.
class AppLogger {
  const AppLogger._();

  static final Logger _logger = Logger(
    filter: _ReleaseSafeFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Verbose tracing.
  static void t(dynamic message) => _logger.t(message);

  /// Debug detail.
  static void d(dynamic message) => _logger.d(message);

  /// Notable, expected events (navigation, session changes).
  static void i(dynamic message) => _logger.i(message);

  /// Recoverable problems.
  static void w(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  /// Failures the user is likely to notice.
  static void e(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// Unrecoverable failures.
  static void f(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}

/// Emits everything in debug/profile, nothing in release.
class _ReleaseSafeFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => !kReleaseMode;
}

// --------------------------------------------------------------------------
// Storage service
// --------------------------------------------------------------------------

class StorageService extends GetxService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _guard(() => _prefs.setString(key, value), key);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setInt(String key, int value) =>
      _guard(() => _prefs.setInt(key, value), key);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, bool value) =>
      _guard(() => _prefs.setBool(key, value), key);

  double? getDouble(String key) => _prefs.getDouble(key);

  Future<bool> setDouble(String key, double value) =>
      _guard(() => _prefs.setDouble(key, value), key);

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException catch (e) {
      AppLogger.w('Corrupt JSON at "$key", dropping it', e);
      _prefs.remove(key);
      return null;
    }
  }

  Future<bool> setJson(String key, Map<String, dynamic> value) =>
      _guard(() => _prefs.setString(key, jsonEncode(value)), key);

  bool has(String key) => _prefs.containsKey(key);

  Future<bool> remove(String key) => _guard(() => _prefs.remove(key), key);

  Future<void> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      await remove(key);
    }
  }

  Future<bool> clear() => _guard(_prefs.clear, '*');

  Future<void> reload() => _prefs.reload();

  Future<bool> _guard(Future<bool> Function() action, String key) async {
    try {
      return await action();
    } catch (e, s) {
      AppLogger.e('Storage write failed for "$key"', e, s);
      throw CacheException('Could not persist "$key".');
    }
  }
}

// --------------------------------------------------------------------------
// Token storage
// --------------------------------------------------------------------------

class TokenStorage {
  const TokenStorage(this._storage);

  final StorageService _storage;

  // Read
  String? get accessToken {
    final token = _storage.getString(StorageKeys.accessToken);
    return (token == null || token.isEmpty) ? null : token;
  }

  String? get refreshToken {
    final token = _storage.getString(StorageKeys.refreshToken);
    return (token == null || token.isEmpty) ? null : token;
  }

  DateTime? get expiry {
    final millis = _storage.getInt(StorageKeys.tokenExpiry);
    if (millis != null && millis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return JwtDecoder.expiryOf(accessToken);
  }

  bool get hasToken => accessToken != null;

  bool get isExpired {
    if (!hasToken) return false;
    final expiresAt = expiry;
    if (expiresAt == null) return false;
    return DateTime.now().add(AppConfig.tokenExpiryLeeway).isAfter(expiresAt);
  }

  bool get isValid => hasToken && !isExpired;

  Future<void> save({
    required String accessToken,
    String? refreshToken,
    int? expiresInSeconds,
    DateTime? expiresAt,
  }) async {
    await _storage.setString(StorageKeys.accessToken, accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.setString(StorageKeys.refreshToken, refreshToken);
    }

    final resolvedExpiry = expiresAt ??
        (expiresInSeconds != null && expiresInSeconds > 0
            ? DateTime.now().add(Duration(seconds: expiresInSeconds))
            : JwtDecoder.expiryOf(accessToken));

    if (resolvedExpiry != null) {
      await _storage.setInt(
        StorageKeys.tokenExpiry,
        resolvedExpiry.millisecondsSinceEpoch,
      );
    } else {
      await _storage.remove(StorageKeys.tokenExpiry);
    }
  }

  Future<void> updateAccessToken(
    String token, {
    int? expiresInSeconds,
  }) =>
      save(accessToken: token, expiresInSeconds: expiresInSeconds);

  Future<void> clear() => _storage.removeAll(const [
        StorageKeys.accessToken,
        StorageKeys.refreshToken,
        StorageKeys.tokenExpiry,
      ]);
}

// --------------------------------------------------------------------------
// Session manager
// --------------------------------------------------------------------------

class SessionManager extends GetxService {
  SessionManager(this._storage) : tokens = TokenStorage(_storage);

  final StorageService _storage;
  final TokenStorage tokens;

  final RxBool isAuthenticated = false.obs;

  final Rxn<Map<String, dynamic>> user = Rxn<Map<String, dynamic>>();

  bool _loggingOut = false;

  final List<Future<void> Function()> _teardownHooks = [];

  @override
  void onInit() {
    super.onInit();
    _hydrate();
  }

  void _hydrate() {
    user.value = _storage.getJson(StorageKeys.userData);
    isAuthenticated.value = tokens.isValid;
  }

  Map<String, dynamic>? get userJson => user.value;

  String? get currentUserId => user.value?['id']?.toString();

  String get currentUserName =>
      (user.value?['name'] ?? user.value?['fullName'] ?? '').toString();

  String get currentUserEmail => (user.value?['email'] ?? '').toString();

  String? get currentUserAvatar {
    final avatar = user.value?['avatarUrl'] ?? user.value?['avatar'];
    final url = avatar?.toString();
    return (url == null || url.isEmpty) ? null : url;
  }

  String? get accessToken => tokens.accessToken;

  bool get hasValidSession => tokens.isValid;

  bool get hasExpiredSession => tokens.hasToken && tokens.isExpired;

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    int? expiresInSeconds,
    DateTime? expiresAt,
    Map<String, dynamic>? userJson,
  }) async {
    await tokens.save(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresInSeconds,
      expiresAt: expiresAt,
    );

    if (userJson != null) {
      await _storage.setJson(StorageKeys.userData, userJson);
    }

    _hydrate();
    _loggingOut = false;
    AppLogger.i(
      'Session saved for ${currentUserEmail.isEmpty ? 'user' : currentUserEmail}',
    );
  }

  Future<void> updateUser(Map<String, dynamic> userJson) async {
    await _storage.setJson(StorageKeys.userData, userJson);
    user.value = userJson;
  }

  Future<void> clearSession() async {
    for (final hook in _teardownHooks) {
      try {
        await hook();
      } catch (e, s) {
        AppLogger.w('Session teardown hook failed', e, s);
      }
    }

    await tokens.clear();
    await _storage.remove(StorageKeys.userData);

    user.value = null;
    isAuthenticated.value = false;
    AppLogger.i('Session cleared');
  }

  void addTeardownHook(Future<void> Function() hook) =>
      _teardownHooks.add(hook);

  Future<void> forceLogout({String? reason}) async {
    if (_loggingOut) return;
    _loggingOut = true;

    AppLogger.w('Forced logout: ${reason ?? 'unauthorized'}');
    await clearSession();

    if (Get.currentRoute != AppRoutes.login && Get.currentRoute.isNotEmpty) {
      await Get.offAllNamed(AppRoutes.login);
    }
    _loggingOut = false;
  }
}

// --------------------------------------------------------------------------
// Theme service
// --------------------------------------------------------------------------

/// Owns the app's [ThemeMode] and persists the user's choice.
///
/// Registered permanently in the initial binding so both `GetMaterialApp` (at
/// startup) and the profile screen (at runtime) read the same source.
class ThemeService extends GetxService {
  ThemeService(this._storage);

  final StorageService _storage;

  static const String _light = 'light';
  static const String _dark = 'dark';
  static const String _system = 'system';

  late final Rx<ThemeMode> themeMode = _readStoredMode().obs;

  ThemeMode _readStoredMode() {
    switch (_storage.getString(StorageKeys.themeMode)) {
      case _light:
        return ThemeMode.light;
      case _dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Resolves `system` against the platform brightness — used by widgets that
  /// need to pick a status/priority colour for the current brightness.
  bool get isDarkMode {
    switch (themeMode.value) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return Get.mediaQuery.platformBrightness == Brightness.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) return;

    themeMode.value = mode;
    Get.changeThemeMode(mode);

    await _storage.setString(StorageKeys.themeMode, switch (mode) {
      ThemeMode.light => _light,
      ThemeMode.dark => _dark,
      ThemeMode.system => _system,
    });
  }

  /// Convenience for a quick light/dark switch in the app bar.
  Future<void> toggle() => setThemeMode(
        isDarkMode ? ThemeMode.light : ThemeMode.dark,
      );
}

// --------------------------------------------------------------------------
// Analytics service
// --------------------------------------------------------------------------

/// Thin wrapper over Firebase Analytics.
///
/// Every call is a no-op when analytics are disabled or Firebase failed to
/// initialise, so screens can log freely without null checks or try/catch.
class AnalyticsService extends GetxService {
  FirebaseAnalytics? _analytics;

  bool get _enabled => AppConfig.enableAnalytics && _analytics != null;

  /// Called from the bootstrap sequence *after* `Firebase.initializeApp`.
  /// Passing `available: false` keeps the service registered but inert.
  Future<AnalyticsService> init({required bool available}) async {
    if (!available || !AppConfig.enableAnalytics) {
      AppLogger.i('Analytics disabled');
      return this;
    }
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
    } catch (e, s) {
      AppLogger.w('Analytics unavailable', e, s);
      _analytics = null;
    }
    return this;
  }

  /// Navigation observer to hand to `GetMaterialApp.navigatorObservers`.
  FirebaseAnalyticsObserver? get observer => _enabled
      ? FirebaseAnalyticsObserver(analytics: _analytics!)
      : null;

  Future<void> setUser({required String id, String? role}) async {
    if (!_enabled) return;
    await _analytics!.setUserId(id: id);
    if (role != null) {
      await _analytics!.setUserProperty(name: 'role', value: role);
    }
  }

  Future<void> clearUser() async {
    if (!_enabled) return;
    await _analytics!.setUserId(id: null);
  }

  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (!_enabled) return;
    try {
      await _analytics!.logEvent(name: name, parameters: params);
    } catch (e) {
      AppLogger.w('Analytics event "$name" failed', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Domain events — named helpers keep event names consistent across the app
  // ---------------------------------------------------------------------------
  Future<void> logLogin() => logEvent('login', {'method': 'password'});

  Future<void> logLogout() => logEvent('logout');

  Future<void> logTaskOpened(String taskId) =>
      logEvent('task_opened', {'task_id': taskId});

  Future<void> logStatusChanged(String taskId, String from, String to) =>
      logEvent('task_status_changed', {
        'task_id': taskId,
        'from_status': from,
        'to_status': to,
      });

  Future<void> logCommentAdded(String taskId) =>
      logEvent('comment_added', {'task_id': taskId});

  Future<void> logTabViewed(String status) =>
      logEvent('tasks_tab_viewed', {'status': status});
}
