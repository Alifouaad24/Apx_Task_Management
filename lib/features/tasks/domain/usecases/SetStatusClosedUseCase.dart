// domain/usecases/set_status_closed_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class SetStatusClosedUseCase {
  SetStatusClosedUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, TaskEntity>> call(int taskId) =>
      _repository.setStatusClosed(taskId);
}