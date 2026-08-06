// domain/usecases/update_task_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/task_entity.dart';
import '../entities/task_status.dart';
import '../repositories/task_repository.dart';

class UpdateTaskParams {
  const UpdateTaskParams({
    required this.taskId,
    required this.body,
    required this.status,
    this.comment,
    this.globalSystemId,
    this.businessId,
    this.serviceId,
  });

  final int taskId;
  final String body;
  final TaskStatus status;
  final String? comment;
  final int? globalSystemId;
  final int? businessId;
  final int? serviceId;
}

class UpdateTaskUseCase {
  UpdateTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, TaskEntity>> call(UpdateTaskParams params) =>
      _repository.updateTask(params);
}