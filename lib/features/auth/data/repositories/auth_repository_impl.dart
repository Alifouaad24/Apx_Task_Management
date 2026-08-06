import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/base_repository.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

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
