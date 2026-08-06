// domain/usecases/change_status_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/task_entity.dart';
import '../entities/task_status.dart';
import '../repositories/task_repository.dart';

class ChangeStatusUseCase {
  ChangeStatusUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, TaskEntity>> call(int taskId, TaskStatus status) =>
      _repository.changeStatus(taskId, status);
}