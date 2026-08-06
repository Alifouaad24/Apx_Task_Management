import 'package:apx_task_management/features/tasks/presentation/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/presentation/pages/create_task_page.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/bindings/splash_binding.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/tasks/presentation/pages/task_details_page.dart';
import '../../features/tasks/presentation/bindings/home_binding.dart';
import '../../features/tasks/presentation/pages/home_page.dart';
import 'app_routes.dart';


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
