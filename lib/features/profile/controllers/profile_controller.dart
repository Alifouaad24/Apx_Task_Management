import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/api_client.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/storage.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/auth/controllers/auth_controller.dart';
import 'package:apx_task_management/features/auth/models/user_model.dart';
import 'package:apx_task_management/features/profile/datasources/profile_datasource.dart';
import 'package:apx_task_management/features/profile/models/notification_settings_model.dart';
import 'package:apx_task_management/features/profile/repositories/profile_repository.dart';
import 'package:apx_task_management/features/profile/usecases/profile_usecases.dart';

/// Drives the profile screen: user details, theme preference, notification
/// toggles and sign-out.
class ProfileController extends GetxController {
  ProfileController({
    required GetProfileUseCase getProfile,
    required UpdateNotificationSettingsUseCase updateNotificationSettings,
    required ProfileRepository repository,
    required ThemeService themeService,
    required AuthController authController,
  })  : _getProfile = getProfile,
        _updateNotificationSettings = updateNotificationSettings,
        _repository = repository,
        _themeService = themeService,
        _authController = authController;

  final GetProfileUseCase _getProfile;
  final UpdateNotificationSettingsUseCase _updateNotificationSettings;
  final ProfileRepository _repository;
  final ThemeService _themeService;
  final AuthController _authController;

  UserModel? user;
  bool isLoading = false;
  Failure? failure;

  late NotificationSettingsModel settings = _repository.notificationSettings;

  ThemeMode get themeMode => _themeService.themeMode;

  bool get isSigningOut => _authController.isLoading;

  @override
  void onInit() {
    super.onInit();

    // Render the cached profile instantly, then refresh in the background.
    user = _repository.cachedUser;
    load();
  }

  Future<void> load() async {
    isLoading = user == null;
    failure = null;
    update();

    final result = await _getProfile();

    isLoading = false;

    result.fold(
      (error) {
        // A cached profile on screen beats an error page.
        if (user == null) failure = error;
      },
      (loaded) => user = loaded,
    );
    update();
  }

  /// Named `reload` rather than `refresh` because `GetxController.refresh()`
  /// already means "notify listeners".
  Future<void> reload() => load();

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------
  Future<void> setThemeMode(ThemeMode mode) {
    // The service swaps the mode synchronously before persisting, so the
    // radio group can rebuild without waiting on storage.
    final saving = _themeService.setThemeMode(mode);
    update();
    return saving;
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Applies a change optimistically and rolls back if persistence fails.
  Future<void> updateSettings(NotificationSettingsModel updated) async {
    final previous = settings;
    settings = updated;
    update();

    final result = await _updateNotificationSettings(updated);

    result.fold(
      (error) {
        settings = previous;
        UiHelpers.showFailure(error);
      },
      (saved) => settings = saved,
    );
    update();
  }

  Future<void> togglePush(bool value) =>
      updateSettings(settings.copyWith(pushEnabled: value));

  Future<void> toggleComments(bool value) =>
      updateSettings(settings.copyWith(comments: value));

  Future<void> toggleStatusChanges(bool value) =>
      updateSettings(settings.copyWith(statusChanges: value));

  Future<void> toggleAssignments(bool value) =>
      updateSettings(settings.copyWith(assignments: value));

  Future<void> toggleNewTasks(bool value) =>
      updateSettings(settings.copyWith(newTasks: value));

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  /// Delegates to [AuthController] so there is one logout path in the app.
  Future<void> signOut() => _authController.logout();
}

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileDatasource(Get.find<ApiClient>()));
    Get.lazyPut(
      () => ProfileRepository(Get.find<ProfileDatasource>(), Get.find<AppStorage>()),
    );
    Get.lazyPut(() => GetProfileUseCase(Get.find<ProfileRepository>()));
    Get.lazyPut(
      () => UpdateNotificationSettingsUseCase(Get.find<ProfileRepository>()),
    );
    Get.lazyPut(
      () => ProfileController(
        getProfile: Get.find<GetProfileUseCase>(),
        updateNotificationSettings: Get.find<UpdateNotificationSettingsUseCase>(),
        repository: Get.find<ProfileRepository>(),
        themeService: Get.find<ThemeService>(),
        authController: Get.find<AuthController>(),
      ),
    );
  }
}
