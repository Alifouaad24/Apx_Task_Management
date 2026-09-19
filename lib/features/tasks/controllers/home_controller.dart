import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/api_client.dart';
import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/notifications.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/features/auth/usecases/auth_usecases.dart';
import 'package:apx_task_management/features/tasks/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/datasources/task_datasource.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';
import 'package:apx_task_management/features/tasks/repositories/task_repository.dart';
import 'package:apx_task_management/features/tasks/usecases/task_usecases.dart';

/// Dashboard shell: tab bar, greeting header and search box. The tabs come
/// from the statuses the server returns, so the [TabController] is rebuilt
/// whenever that list changes. The data itself lives in [TaskListController].
class HomeController extends GetxController with GetTickerProviderStateMixin {
  HomeController({
    required TaskListController board,
    required GetCurrentUserUseCase getCurrentUser,
    required NotificationService notifications,
    required AnalyticsService analytics,
  }) : _board = board,
       _getCurrentUser = getCurrentUser,
       _notifications = notifications,
       _analytics = analytics;

  final TaskListController _board;
  final GetCurrentUserUseCase _getCurrentUser;
  final NotificationService _notifications;
  final AnalyticsService _analytics;

  /// `null` until the statuses have loaded.
  TabController? tabController;
  List<OrderStatusModel> statuses = const [];
  final TextEditingController searchController = TextEditingController();

  bool isSearching = false;

  Timer? _searchDebounce;
  StreamSubscription<PushPayload>? _pushSubscription;

  OrderStatusModel? get currentStatus {
    final index = tabController?.index;
    return index == null || index >= statuses.length ? null : statuses[index];
  }

  String get userName => _getCurrentUser()?.name ?? '';

  String? get userAvatar => _getCurrentUser()?.avatarUrl;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void onInit() {
    super.onInit();

    _board.addListener(_syncTabs);
    _syncTabs();

    _pushSubscription = _notifications.onMessage.listen(_onPush);

    // Any notification the user already saw is stale once they open the board.
    _notifications.clearAll();
  }

  @override
  void onClose() {
    _board.removeListener(_syncTabs);
    _searchDebounce?.cancel();
    _pushSubscription?.cancel();
    tabController?.dispose();
    searchController.dispose();
    super.onClose();
  }

  /// Rebuilds the tabs when the board's statuses differ from ours, keeping the
  /// user on the same status if it still exists.
  void _syncTabs() {
    final next = _board.statuses;
    if (listEquals(next, statuses)) return;

    final current = currentStatus;
    final old = tabController;

    statuses = List.unmodifiable(next);
    final keptIndex = current == null ? -1 : statuses.indexOf(current);
    tabController = TabController(
      length: statuses.length,
      initialIndex: keptIndex < 0 ? 0 : keptIndex,
      vsync: this,
    )..addListener(_onTabChanged);

    // The old controller is still attached to the tab bar until the next frame.
    if (old != null) {
      old.removeListener(_onTabChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    update();
  }

  void _onTabChanged() {
    // Fires twice per swipe (start + settle); only react to the settled value.
    if (tabController?.indexIsChanging ?? true) return;
    final status = currentStatus;
    if (status != null) _analytics.logTabViewed(status.nameEn);
  }

  void goToStatusTab(OrderStatusModel status) {
    final index = statuses.indexOf(status);
    if (index != -1) tabController?.animateTo(index);
  }

  void openProfile() => Get.toNamed(AppRoutes.profile);

  void openCreateTask() => Get.toNamed(AppRoutes.addUpdateTask);

  Future<void> reload() => _board.reload();

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------
  void toggleSearch() {
    isSearching = !isSearching;
    if (!isSearching) {
      searchController.clear();
      _board.applySearch('');
    }
    update();
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      AppConfig.inputDebounce,
      () => _board.applySearch(value),
    );
  }

  /// A push about a task may mean the board is out of date.
  void _onPush(PushPayload payload) {
    switch (payload.type) {
      case PushType.taskCreated:
      case PushType.taskAssigned:
      case PushType.statusChanged:
        _board.reload();
      case PushType.commentAdded:
      case PushType.general:
        break;
    }
  }
}

/// Wires the dashboard: datasource → repository → use cases → controllers.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TaskDatasource(Get.find<ApiClient>()));
    Get.lazyPut(() => TaskRepository(Get.find<TaskDatasource>()));

    Get.lazyPut(
      () => GetTaskScopeUseCase(
        Get.find<GetCurrentUserUseCase>(),
        Get.find<GetCurrentBusinessUseCase>(),
      ),
    );
    Get.lazyPut(() => LoadTaskBoardUseCase(Get.find<TaskRepository>()));
    Get.lazyPut(() => DeleteTaskUseCase(Get.find<TaskRepository>()));
    Get.lazyPut(() => AddCommentUseCase(Get.find<TaskRepository>()));
    Get.lazyPut(() => MarkCommentsReadUseCase(Get.find<TaskRepository>()));
    Get.lazyPut(() => ChangeStatusUseCase(Get.find<TaskRepository>()));

    Get.lazyPut(
      () => TaskListController(
        getScope: Get.find<GetTaskScopeUseCase>(),
        loadBoard: Get.find<LoadTaskBoardUseCase>(),
        deleteTask: Get.find<DeleteTaskUseCase>(),
        addComment: Get.find<AddCommentUseCase>(),
        markCommentsRead: Get.find<MarkCommentsReadUseCase>(),
        changeStatus: Get.find<ChangeStatusUseCase>(),
        getCurrentUser: Get.find<GetCurrentUserUseCase>(),
        loadBusinesses: Get.find<LoadBusinessesUseCase>(),
        getCurrentBusiness: Get.find<GetCurrentBusinessUseCase>(),
        selectBusiness: Get.find<SelectBusinessUseCase>(),
      ),
    );

    Get.lazyPut(
      () => HomeController(
        board: Get.find<TaskListController>(),
        getCurrentUser: Get.find<GetCurrentUserUseCase>(),
        notifications: Get.find<NotificationService>(),
        analytics: Get.find<AnalyticsService>(),
      ),
    );
  }
}
