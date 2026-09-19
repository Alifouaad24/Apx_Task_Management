import 'dart:async';

import 'package:get/get.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/notifications.dart';
import 'package:apx_task_management/features/auth/usecases/auth_usecases.dart';

/// Shows the brand for a moment, then goes to home or login.
class SplashController extends GetxController {
  SplashController({
    required IsLoggedInUseCase isLoggedIn,
    required NotificationService notifications,
  })  : _isLoggedIn = isLoggedIn,
        _notifications = notifications;

  final IsLoggedInUseCase _isLoggedIn;
  final NotificationService _notifications;

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(AppConfig.splashMinimumDuration);

    if (!_isLoggedIn()) {
      await Get.offAllNamed(AppRoutes.login);
      return;
    }

    await Get.offAllNamed(AppRoutes.home);
    _notifications.handlePendingPayload();

    // Login registers the device too, but on iOS the APNs token can arrive
    // later than that; retrying each launch gets the token to the backend.
    // A no-op when the stored token is unchanged.
    unawaited(_notifications.registerDevice());
  }
}

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      SplashController(
        isLoggedIn: Get.find<IsLoggedInUseCase>(),
        notifications: Get.find<NotificationService>(),
      ),
    );
  }
}
