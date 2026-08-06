import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/notifications/notification_channels.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/session_manager.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_status.dart';
import 'task_list_controller.dart';

/// Dashboard shell: owns the tab bar, the greeting header, the search box and
/// the cross-tab synchronisation that keeps lists honest after a status change.
///
/// The per-tab data lives in [TaskListController]; this controller never
/// fetches tasks itself.
class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  HomeController({
    required SessionManager session,
    required NotificationService notifications,
    required AnalyticsService analytics,
  }) : _session = session,
       _notifications = notifications,
       _analytics = analytics;

  final SessionManager _session;
  final NotificationService _notifications;
  final AnalyticsService _analytics;

  late final TabController tabController;

  final List<TaskStatus> statuses = TaskStatus.tabOrder;

  final TextEditingController searchController = TextEditingController();
  int currentIndex = 0;
  String searchQuery = '';
  bool isSearching = false;

  Timer? _searchDebounce;
  StreamSubscription<dynamic>? _pushSubscription;

  TaskStatus get currentStatus => statuses[currentIndex];

  String get userName => _session.currentUserName;

  String? get userAvatar => _session.currentUserAvatar;

  /// `Good morning` / `Good afternoon` / `Good evening`.
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void onInit() {
    super.onInit();

    tabController = TabController(length: statuses.length, vsync: this)
      ..addListener(_onTabChanged);

    _listenForPushUpdates();

    // Any notification the user already saw is stale once they open the board.
    _notifications.clearAll();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _pushSubscription?.cancel();
    tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    searchController.dispose();
    super.onClose();
  }

  void _onTabChanged() {
    // Fires twice per swipe (start + settle); only react to the settled value.
    if (tabController.indexIsChanging) return;
    if (currentIndex == tabController.index) return;

    currentIndex = tabController.index;
    _analytics.logTabViewed(currentStatus.apiValue);

    // A tab marked stale by a status change elsewhere reloads on arrival.
    unawaited(_controllerFor(currentStatus)?.reloadIfStale() ?? Future.value());
  }

  /// Jumps to the tab that holds [status].
  void goToStatusTab(TaskStatus status) {
    final index = statuses.indexOf(status);
    if (index != -1) tabController.animateTo(index);
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------
  void toggleSearch() {
    isSearching = !isSearching;
    if (!isSearching) {
      searchController.clear();
      _applySearch('');
    }
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppConfig.inputDebounce, () => _applySearch(value));
  }

  void _applySearch(String value) {
    searchQuery = value;
    update();
    for (final status in statuses) {
      final controller = _controllerFor(status);
      if (controller == null) continue;

      if (status == currentStatus) {
        controller.applySearch(value);
      } else {
        controller
          ..applySearch(value)
          ..markStale();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cross-tab synchronisation
  // ---------------------------------------------------------------------------
  TaskListController? _controllerFor(TaskStatus status) {
    return Get.isRegistered<TaskListController>(tag: status.apiValue)
        ? Get.find<TaskListController>(tag: status.apiValue)
        : null;
  }

  /// Called by the task details screen after a successful status change.
  ///
  /// The task leaves its old tab immediately and the destination tab is marked
  /// stale, which is cheaper (and less jarring) than refetching everything.
  void onTaskStatusChanged({
    required TaskEntity task,
    required TaskStatus previousStatus,
  }) {
    if (previousStatus == task.status) return;

    _controllerFor(previousStatus)?.removeTask(task.id);

    final destination = _controllerFor(task.status);
    if (destination == null) return;

    if (task.status == currentStatus) {
      destination.upsertTask(task);
    } else {
      destination.markStale();
    }
  }

  /// Called when a task's comment count changes.
  void onTaskUpdated(TaskEntity task) =>
      _controllerFor(task.status)?.upsertTask(task);

  /// Reloads the visible tab; wired to pull-to-refresh and the retry button.
  Future<void> reloadCurrentTab() async =>
      _controllerFor(currentStatus)?.reload();

  // ---------------------------------------------------------------------------
  // Push notifications
  // ---------------------------------------------------------------------------

  /// A push about a task means our lists may be out of date. Rather than
  /// blindly refetching six tabs, refresh the visible one and mark the rest.
  void _listenForPushUpdates() {
    _pushSubscription = _notifications.onMessage.listen((payload) {
      switch (payload.type) {
        case PushType.taskCreated:
        case PushType.taskAssigned:
        case PushType.statusChanged:
          for (final status in statuses) {
            final controller = _controllerFor(status);
            if (controller == null) continue;
            if (status == currentStatus) {
              controller.reload();
            } else {
              controller.markStale();
            }
          }
        case PushType.commentAdded:
        case PushType.general:
          // Comment counts are refreshed when the task is opened.
          break;
      }
    });
  }

  void openProfile() => Get.toNamed(AppRoutes.profile);

  void onTaskCreated(TaskEntity task) {
    final destination = _controllerFor(task.status);
    if (destination == null) return;

    if (task.status == currentStatus) {
      destination.upsertTask(task);
    } else {
      destination.markStale();
    }

    goToStatusTab(task.status);
  }

  // void openTask(TaskEntity task) {
  //   _analytics.logTaskOpened(task.id.toString());
  //   Get.toNamed(
  //     AppRoutes.taskDetails,
  //     parameters: {RouteParams.taskId: task.id.toString()},
  //   );
  // }
}
