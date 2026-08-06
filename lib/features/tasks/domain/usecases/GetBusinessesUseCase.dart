// domain/usecases/get_businesses_usecase.dart
import 'package:apx_task_management/features/tasks/data/models/task_model.dart';
import 'package:apx_task_management/features/tasks/domain/repositories/task_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';


class GetBusinessesUseCase {
  GetBusinessesUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<BusinessEntity>>> call() =>
      _repository.getBusinesses();
}