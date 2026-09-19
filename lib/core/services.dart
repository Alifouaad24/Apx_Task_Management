import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/storage.dart';

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
// Theme service
// --------------------------------------------------------------------------

/// Owns the app's [ThemeMode] and persists the user's choice.
///
/// Registered permanently in the initial binding so both `GetMaterialApp` (at
/// startup) and the profile screen (at runtime) read the same source.
class ThemeService extends GetxController {
  ThemeService(this._storage);

  final AppStorage _storage;

  late ThemeMode themeMode = switch (_storage.themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// Resolves `system` against the platform brightness — used by widgets that
  /// need to pick a status/priority colour for the current brightness.
  bool get isDarkMode {
    switch (themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return Get.mediaQuery.platformBrightness == Brightness.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode == mode) return;

    themeMode = mode;
    update();

    await _storage.saveThemeMode(mode.name);
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
