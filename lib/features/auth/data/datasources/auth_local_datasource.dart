import '../../../../core/services/session_manager.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheSession(AuthSessionModel session);

  Future<void> cacheUser(UserModel user);

  UserModel? getCachedUser();

  Future<void> clearSession();

  bool get hasValidSession;

  bool get hasExpiredSession;
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._session);

  final SessionManager _session;

  @override
  Future<void> cacheSession(AuthSessionModel session) => _session.saveSession(
    accessToken: session.token,
    refreshToken: session.refreshToken,
    expiresInSeconds: session.expiresInSeconds,
    userJson: session.user.toJson(),
  );

  @override
  Future<void> cacheUser(UserModel user) => _session.updateUser(user.toJson());

  @override
  UserModel? getCachedUser() {
    final json = _session.userJson;
    if (json == null) return null;
    return UserModel.tryParse(json);
  }

  @override
  Future<void> clearSession() => _session.clearSession();

  @override
  bool get hasValidSession => _session.hasValidSession;

  @override
  bool get hasExpiredSession => _session.hasExpiredSession;
}
