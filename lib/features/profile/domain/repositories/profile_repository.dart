import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/notification_settings_entity.dart';

abstract class ProfileRepository {
  /// The cached user, available instantly and without a network call.
  UserEntity? get cachedUser;

  /// Authoritative profile from the server; also refreshes the cache.
  Future<Either<Failure, UserEntity>> getProfile();

  /// Locally stored notification preferences.
  NotificationSettingsEntity get notificationSettings;

  /// Persists preferences locally and mirrors them to the server.
  ///
  /// The local write always succeeds first, so the toggle stays responsive even
  /// when the device is offline.
  Future<Either<Failure, NotificationSettingsEntity>> updateNotificationSettings(
    NotificationSettingsEntity settings,
  );
}
