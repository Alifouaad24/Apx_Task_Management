import 'package:get/get.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../auth/domain/usecases/check_session_usecase.dart';
import '../../domain/usecases/resolve_startup_route_usecase.dart';
import '../controllers/splash_controller.dart';

/// Wires the startup screen. Everything it needs beyond its own use case is
/// already permanent (registered in `InitialBinding`).
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResolveStartupRouteUseCase>(
      () => ResolveStartupRouteUseCase(Get.find<CheckSessionUseCase>()),
    );

    Get.put<SplashController>(
  SplashController(
    resolveStartupRoute: Get.find<ResolveStartupRouteUseCase>(),
    notifications: Get.find<NotificationService>(),
  ),
);
  }
}
