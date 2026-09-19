import 'package:dartz/dartz.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/features/auth/usecases/auth_usecases.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';
import 'package:apx_task_management/features/tasks/repositories/task_repository.dart';

/// The business + service the board is scoped to.
class TaskScope {
  const TaskScope({required this.businessId, required this.serviceId});

  final int businessId;
  final int serviceId;
}

/// Everything the dashboard shows: the service's statuses (one tab each) and
/// every task of the business in that service.
class TaskBoard {
  const TaskBoard({required this.statuses, required this.tasks});

  final List<OrderStatusModel> statuses;
  final List<TaskModel> tasks;
}

/// The selected business (falling back to the user's own), and the user's
/// service.
class GetTaskScopeUseCase {
  const GetTaskScopeUseCase(this._getCurrentUser, this._getCurrentBusiness);
  final GetCurrentUserUseCase _getCurrentUser;
  final GetCurrentBusinessUseCase _getCurrentBusiness;

  Either<Failure, TaskScope> call() {
    final user = _getCurrentUser();
    final businessId = _getCurrentBusiness()?.id ?? user?.businessId;
    if (businessId == null) {
      return const Left(
        Failure('Your account is not linked to a business. Sign in again.'),
      );
    }
    return Right(
      TaskScope(
        businessId: businessId,
        serviceId: user?.serviceId ?? ApiConstants.defaultServiceId,
      ),
    );
  }
}

/// Fetches the statuses first, then the tasks — a task list is meaningless
/// without the tabs to sort it into.
class LoadTaskBoardUseCase {
  const LoadTaskBoardUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, TaskBoard>> call(TaskScope scope) async {
    final statusesResult = await _repository.getStatuses(scope.serviceId);
    return statusesResult.fold<Future<Either<Failure, TaskBoard>>>(
      (failure) async => Left(failure),
      (statuses) async {
        final tasks = await _repository.getTasks(
          scope.businessId,
          scope.serviceId,
        );
        return tasks.map(
          (tasks) => TaskBoard(statuses: statuses, tasks: tasks),
        );
      },
    );
  }
}

class CreateTaskUseCase {
  const CreateTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(NewTaskData data) =>
      _repository.createTask(data);
}

class UpdateTaskUseCase {
  const UpdateTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(
    int taskId, {
    required String notes,
    int? statusId,
  }) => _repository.updateTask(taskId, notes: notes, statusId: statusId);
}

class DeleteTaskUseCase {
  const DeleteTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(int taskId) =>
      _repository.deleteTask(taskId);
}

class AddCommentUseCase {
  const AddCommentUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(int taskId, String comment) =>
      _repository.addComment(taskId, comment);
}

class MarkCommentsReadUseCase {
  const MarkCommentsReadUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(int taskId) =>
      _repository.markCommentsRead(taskId);
}

class ChangeStatusUseCase {
  const ChangeStatusUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(TaskModel task, OrderStatusModel status) =>
      _repository.changeStatus(task, status);
}

class GetAssignTypesUseCase {
  const GetAssignTypesUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<AssignTypeModel>>> call() =>
      _repository.getAssignTypes();
}

class GetAssignOptionsUseCase {
  const GetAssignOptionsUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<LookupOption>>> call(
    String type,
    int businessId,
  ) => _repository.getAssignOptions(type, businessId);
}

class GetBusinessesUseCase {
  const GetBusinessesUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<LookupOption>>> call(int businessId) =>
      _repository.getBusinesses(businessId);
}

class GetCustomersUseCase {
  const GetCustomersUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<LookupOption>>> call(int businessId) =>
      _repository.getCustomers(businessId);
}
