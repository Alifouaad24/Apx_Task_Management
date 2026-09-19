import 'package:get/get.dart';

import 'package:apx_task_management/core/api_client.dart';
import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/storage.dart';
import 'package:apx_task_management/features/auth/controllers/auth_controller.dart';
import 'package:apx_task_management/features/auth/datasources/auth_datasource.dart';
import 'package:apx_task_management/features/auth/repositories/auth_repository.dart';
import 'package:apx_task_management/features/auth/usecases/auth_usecases.dart';
import 'package:apx_task_management/features/auth/views/login_page.dart';
import 'package:apx_task_management/features/profile/controllers/profile_controller.dart';
import 'package:apx_task_management/features/profile/views/profile_page.dart';
import 'package:apx_task_management/features/splash/controllers/splash_controller.dart';
import 'package:apx_task_management/features/splash/views/splash_page.dart';
import 'package:apx_task_management/features/tasks/controllers/home_controller.dart';
import 'package:apx_task_management/features/tasks/controllers/task_form_controller.dart';
import 'package:apx_task_management/features/tasks/views/create_task_page.dart';
import 'package:apx_task_management/features/tasks/views/home_page.dart';
import 'package:apx_task_management/features/tasks/views/task_details_page.dart';

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
      // Registers the board when the page is opened from a notification
      // before the dashboard; a no-op when the dashboard already did.
      binding: HomeBinding(),
      transition: _defaultTransition,
    ),
    GetPage(
      name: AppRoutes.addUpdateTask,
      page: () => const CreateTaskPage(),
      binding: TaskFormBinding(),
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

/// The auth stack, shared by splash, login, profile and tasks.
///
/// `fenix` recreates an instance if GetX disposed it with a route (e.g. the
/// login screen), so it is always there after a logout.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthDatasource(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut(
      () => AuthRepository(Get.find<AuthDatasource>(), Get.find<AppStorage>()),
      fenix: true,
    );
    Get.lazyPut(() => LoginUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(() => LogoutUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(
      () => IsLoggedInUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetCurrentUserUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => LoadBusinessesUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetCurrentBusinessUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SelectBusinessUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => AuthController(
        loginUseCase: Get.find<LoginUseCase>(),
        logoutUseCase: Get.find<LogoutUseCase>(),
      ),
      fenix: true,
    );
  }
}
