import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_settings_entity.dart';
import '../repositories/profile_repository.dart';

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
