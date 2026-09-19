import 'package:get/get.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/network.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/features/auth/auth_controller.dart';
import 'package:apx_task_management/features/auth/auth_repository.dart';
import 'package:apx_task_management/features/auth/auth_usecases.dart';
import 'package:apx_task_management/features/auth/login_page.dart';
import 'package:apx_task_management/features/profile/profile_controller.dart';
import 'package:apx_task_management/features/profile/profile_page.dart';
import 'package:apx_task_management/features/splash/splash.dart';
import 'package:apx_task_management/features/tasks/create_task_page.dart';
import 'package:apx_task_management/features/tasks/home_page.dart';
import 'package:apx_task_management/features/tasks/task_controllers.dart';
import 'package:apx_task_management/features/tasks/task_details_page.dart';

// --------------------------------------------------------------------------
// App pages
// --------------------------------------------------------------------------

class AppPages {
  const AppPages._();

  static const String initial = AppRoutes.splash;
  static const Transition _defaultTransition = Transition.cupertino;
  
  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
      // No transition into the first screen.
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.taskDetails,
      page: () => const TaskDetailsPage(),
      // binding: HomeBinding(),
      transition: _defaultTransition,
    ), 
    GetPage(
      name: AppRoutes.addUpdateTask,
      page: () => const CreateTaskPage(),
      // binding: HomeBinding(),
      transition: _defaultTransition,
    ), 
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
      transition: _defaultTransition,
    ),
  ];
}

// --------------------------------------------------------------------------
// Initial binding
// --------------------------------------------------------------------------

/// App-wide dependency graph, attached to `GetMaterialApp.initialBinding`.
///
/// Long-lived *services* (storage, session, network, notifications, analytics,
/// theme) are bootstrapped in `main()` because they need to be awaited before
/// the first frame. This binding registers the shared **auth** stack, which
/// splash, login and profile all depend on — registering it once here avoids
/// three bindings racing to create the same repository.
///
/// Everything is `lazyPut`: nothing is constructed until something asks for it.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ---- Auth: data ---------------------------------------------------------
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(Get.find<ApiClient>()),
      fenix: true,
    );

    Get.lazyPut<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(Get.find<SessionManager>()),
      fenix: true,
    );

    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: Get.find<AuthRemoteDataSource>(),
        local: Get.find<AuthLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // ---- Auth: domain -------------------------------------------------------
    // `fenix` rebuilds these if GetX ever disposes them with a route, which
    // matters because the session flow can run again after a forced logout.
    Get.lazyPut<LoginUseCase>(
      () => LoginUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<LogoutUseCase>(
      () => LogoutUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<GetCachedUserUseCase>(
      () => GetCachedUserUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<CheckSessionUseCase>(
      () => CheckSessionUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
  }
}
