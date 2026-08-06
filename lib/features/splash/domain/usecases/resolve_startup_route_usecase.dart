import '../../../../core/routes/app_routes.dart';
import '../../../auth/domain/usecases/check_session_usecase.dart';

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
