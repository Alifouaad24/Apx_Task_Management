import 'package:dartz/dartz.dart';

import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/storage.dart';
import 'package:apx_task_management/features/auth/models/user_model.dart';
import 'package:apx_task_management/features/profile/datasources/profile_datasource.dart';
import 'package:apx_task_management/features/profile/models/notification_settings_model.dart';

class ProfileRepository {
  const ProfileRepository(this._datasource, this._storage);

  final ProfileDatasource _datasource;
  final AppStorage _storage;

  /// The user saved at login, available instantly.
  UserModel? get cachedUser {
    final json = _storage.user;
    return json == null ? null : UserModel.fromJson(json);
  }

  /// Fresh profile from the server; also updates the saved copy.
  Future<Either<Failure, UserModel>> getProfile() {
    return safeCall(() async {
      final user = await _datasource.getProfile();
      await _storage.saveUser(user.toJson());
      return user;
    });
  }

  NotificationSettingsModel get notificationSettings {
    final json = _storage.notificationSettings;
    return json == null
        ? const NotificationSettingsModel()
        : NotificationSettingsModel.fromJson(json);
  }

  /// Saves locally first so the switch never waits on the network, then syncs
  /// to the server (best effort — offline just means other devices lag).
  Future<Either<Failure, NotificationSettingsModel>> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) {
    return safeCall(() async {
      await _storage.saveNotificationSettings(settings.toJson());

      try {
        final synced = await _datasource.updateNotificationSettings(settings);
        await _storage.saveNotificationSettings(synced.toJson());
        return synced;
      } catch (e) {
        AppLogger.w('Notification settings did not sync to the server', e);
        return settings;
      }
    });
  }
}
