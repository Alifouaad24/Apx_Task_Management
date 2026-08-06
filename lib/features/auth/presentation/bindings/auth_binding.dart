import 'package:get/get.dart';

import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../controllers/auth_controller.dart';

/// Wires the login screen.
///
/// The auth *data* dependencies (data sources, repository, use cases) are
/// registered permanently in `InitialBinding` because splash, login and profile
/// all need them; this binding only owns the screen-scoped controller.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(
        loginUseCase: Get.find<LoginUseCase>(),
        logoutUseCase: Get.find<LogoutUseCase>(),
      ),
    );
  }
}
