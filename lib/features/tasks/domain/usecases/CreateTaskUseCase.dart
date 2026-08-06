import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/task_entity.dart';
import '../entities/task_status.dart';
import '../repositories/task_repository.dart';

class CreateTaskParams {
  const CreateTaskParams({
    required this.body,
    required this.status,
    this.comment,
    this.globalSystemId,
    this.businessId,
    this.serviceId,
  });

  final String body;
  final TaskStatus status;
  final String? comment;
  final int? globalSystemId;
  final int? businessId;
  final int? serviceId;
}

class CreateTaskUseCase {
  CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Either<Failure, TaskEntity>> call(CreateTaskParams params) =>
      _repository.createTask(params);
}