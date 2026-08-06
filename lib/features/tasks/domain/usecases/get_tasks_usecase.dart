import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/paginated.dart';
import '../entities/task_entity.dart';
import '../entities/task_status.dart';
import '../repositories/task_repository.dart';

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
