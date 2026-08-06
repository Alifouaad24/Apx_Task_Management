import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/base_repository.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/logger_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/notification_settings_model.dart';

class ProfileRepositoryImpl with RepositoryMixin implements ProfileRepository {
  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remote,
    required ProfileLocalDataSource local,
    required this.networkInfo,
  })  : _remote = remote,
        _local = local;

  final ProfileRemoteDataSource _remote;
  final ProfileLocalDataSource _local;

  @override
  final NetworkInfo networkInfo;

  @override
  UserEntity? get cachedUser => _local.getCachedUser()?.toEntity();

  @override
  Future<Either<Failure, UserEntity>> getProfile() {
    return guard(
      () async {
        final user = await _remote.getProfile();
        await _local.cacheUser(user);
        return user.toEntity();
      },
      // Offline? The cached profile is still perfectly good to display.
      onCacheFallback: () async => _local.getCachedUser()?.toEntity(),
    );
  }

  @override
  NotificationSettingsEntity get notificationSettings =>
      _local.getNotificationSettings().toEntity();

  @override
  Future<Either<Failure, NotificationSettingsEntity>>
      updateNotificationSettings(NotificationSettingsEntity settings) async {
    final model = NotificationSettingsModel.fromEntity(settings);

    // Local first: the switch must not wait on (or be undone by) the network.
    final localResult = await guardLocal(() async {
      await _local.cacheNotificationSettings(model);
      return settings;
    });

    if (localResult.isLeft()) return localResult;

    // Server sync is best effort — a failure here does not undo the local
    // preference, it just means other devices will not see it yet.
    try {
      if (await networkInfo.isConnected) {
        final synced = await _remote.updateNotificationSettings(model);
        await _local.cacheNotificationSettings(synced);
        return Right(synced.toEntity());
      }
    } catch (e) {
      AppLogger.w('Notification settings did not sync to the server', e);
    }

    return Right(settings);
  }
}
