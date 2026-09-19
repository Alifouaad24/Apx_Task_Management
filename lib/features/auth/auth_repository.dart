import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' show Options;

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/network.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/features/auth/auth_models.dart';

// --------------------------------------------------------------------------
// Auth repository
// --------------------------------------------------------------------------

abstract class AuthRepository {
  Future<Either<Failure, AuthSessionEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> logout();
  Future<Either<Failure, UserEntity?>> getCachedUser();
  Future<Either<Failure, UserEntity>> fetchCurrentUser();
  Future<Either<Failure, Unit>> clearSession();

  bool get hasValidSession;
  bool get hasExpiredSession;
}

// --------------------------------------------------------------------------
// Auth remote datasource
// --------------------------------------------------------------------------

/// Talks to the auth endpoints. Throws [AppException]s; never returns
/// `Either` — that translation is the repository's job.
abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserModel> fetchCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final body = await _client.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
    );

    return AuthSessionModel.fromJson(ApiResponseParser.object(body));
  }

  @override
  Future<void> logout() async {
    // Best effort: the repository clears local state regardless of the result.
    await _client.post(ApiConstants.logout);
  }

  @override
  Future<UserModel> fetchCurrentUser() async {
    final body = await _client.get(ApiConstants.currentUser);
    return UserModel.fromJson(ApiResponseParser.object(body));
  }
}

// --------------------------------------------------------------------------
// Auth local datasource
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Auth repository impl
// --------------------------------------------------------------------------

/// Coordinates the remote and local auth data sources and converts every
/// outcome into `Either<Failure, T>`.
class AuthRepositoryImpl with RepositoryMixin implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required this.networkInfo,
  }) : _remote = remote,
       _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, AuthSessionEntity>> login({
    required String email,
    required String password,
  }) {
    return guard(() async {
      final session = await _remote.login(email: email, password: password);
      await _local.cacheSession(session);

      return session.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      if (await networkInfo.isConnected) await _remote.logout();
    } catch (e) {
      AppLogger.w('Remote logout failed, clearing locally anyway', e);
    }

    return guardLocal(() async {
      await _local.clearSession();
      return unit;
    });
  }

  @override
  Future<Either<Failure, UserEntity?>> getCachedUser() {
    return guardLocal(() async => _local.getCachedUser()?.toEntity());
  }

  @override
  Future<Either<Failure, UserEntity>> fetchCurrentUser() {
    return guard(() async {
      final user = await _remote.fetchCurrentUser();
      await _local.cacheUser(user);
      return user.toEntity();
    });
  }

  @override
  bool get hasValidSession => _local.hasValidSession;

  @override
  bool get hasExpiredSession => _local.hasExpiredSession;

  @override
  Future<Either<Failure, Unit>> clearSession() => guardLocal(() async {
    await _local.clearSession();
    return unit;
  });
}
