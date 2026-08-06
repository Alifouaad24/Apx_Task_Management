import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

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
