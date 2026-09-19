import 'package:dartz/dartz.dart';

import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/features/tasks/datasources/task_datasource.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';

class TaskRepository {
  const TaskRepository(this._datasource);

  final TaskDatasource _datasource;

  Future<Either<Failure, List<OrderStatusModel>>> getStatuses(int serviceId) =>
      safeCall(() => _datasource.getStatuses(serviceId));

  Future<Either<Failure, List<TaskModel>>> getTasks(
    int businessId,
    int serviceId,
  ) => safeCall(() => _datasource.getTasks(businessId, serviceId));

  Future<Either<Failure, void>> createTask(NewTaskData data) =>
      safeCall(() => _datasource.createTask(data));

  Future<Either<Failure, void>> updateTask(
    int taskId, {
    required String notes,
    int? statusId,
  }) => safeCall(
    () => _datasource.updateTask(taskId, notes: notes, statusId: statusId),
  );

  Future<Either<Failure, void>> deleteTask(int taskId) =>
      safeCall(() => _datasource.deleteTask(taskId));

  Future<Either<Failure, void>> addComment(int taskId, String comment) =>
      safeCall(() => _datasource.addComment(taskId, comment));

  Future<Either<Failure, void>> markCommentsRead(int taskId) =>
      safeCall(() => _datasource.markCommentsRead(taskId));

  Future<Either<Failure, void>> changeStatus(
    TaskModel task,
    OrderStatusModel status,
  ) => safeCall(() => _datasource.changeStatus(task, status));

  Future<Either<Failure, List<AssignTypeModel>>> getAssignTypes() =>
      safeCall(_datasource.getAssignTypes);

  Future<Either<Failure, List<LookupOption>>> getBusinesses(int businessId) =>
      safeCall(() => _datasource.getBusinesses(businessId));

  Future<Either<Failure, List<LookupOption>>> getCustomers(int businessId) =>
      safeCall(() => _datasource.getCustomers(businessId));

  /// The options behind an assign type (Business / Customer / System / User).
  /// Unknown types yield an empty list rather than an error.
  Future<Either<Failure, List<LookupOption>>> getAssignOptions(
    String type,
    int businessId,
  ) => safeCall(
    () => switch (type) {
      'Business' => _datasource.getBusinesses(businessId),
      'Customer' => _datasource.getCustomers(businessId),
      'System' => _datasource.getGlobalSystems(),
      'User' => _datasource.getUsers(businessId),
      _ => Future.value(const <LookupOption>[]),
    },
  );
}
