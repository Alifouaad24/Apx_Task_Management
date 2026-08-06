import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/notification_settings_model.dart';

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
