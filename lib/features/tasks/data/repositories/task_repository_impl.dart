import 'package:apx_task_management/features/tasks/data/models/task_model.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/AddCommentUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/CreateTaskUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/UpdateTaskUseCase.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/base_repository.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/paginated.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

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
