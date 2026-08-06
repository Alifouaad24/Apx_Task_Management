import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Contract for every use case in the app.
///
/// Keeping the signature uniform means controllers always call
/// `await useCase(params)` and always fold an `Either`.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Synchronous variant for use cases that only read local state.
abstract class SyncUseCase<Type, Params> {
  Either<Failure, Type> call(Params params);
}

/// Placeholder for use cases that take no arguments.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
