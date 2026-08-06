import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session_entity.dart';
import '../entities/user_entity.dart';

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
