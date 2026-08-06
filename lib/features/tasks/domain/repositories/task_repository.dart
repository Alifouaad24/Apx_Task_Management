import 'package:apx_task_management/features/tasks/data/models/task_model.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/AddCommentUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/CreateTaskUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/UpdateTaskUseCase.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/paginated.dart';
import '../entities/task_entity.dart';
import '../entities/task_status.dart';

abstract class TaskRepository {
  Future<Either<Failure, Paginated<TaskEntity>>> getTasks({
    required TaskStatus status,
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Either<Failure, TaskEntity>> createTask(CreateTaskParams params);
  Future<Either<Failure, List<BusinessEntity>>> getBusinesses();
  Future<Either<Failure, List<ServiceEntity>>> getServices({int? businessId});
  Future<Either<Failure, List<GlobalSystemEntity>>> getGlobalSystems();
  Future<Either<Failure, TaskEntity>> updateTask(UpdateTaskParams params);
  Future<Either<Failure, void>> deleteTask(int taskId);
  Future<Either<Failure, void>> addComment(AddCommentParams params);
  Future<Either<Failure, TaskEntity>> setStatusClosed(int taskId);
  Future<Either<Failure, TaskEntity>> setStatusCompleted(int taskId);
  Future<Either<Failure, TaskEntity>> changeStatus(int taskId, TaskStatus status);
}
