import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/network.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/auth/auth_controller.dart';
import 'package:apx_task_management/features/auth/auth_models.dart';
import 'package:apx_task_management/features/auth/auth_usecases.dart';
import 'package:apx_task_management/features/profile/profile_models.dart';
import 'package:apx_task_management/features/profile/profile_repository.dart';
import 'package:apx_task_management/features/profile/profile_usecases.dart';

// --------------------------------------------------------------------------
// Profile controller
// --------------------------------------------------------------------------

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

  final Rxn<UserEntity> user = Rxn<UserEntity>();
  final RxBool isLoading = false.obs;
  final Rxn<Failure> failure = Rxn<Failure>();

  late final Rx<NotificationSettingsEntity> settings =
      _repository.notificationSettings.obs;

  ThemeMode get themeMode => _themeService.themeMode.value;

  Rx<ThemeMode> get themeModeRx => _themeService.themeMode;

  RxBool get isSigningOut => _authController.isLoading;

  @override
  void onInit() {
    super.onInit();

    // Render the cached profile instantly, then refresh in the background.
    user.value = _repository.cachedUser;
    load();
  }

  Future<void> load() async {
    isLoading.value = user.value == null;
    failure.value = null;

    final result = await _getProfile(const NoParams());

    isLoading.value = false;

    result.fold(
      (error) {
        // A cached profile on screen beats an error page.
        if (user.value == null) failure.value = error;
      },
      (loaded) => user.value = loaded,
    );
  }

  /// Named `reload` rather than `refresh` because `GetxController.refresh()`
  /// already means "notify listeners".
  Future<void> reload() => load();

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------
  Future<void> setThemeMode(ThemeMode mode) => _themeService.setThemeMode(mode);

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Applies a change optimistically and rolls back if persistence fails.
  Future<void> updateSettings(NotificationSettingsEntity updated) async {
    final previous = settings.value;
    settings.value = updated;

    final result = await _updateNotificationSettings(updated);

    result.fold(
      (error) {
        settings.value = previous;
        UiHelpers.showFailure(error);
      },
      (saved) => settings.value = saved,
    );
  }

  Future<void> togglePush(bool value) =>
      updateSettings(settings.value.copyWith(pushEnabled: value));

  Future<void> toggleComments(bool value) =>
      updateSettings(settings.value.copyWith(comments: value));

  Future<void> toggleStatusChanges(bool value) =>
      updateSettings(settings.value.copyWith(statusChanges: value));

  Future<void> toggleAssignments(bool value) =>
      updateSettings(settings.value.copyWith(assignments: value));

  Future<void> toggleNewTasks(bool value) =>
      updateSettings(settings.value.copyWith(newTasks: value));

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  /// Delegates to [AuthController] so there is one logout path in the app.
  Future<void> signOut() => _authController.logout();
}

// --------------------------------------------------------------------------
// Profile binding
// --------------------------------------------------------------------------

/// Wires the profile screen.
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // ---- Data ---------------------------------------------------------------
    Get.lazyPut<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(Get.find<ApiClient>()),
    );

    Get.lazyPut<ProfileLocalDataSource>(
      () => ProfileLocalDataSourceImpl(
        storage: Get.find<StorageService>(),
        session: Get.find<SessionManager>(),
      ),
    );

    Get.lazyPut<ProfileRepository>(
      () => ProfileRepositoryImpl(
        remote: Get.find<ProfileRemoteDataSource>(),
        local: Get.find<ProfileLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
    );

    // ---- Domain -------------------------------------------------------------
    Get.lazyPut<GetProfileUseCase>(
      () => GetProfileUseCase(Get.find<ProfileRepository>()),
    );
    Get.lazyPut<UpdateNotificationSettingsUseCase>(
      () => UpdateNotificationSettingsUseCase(Get.find<ProfileRepository>()),
    );

    // ---- Presentation -------------------------------------------------------
    // Sign-out lives in AuthController; if the user reached profile without
    // passing through login (a restored session), it may not exist yet.
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          loginUseCase: Get.find<LoginUseCase>(),
          logoutUseCase: Get.find<LogoutUseCase>(),
        ),
        permanent: true,
      );
    }

    Get.lazyPut<ProfileController>(
      () => ProfileController(
        getProfile: Get.find<GetProfileUseCase>(),
        updateNotificationSettings:
            Get.find<UpdateNotificationSettingsUseCase>(),
        repository: Get.find<ProfileRepository>(),
        themeService: Get.find<ThemeService>(),
        authController: Get.find<AuthController>(),
      ),
    );
  }
}
