import 'package:apx_task_management/core/api_client.dart';
import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';

/// Order (task) endpoints. Throws on failure; the repository turns that into
/// `Either`.
///
/// The write endpoints return nothing useful, so callers update their state
/// locally or reload.
class TaskDatasource {
  const TaskDatasource(this._api);

  final ApiClient _api;

  Future<List<OrderStatusModel>> getStatuses(int serviceId) async {
    final body = await _api.get(ApiConstants.orderStatuses(serviceId));
    return OrderStatusModel.listFrom(ApiResponse.list(body));
  }

  Future<List<TaskModel>> getTasks(int businessId, int serviceId) async {
    final body = await _api.get(ApiConstants.orders(businessId, serviceId));
    return TaskModel.listFrom(ApiResponse.list(body));
  }

  Future<void> createTask(NewTaskData data) =>
      _api.post(ApiConstants.addOrder, data: data.toJson());

  Future<void> updateTask(int taskId, {required String notes, int? statusId}) =>
      _api.put(
        ApiConstants.updateOrder(taskId),
        data: {'notes': notes, 'statusId': statusId},
      );

  Future<void> deleteTask(int taskId) =>
      _api.delete(ApiConstants.deleteOrder(taskId));

  Future<void> addComment(int taskId, String comment) => _api.put(
    ApiConstants.addOrderComment(taskId),
    data: {'comment': comment},
  );

  Future<void> markCommentsRead(int taskId) =>
      _api.put(ApiConstants.markOrderCommentsRead(taskId));

  /// Closed and Completed have their own endpoints; every other status goes
  /// through UpdateETaskOrder, which also needs the current notes.
  Future<void> changeStatus(TaskModel task, OrderStatusModel status) {
    if (status.isClosed) return _api.put(ApiConstants.closeOrder(task.id));
    if (status.isCompleted) {
      return _api.put(ApiConstants.completeOrder(task.id));
    }
    return updateTask(task.id, notes: task.notes, statusId: status.id);
  }

  Future<List<AssignTypeModel>> getAssignTypes() async {
    final body = await _api.get(ApiConstants.assignTypes);
    return AssignTypeModel.listFrom(ApiResponse.list(body));
  }

  Future<List<LookupOption>> getBusinesses(int businessId) => _options(
    ApiConstants.businessesForTask(businessId),
    idKeys: const ['business_id', 'Business_id'],
    nameKeys: const ['business_name', 'Business_name'],
  );

  Future<List<LookupOption>> getCustomers(int businessId) => _options(
    ApiConstants.customers(businessId),
    idKeys: const ['globalCustomerId', 'GlobalCustomerId'],
    nameKeys: const ['customerName', 'CustomerName'],
  );

  Future<List<LookupOption>> getGlobalSystems() => _options(
    ApiConstants.globalSystems,
    idKeys: const ['globalSystemId', 'GlobalSystemId'],
    nameKeys: const ['globalSystemName', 'GlobalSystemName'],
  );

  Future<List<LookupOption>> getUsers(int businessId) => _options(
    ApiConstants.users(businessId),
    idKeys: const ['id', 'Id'],
    nameKeys: const ['userName', 'UserName'],
  );

  /// Fetches a list and flattens each item into a [LookupOption], trying each
  /// key spelling the backend has been seen to use.
  Future<List<LookupOption>> _options(
    String path, {
    required List<String> idKeys,
    required List<String> nameKeys,
  }) async {
    final body = await _api.get(path);
    Object? pick(Map<String, dynamic> json, List<String> keys) => keys
        .map((key) => json[key])
        .firstWhere((v) => v != null, orElse: () => null);

    return [
      for (final item in ApiResponse.list(body))
        if (item is Map<String, dynamic> && pick(item, idKeys) != null)
          LookupOption(
            id: pick(item, idKeys).toString(),
            name: pick(item, nameKeys)?.toString() ?? '',
          ),
    ];
  }
}
