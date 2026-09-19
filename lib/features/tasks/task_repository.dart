import 'package:dartz/dartz.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/network.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/tasks/task_models.dart';
import 'package:apx_task_management/features/tasks/task_usecases.dart';

// --------------------------------------------------------------------------
// Task repository
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Task remote datasource
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Task repository impl
// --------------------------------------------------------------------------

class TaskRepositoryImpl with RepositoryMixin implements TaskRepository {
  TaskRepositoryImpl({
    required TaskRemoteDataSource remote,
    required this.networkInfo,
  }) : _remote = remote;

  final TaskRemoteDataSource _remote;

  @override
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, Paginated<TaskEntity>>> getTasks({
    required TaskStatus status,
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return guard(() async {
      final result = await _remote.getTasks(
        status: status.apiValue,
        page: page,
        limit: limit,
        search: search,
      );

      // Models → entities, pagination metadata preserved.
      return result.map((model) => model.toEntity());
    });
  }

  Future<Either<Failure, TaskEntity>> createTask(
    CreateTaskParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure()); // TODO: اسم الـ Failure الحقيقي عندك
    }
    try {
      final model = await _remote.createTask(params);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString())); // TODO: نفس الملاحظة
    }
  }

  @override
  Future<Either<Failure, List<BusinessEntity>>> getBusinesses() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final businesses = await _remote.getBusinesses();
      final businessesEntity = businesses.map((el) => el.toEntity()).toList();

      return Right(businessesEntity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices({
    int? businessId,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final services = await _remote.getServices(businessId: businessId);
      final servicesEntity = services.map((el) => el.toEntity()).toList();

      return Right(servicesEntity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GlobalSystemEntity>>> getGlobalSystems() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      var systems = await _remote.getGlobalSystems();
      var systemsEntity = systems
          .map((el) => el.toEntity())
          .toList(); // ← ضفت toList()

      return Right(systemsEntity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTask(
    UpdateTaskParams params,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final model = await _remote.updateTask(params);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(int taskId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.deleteTask(taskId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addComment(AddCommentParams params) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.addComment(params);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> setStatusClosed(int taskId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final model = await _remote.setStatusClosed(taskId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> setStatusCompleted(int taskId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final model = await _remote.setStatusCompleted(taskId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> changeStatus(
    int taskId,
    TaskStatus status,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final model = await _remote.changeStatus(taskId, status);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
