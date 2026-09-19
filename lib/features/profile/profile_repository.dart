import 'package:dartz/dartz.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/network.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/features/auth/auth_models.dart';
import 'package:apx_task_management/features/profile/profile_models.dart';

// --------------------------------------------------------------------------
// Profile repository
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Profile remote datasource
// --------------------------------------------------------------------------

abstract class ProfileRemoteDataSource {
  Future<UserModel> getProfile();

  Future<NotificationSettingsModel> updateNotificationSettings(
    NotificationSettingsModel settings,
  );
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<UserModel> getProfile() async {
    final body = await _client.get(ApiConstants.profile);
    return UserModel.fromJson(ApiResponseParser.object(body));
  }

  @override
  Future<NotificationSettingsModel> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    final body = await _client.patch(
      ApiConstants.notificationSettings,
      data: settings.toJson(),
    );

    // Trust the server's echo when it sends one; fall back to what we sent.
    return NotificationSettingsModel.tryParse(
          ApiResponseParser.object(body),
        ) ??
        settings;
  }
}

// --------------------------------------------------------------------------
// Profile local datasource
// --------------------------------------------------------------------------

abstract class ProfileLocalDataSource {
  UserModel? getCachedUser();

  Future<void> cacheUser(UserModel user);

  /// Returns stored preferences, or defaults on first run.
  NotificationSettingsModel getNotificationSettings();

  Future<void> cacheNotificationSettings(NotificationSettingsModel settings);
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  const ProfileLocalDataSourceImpl({
    required StorageService storage,
    required SessionManager session,
  })  : _storage = storage,
        _session = session;

  final StorageService _storage;
  final SessionManager _session;

  @override
  UserModel? getCachedUser() => UserModel.tryParse(_session.userJson);

  @override
  Future<void> cacheUser(UserModel user) => _session.updateUser(user.toJson());

  @override
  NotificationSettingsModel getNotificationSettings() {
    final stored = _storage.getJson(StorageKeys.notificationSettings);
    return NotificationSettingsModel.tryParse(stored) ??
        const NotificationSettingsModel();
  }

  @override
  Future<void> cacheNotificationSettings(NotificationSettingsModel settings) =>
      _storage.setJson(StorageKeys.notificationSettings, settings.toJson());
}

// --------------------------------------------------------------------------
// Profile repository impl
// --------------------------------------------------------------------------

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
