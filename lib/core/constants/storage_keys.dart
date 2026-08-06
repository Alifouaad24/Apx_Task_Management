/// Single source of truth for every SharedPreferences key.
///
/// Keys are namespaced with the app prefix so a shared preference store (e.g.
/// on iOS app groups) never collides with another module's keys.
class StorageKeys {
  const StorageKeys._();

  static const String _prefix = 'apx_';

  /// JWT access token.
  static const String accessToken = '${_prefix}access_token';

  /// Long-lived refresh token used by the [AuthInterceptor].
  static const String refreshToken = '${_prefix}refresh_token';

  /// Millisecond epoch at which [accessToken] stops being valid.
  static const String tokenExpiry = '${_prefix}token_expiry';

  /// The signed-in user serialized as a JSON string.
  static const String userData = '${_prefix}user_data';

  /// `light` | `dark` | `system`.
  static const String themeMode = '${_prefix}theme_mode';

  /// Notification preferences serialized as a JSON string.
  static const String notificationSettings = '${_prefix}notification_settings';

  /// Last FCM token that was successfully registered with the backend.
  static const String fcmToken = '${_prefix}fcm_token';
  static const String userId = '${_prefix}user_id';

  /// `true` once the user has completed the first launch flow.
  static const String onboardingSeen = '${_prefix}onboarding_seen';
}
