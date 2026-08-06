import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

import '../constants/app_constants.dart';
import 'logger_service.dart';

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
