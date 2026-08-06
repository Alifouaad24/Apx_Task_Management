import 'package:apx_task_management/features/tasks/domain/entities/task_status.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/AddCommentUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/CreateTaskUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/UpdateTaskUseCase.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/pagination_parser.dart';
import '../../../../core/utils/paginated.dart';
import '../models/task_model.dart';

/// Reads task lists from the API.
abstract class TaskRemoteDataSource {
  Future<Paginated<TaskModel>> getTasks({
    required String status,
    required int page,
    required int limit,
    String? search,
  });

  Future<TaskModel> createTask(CreateTaskParams params);
  Future<List<ServiceModel>> getServices({int? businessId});
  Future<List<GlobalSystemModel>> getGlobalSystems();
  Future<List<BusinessModel>> getBusinesses();
  Future<TaskModel> updateTask(UpdateTaskParams params);
  Future<void> deleteTask(int taskId);
  // abstract class
  Future<void> addComment(AddCommentParams params);
  Future<TaskModel> setStatusClosed(int taskId);
  Future<TaskModel> setStatusCompleted(int taskId);
  Future<TaskModel> changeStatus(int taskId, TaskStatus status);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  const TaskRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<Paginated<TaskModel>> getTasks({
    required String status,
    required int page,
    required int limit,
    String? search,
  }) async {
    final body = await _client.get(
      ApiConstants.tasks,
      queryParameters: {
        ApiConstants.statusParam: status,
        // ApiConstants.pageParam: page,
        // ApiConstants.limitParam: limit,
        // if (search != null) ApiConstants.searchParam: search,
      },
    );

    return PaginationParser.parse<TaskModel>(
      body,
      itemBuilder: TaskModel.fromJson,
      requestedPage: page,
      requestedLimit: limit,
    );
  }

  @override
  Future<TaskModel> createTask(CreateTaskParams params) async {
    final response = await _client.post(
      '/Feature',
      data: {
        'Body': params.body,
        'Status': params.status.apiValue,
        'Comment': params.comment,
        'GlobalSystemId': params.globalSystemId,
        'BusinessId': params.businessId,
        'ServiceId': params.serviceId,
      },
    );
    return TaskModel.fromJson(response);
  }

  Future<List<BusinessModel>> getBusinesses() async {
    final response = await _client.get('/Business');
    final list = response as List;
    return list
        .map((json) => BusinessModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ServiceModel>> getServices({int? businessId}) async {
    final response = await _client.get('/Service/$businessId');
    final list = response as List;
    return list
        .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<GlobalSystemModel>> getGlobalSystems() async {
    final response = await _client.get('/GlobalSystem');
    final list = response as List;
    return list
        .map((json) => GlobalSystemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TaskModel> updateTask(UpdateTaskParams params) async {
    final response = await _client.put(
      '/Feature/${params.taskId}',
      data: {
        'FeatureId': params.taskId,
        'Body': params.body,
        'Status': params.status.apiValue,
        'Comment': params.comment,
        'GlobalSystemId': params.globalSystemId,
        'BusinessId': params.businessId,
        'ServiceId': params.serviceId,
      },
    );
    return TaskModel.fromJson(
      response as Map<String, dynamic>,
    ); // عدّل لو مختلف عن Business/GlobalSystem
  }

  @override
  Future<void> deleteTask(int taskId) async {
    await _client.delete('/Feature/$taskId'); // TODO: راجع المسار
  }

  // Impl
  @override
  Future<void> addComment(AddCommentParams params) async {
    await _client.put(
      '/Feature/AddComment/${params.taskId}',
      data: {'comment': params.comment},
    );
  }

  @override
  Future<TaskModel> setStatusClosed(int taskId) async {
    final response = await _client.put('/Feature/SetTaskStatusClosed/$taskId');
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<TaskModel> setStatusCompleted(int taskId) async {
    final response = await _client.put(
      '/Feature/SetStatusComleted/$taskId',
    ); // نفس الـ typo الموجود بالباك
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  // Impl
@override
Future<TaskModel> changeStatus(int taskId, TaskStatus status) async {
  final response = await _client.put(
    '/Feature/ChangeStatus/$taskId',
    queryParameters: {'status': status.apiValue}, 
  );
  return TaskModel.fromJson(response as Map<String, dynamic>);
}
}
