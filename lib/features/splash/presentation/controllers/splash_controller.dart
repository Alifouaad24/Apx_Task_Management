import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../domain/usecases/resolve_startup_route_usecase.dart';

class SplashController extends GetxController {
  SplashController({
    required ResolveStartupRouteUseCase resolveStartupRoute,
    required NotificationService notifications,
  }) : _resolveStartupRoute = resolveStartupRoute,
       _notifications = notifications;

  final ResolveStartupRouteUseCase _resolveStartupRoute;
  final NotificationService _notifications;

  @override
  void onReady() {
    super.onReady();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final results = await Future.wait([
      _resolveStartupRoute(),
      Future<void>.delayed(AppConfig.splashMinimumDuration),
    ]);

    final destination = results.first as StartupDestination;
    AppLogger.i('Startup → ${destination.route} (${destination.status.name})');

    await Get.offAllNamed(destination.route);

    if (destination.sessionWasExpired) {
      UiHelpers.showInfo(
        'Your session expired. Please sign in again.',
        title: 'Signed out',
      );
    }

    if (destination.route == AppRoutes.home) {
      _notifications.handlePendingPayload();
    }
  }
}
