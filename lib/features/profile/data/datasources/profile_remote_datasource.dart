import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/notification_settings_model.dart';

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
