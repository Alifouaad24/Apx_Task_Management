import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/notifications.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/auth/auth_usecases.dart';

// --------------------------------------------------------------------------
// Resolve startup route usecase
// --------------------------------------------------------------------------

class StartupDestination {
  const StartupDestination({required this.route, required this.status});

  final String route;
  final SessionStatus status;

  bool get sessionWasExpired => status == SessionStatus.expired;
}

class ResolveStartupRouteUseCase {
  const ResolveStartupRouteUseCase(this._checkSession);

  final CheckSessionUseCase _checkSession;

  Future<StartupDestination> call() async {
    final result = await _checkSession();

    return result.fold(
      (_) => const StartupDestination(
        route: AppRoutes.login,
        status: SessionStatus.missing,
      ),
      (status) => StartupDestination(
        route: status == SessionStatus.valid ? AppRoutes.home : AppRoutes.login,
        status: status,
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Splash controller
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Splash binding
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Splash page
// --------------------------------------------------------------------------

/// Branded startup screen shown while the session is being resolved.
class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const _AnimatedLogo(),
              SizedBox(height: 24.h),
              Text(
                AppConfig.appName,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Your team’s work, in one place',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 22.w,
                width: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo mark that fades and scales in on first frame.
class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 96.w,
          width: 96.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Icon(Icons.task_alt_rounded, size: 48.sp, color: Colors.white),
        ),
      ),
    );
  }
}
