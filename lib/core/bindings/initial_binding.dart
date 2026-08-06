import 'package:get/get.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_session_usecase.dart';
import '../../features/auth/domain/usecases/get_cached_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../services/session_manager.dart';

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
