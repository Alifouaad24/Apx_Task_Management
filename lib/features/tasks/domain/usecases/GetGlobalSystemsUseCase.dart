// domain/usecases/get_global_systems_usecase.dart
import 'package:apx_task_management/features/tasks/data/models/task_model.dart';
import 'package:apx_task_management/features/tasks/domain/repositories/task_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';


class GetGlobalSystemsUseCase {
  GetGlobalSystemsUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<GlobalSystemEntity>>> call() =>
      _repository.getGlobalSystems();
}