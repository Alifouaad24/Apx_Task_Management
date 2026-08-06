import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Reads the locally cached user — used by the splash and profile screens to
/// render immediately, before any network round trip.
class GetCachedUserUseCase implements UseCase<UserEntity?, NoParams> {
  const GetCachedUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) =>
      _repository.getCachedUser();
}
