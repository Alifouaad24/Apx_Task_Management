// domain/usecases/delete_task_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  DeleteTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(int taskId) =>
      _repository.deleteTask(taskId);
}