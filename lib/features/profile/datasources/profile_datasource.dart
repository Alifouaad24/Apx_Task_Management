import 'package:apx_task_management/core/api_client.dart';
import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/features/auth/models/user_model.dart';
import 'package:apx_task_management/features/profile/models/notification_settings_model.dart';

/// Profile endpoints. Throws on failure; the repository turns that into
/// `Either`.
class ProfileDatasource {
  const ProfileDatasource(this._api);

  final ApiClient _api;

  Future<UserModel> getProfile() async {
    final body = await _api.get(ApiConstants.profile);
    return UserModel.fromJson(ApiResponse.object(body));
  }

  Future<NotificationSettingsModel> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    final body = await _api.patch(
      ApiConstants.notificationSettings,
      data: settings.toJson(),
    );
    return NotificationSettingsModel.fromJson(ApiResponse.object(body));
  }
}
