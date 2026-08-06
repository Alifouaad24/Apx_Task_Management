import 'package:get/get.dart';

import '../constants/storage_keys.dart';
import '../routes/app_routes.dart';
import '../storage/storage_service.dart';
import '../storage/token_storage.dart';
import 'logger_service.dart';

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
