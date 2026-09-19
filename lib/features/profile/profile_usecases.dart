import 'package:dartz/dartz.dart';

import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/auth/auth_models.dart';
import 'package:apx_task_management/features/profile/profile_models.dart';
import 'package:apx_task_management/features/profile/profile_repository.dart';

// --------------------------------------------------------------------------
// Get profile usecase
// --------------------------------------------------------------------------

/// Fetches the signed-in user's profile from the server.
class GetProfileUseCase implements UseCase<UserEntity, NoParams> {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.getProfile();
}

// --------------------------------------------------------------------------
// Update notification settings usecase
// --------------------------------------------------------------------------

/// Saves notification preferences.
class UpdateNotificationSettingsUseCase
    implements UseCase<NotificationSettingsEntity, NotificationSettingsEntity> {
  const UpdateNotificationSettingsUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, NotificationSettingsEntity>> call(
    NotificationSettingsEntity params,
  ) =>
      _repository.updateNotificationSettings(params);
}
