import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The app's only local storage: token, signed-in user and a few preferences.
///
/// A user counts as logged in while a token is stored. The server is the one
/// that decides whether the token is still good; a 401 clears it (see
/// `ApiClient`).
class AppStorage {
  AppStorage._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppStorage> init() async =>
      AppStorage._(await SharedPreferences.getInstance());

  static const _tokenKey = 'apx_access_token';
  static const _userKey = 'apx_user';
  static const _themeKey = 'apx_theme_mode';
  static const _fcmTokenKey = 'apx_fcm_token';
  static const _notificationSettingsKey = 'apx_notification_settings';
  static const _businessesKey = 'apx_businesses';
  static const _currentBusinessIdKey = 'apx_current_business_id';

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------
  String? get token => _prefs.getString(_tokenKey);

  Future<void> saveToken(String token) => _prefs.setString(_tokenKey, token);

  bool get isLoggedIn => (token ?? '').isNotEmpty;

  Map<String, dynamic>? get user => _readJson(_userKey);

  Future<void> saveUser(Map<String, dynamic> user) =>
      _prefs.setString(_userKey, jsonEncode(user));

  /// Removes everything tied to the signed-in user. Preferences such as the
  /// theme survive a logout.
  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    await _prefs.remove(_fcmTokenKey);
    await _prefs.remove(_businessesKey);
    await _prefs.remove(_currentBusinessIdKey);
  }

  /// The businesses the user belongs to, as returned at login.
  List<Map<String, dynamic>> get businesses {
    final raw = _prefs.getString(_businessesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List
          ? decoded.whereType<Map<String, dynamic>>().toList()
          : const [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveBusinesses(List<Map<String, dynamic>> businesses) =>
      _prefs.setString(_businessesKey, jsonEncode(businesses));

  /// The business the task board is showing.
  int? get currentBusinessId => _prefs.getInt(_currentBusinessIdKey);

  Future<void> saveCurrentBusinessId(int id) =>
      _prefs.setInt(_currentBusinessIdKey, id);

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------

  /// `light` | `dark` | `system`.
  String? get themeMode => _prefs.getString(_themeKey);

  Future<void> saveThemeMode(String mode) => _prefs.setString(_themeKey, mode);

  /// Last FCM token that was registered with the backend.
  String? get fcmToken => _prefs.getString(_fcmTokenKey);

  Future<void> saveFcmToken(String token) =>
      _prefs.setString(_fcmTokenKey, token);

  Map<String, dynamic>? get notificationSettings =>
      _readJson(_notificationSettingsKey);

  Future<void> saveNotificationSettings(Map<String, dynamic> settings) =>
      _prefs.setString(_notificationSettingsKey, jsonEncode(settings));

  Map<String, dynamic>? _readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
