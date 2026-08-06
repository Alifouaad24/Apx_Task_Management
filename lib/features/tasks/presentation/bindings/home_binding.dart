import 'package:apx_task_management/features/tasks/domain/usecases/AddCommentUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/ChangeStatusUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/CreateTaskUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/DeleteTaskUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/GetBusinessesUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/GetGlobalSystemsUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/GetServicesUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/SetStatusClosedUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/SetStatusCompletedUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/UpdateTaskUseCase.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/session_manager.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../controllers/home_controller.dart';
import '../controllers/task_list_controller.dart';

/// Wires the dashboard: data source → repository → use case → controllers.
///
/// One [TaskListController] is registered per status, tagged with the status'
/// API value. They are lazy, so a tab's first page is only fetched when the
/// user actually opens that tab.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // ---- Data ---------------------------------------------------------------
    Get.lazyPut<TaskRemoteDataSource>(
      () => TaskRemoteDataSourceImpl(Get.find<ApiClient>()),
    );

    Get.lazyPut<TaskRepository>(
      () => TaskRepositoryImpl(
        remote: Get.find<TaskRemoteDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
    );

    // ---- Domain -------------------------------------------------------------
    Get.lazyPut<GetTasksUseCase>(
      () => GetTasksUseCase(Get.find<TaskRepository>()),
    );

    Get.lazyPut<CreateTaskUseCase>(
      () => CreateTaskUseCase(Get.find<TaskRepository>()),
    );
    Get.lazyPut<GetBusinessesUseCase>(
      () => GetBusinessesUseCase(Get.find<TaskRepository>()),
    );
    Get.lazyPut<GetServicesUseCase>(
      () => GetServicesUseCase(Get.find<TaskRepository>()),
    );
    Get.lazyPut<GetGlobalSystemsUseCase>(
      () => GetGlobalSystemsUseCase(Get.find<TaskRepository>()),
    );
    Get.lazyPut<UpdateTaskUseCase>(
      () => UpdateTaskUseCase(Get.find<TaskRepository>()),
    );
    Get.lazyPut<DeleteTaskUseCase>(
      () => DeleteTaskUseCase(Get.find<TaskRepository>()),
    );

    Get.lazyPut<AddCommentUseCase>(
      () => AddCommentUseCase(Get.find<TaskRepository>()),
    );

    Get.lazyPut<SetStatusClosedUseCase>(
      () => SetStatusClosedUseCase(Get.find<TaskRepository>()),
    );
    Get.lazyPut<SetStatusCompletedUseCase>(
      () => SetStatusCompletedUseCase(Get.find<TaskRepository>()),
    );

    Get.lazyPut<ChangeStatusUseCase>(
      () => ChangeStatusUseCase(Get.find<TaskRepository>()),
    );

    // ---- Presentation -------------------------------------------------------
    Get.lazyPut<HomeController>(
      () => HomeController(
        session: Get.find<SessionManager>(),
        notifications: Get.find<NotificationService>(),
        analytics: Get.find<AnalyticsService>(),
      ),
    );

    for (final status in TaskStatus.tabOrder) {
      Get.lazyPut<TaskListController>(
        () => TaskListController(
          status: status,
          getTasks: Get.find<GetTasksUseCase>(),
          changeStatusUseCase: Get.find<ChangeStatusUseCase>(),
          createTask: Get.find<CreateTaskUseCase>(),
          updateTask: Get.find<UpdateTaskUseCase>(), // ← جديد
          deleteTask: Get.find<DeleteTaskUseCase>(),
          setStatusClosed: Get.find<SetStatusClosedUseCase>(), // ← جديد
          setStatusCompleted: Get.find<SetStatusCompletedUseCase>(),
          getBusinesses: Get.find<GetBusinessesUseCase>(),
          addComment: Get.find<AddCommentUseCase>(),
          getServices: Get.find<GetServicesUseCase>(),
          getGlobalSystems: Get.find<GetGlobalSystemsUseCase>(),
          session: Get.find<SessionManager>(),
        ),
        tag: status.apiValue,
      );
    }
  }
}
