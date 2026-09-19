import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/auth/auth_models.dart';
import 'package:apx_task_management/features/auth/auth_repository.dart';

// --------------------------------------------------------------------------
// Login usecase
// --------------------------------------------------------------------------

/// Signs a user in with email + password.
class LoginUseCase implements UseCase<AuthSessionEntity, LoginParams> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSessionEntity>> call(LoginParams params) {
    return _repository.login(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

// --------------------------------------------------------------------------
// Logout usecase
// --------------------------------------------------------------------------

/// Signs the current user out and clears every trace of the session.
class LogoutUseCase implements UseCase<Unit, NoParams> {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.logout();
}

// --------------------------------------------------------------------------
// Get cached user usecase
// --------------------------------------------------------------------------

/// Reads the locally cached user — used by the splash and profile screens to
/// render immediately, before any network round trip.
class GetCachedUserUseCase implements UseCase<UserEntity?, NoParams> {
  const GetCachedUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) =>
      _repository.getCachedUser();
}

// --------------------------------------------------------------------------
// Check session usecase
// --------------------------------------------------------------------------

enum SessionStatus { missing, expired, valid }

class CheckSessionUseCase {
  const CheckSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, SessionStatus>> call() async {
    if (_repository.hasExpiredSession) {
      final result = await _repository.clearSession();
      return result.fold(Left.new, (_) => const Right(SessionStatus.expired));
    }

    if (_repository.hasValidSession) {
      return const Right(SessionStatus.valid);
    }

    return const Right(SessionStatus.missing);
  }
}
