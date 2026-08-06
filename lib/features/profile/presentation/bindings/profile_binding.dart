import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../auth/domain/usecases/login_usecase.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_notification_settings_usecase.dart';
import '../controllers/profile_controller.dart';

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
