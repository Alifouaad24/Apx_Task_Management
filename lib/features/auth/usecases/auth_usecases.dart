import 'package:dartz/dartz.dart';

import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/features/auth/models/business_model.dart';
import 'package:apx_task_management/features/auth/models/user_model.dart';
import 'package:apx_task_management/features/auth/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserModel>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }
}

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}

/// `true` while a token is stored. Used by the splash screen.
class IsLoggedInUseCase {
  const IsLoggedInUseCase(this._repository);

  final AuthRepository _repository;

  bool call() => _repository.isLoggedIn;
}

/// The signed-in user saved at login, or `null`.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  UserModel? call() => _repository.currentUser;
}

/// The user's businesses, fetched from the server if none are stored.
class LoadBusinessesUseCase {
  const LoadBusinessesUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, List<BusinessModel>>> call() =>
      _repository.loadBusinesses();
}

/// The business the task board is scoped to, or `null`.
class GetCurrentBusinessUseCase {
  const GetCurrentBusinessUseCase(this._repository);

  final AuthRepository _repository;

  BusinessModel? call() => _repository.currentBusiness;
}

class SelectBusinessUseCase {
  const SelectBusinessUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(BusinessModel business) =>
      _repository.selectBusiness(business);
}
