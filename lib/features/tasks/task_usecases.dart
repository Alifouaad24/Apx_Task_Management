import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/tasks/task_models.dart';
import 'package:apx_task_management/features/tasks/task_repository.dart';

// --------------------------------------------------------------------------
// Get tasks usecase
// --------------------------------------------------------------------------

/// Loads one page of tasks for a status tab.
class GetTasksUseCase
    implements UseCase<Paginated<TaskEntity>, GetTasksParams> {
  const GetTasksUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Paginated<TaskEntity>>> call(GetTasksParams params) {
    return _repository.getTasks(
      status: params.status,
      page: params.page,
      limit: params.limit,
      // An empty search string must not be sent as a filter.
      search: (params.search?.trim().isEmpty ?? true) ? null : params.search!.trim(),
    );
  }
}

class GetTasksParams extends Equatable {
  const GetTasksParams({
    required this.status,
    this.page = 1,
    this.limit = AppConfig.defaultPageSize,
    this.search,
  });

  final TaskStatus status;
  final int page;
  final int limit;
  final String? search;

  @override
  List<Object?> get props => [status, page, limit, search];
}

// --------------------------------------------------------------------------
// CreateTaskUseCase
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// UpdateTaskUseCase
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// DeleteTaskUseCase
// --------------------------------------------------------------------------

class DeleteTaskUseCase {
  DeleteTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(int taskId) =>
      _repository.deleteTask(taskId);
}

// --------------------------------------------------------------------------
// AddCommentUseCase
// --------------------------------------------------------------------------

class AddCommentParams {
  const AddCommentParams({required this.taskId, required this.comment});

  final int taskId;
  final String comment;
}

class AddCommentUseCase {
  AddCommentUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(AddCommentParams params) =>
      _repository.addComment(params);
}

// --------------------------------------------------------------------------
// ChangeStatusUseCase
// --------------------------------------------------------------------------

class ChangeStatusUseCase {
  ChangeStatusUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, TaskEntity>> call(int taskId, TaskStatus status) =>
      _repository.changeStatus(taskId, status);
}

// --------------------------------------------------------------------------
// SetStatusCompletedUseCase
// --------------------------------------------------------------------------

class SetStatusCompletedUseCase {
  SetStatusCompletedUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, TaskEntity>> call(int taskId) =>
      _repository.setStatusCompleted(taskId);
}

// --------------------------------------------------------------------------
// SetStatusClosedUseCase
// --------------------------------------------------------------------------

class SetStatusClosedUseCase {
  SetStatusClosedUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, TaskEntity>> call(int taskId) =>
      _repository.setStatusClosed(taskId);
}

// --------------------------------------------------------------------------
// GetBusinessesUseCase
// --------------------------------------------------------------------------

class GetBusinessesUseCase {
  GetBusinessesUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<BusinessEntity>>> call() =>
      _repository.getBusinesses();
}

// --------------------------------------------------------------------------
// GetServicesUseCase
// --------------------------------------------------------------------------

class GetServicesUseCase {
  GetServicesUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<ServiceEntity>>> call({int? businessId}) =>
      _repository.getServices(businessId: businessId);
}

// --------------------------------------------------------------------------
// GetGlobalSystemsUseCase
// --------------------------------------------------------------------------

class GetGlobalSystemsUseCase {
  GetGlobalSystemsUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<GlobalSystemEntity>>> call() =>
      _repository.getGlobalSystems();
}
