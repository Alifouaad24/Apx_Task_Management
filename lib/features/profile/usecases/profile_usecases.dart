import 'package:dartz/dartz.dart';

import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/features/auth/models/user_model.dart';
import 'package:apx_task_management/features/profile/models/notification_settings_model.dart';
import 'package:apx_task_management/features/profile/repositories/profile_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, UserModel>> call() => _repository.getProfile();
}

class UpdateNotificationSettingsUseCase {
  const UpdateNotificationSettingsUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, NotificationSettingsModel>> call(
    NotificationSettingsModel settings,
  ) =>
      _repository.updateNotificationSettings(settings);
}
