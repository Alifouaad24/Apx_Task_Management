// domain/usecases/add_comment_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/task_repository.dart';

class AddCommentParams {
  const AddCommentParams({required this.taskId, required this.comment});

  final int taskId;
  final String comment;
}

class AddCommentUseCase {
  AddCommentUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(AddCommentParams params) =>
      _repository.addComment(params);
}