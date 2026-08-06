import 'package:apx_task_management/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/entities/task_status.dart';
import '../controllers/task_list_controller.dart';
import 'task_card.dart';

class TaskListView extends StatefulWidget {
  const TaskListView({super.key, required this.status});

  final TaskStatus status;

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView>
    with AutomaticKeepAliveClientMixin {
  late final TaskListController controller = Get.find<TaskListController>(
    tag: widget.status.apiValue,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GetBuilder<TaskListController>(
      tag: widget.status.apiValue,
      builder: (controller) {
        // 1 — first load, nothing on screen yet.
        if (controller.isLoading && controller.tasks.isEmpty) {
          return const _LoadingList();
        }

        // 2 — first page failed.
        if (controller.failure != null && controller.tasks.isEmpty) {
          return AppErrorWidget(
            failure: controller.failure,
            onRetry: controller.loadFirstPage,
          );
        }

        // 3 — nothing to show.
        if (controller.tasks.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: EmptyStateWidget(
                  title: AppStrings.noTasks,
                  subtitle: AppStrings.noTasksSubtitle,
                  icon: _iconFor(widget.status),
                ),
              ),
            ),
          );
        }

        // 4 — the list.
        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView.separated(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
            itemCount: controller.tasks.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              if (index == controller.tasks.length) {
                return _ListFooter(controller: controller);
              }

              final task = controller.tasks[index];

              return TaskCard(
                task: task,
                onTap: () {
                  Get.toNamed(AppRoutes.taskDetails, arguments: task);
                },
              );
            },
          ),
        );
      },
    );
  }

  IconData _iconFor(TaskStatus status) => switch (status) {
    TaskStatus.newTask => Icons.fiber_new_rounded,
    TaskStatus.inProgress => Icons.play_circle_outline_rounded,
    TaskStatus.readyfortesting => Icons.pending_actions_rounded,
    TaskStatus.testing => Icons.bug_report_outlined,
    TaskStatus.completed => Icons.check_circle_outline_rounded,
    TaskStatus.closed => Icons.cancel_outlined,
  };
}

/// Trailing element: pagination spinner, retry row, or an end-of-list marker.
class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.controller});

  final TaskListController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingMore) {
      return const PaginationLoader();
    }

    final error = controller.paginationError;

    if (error != null) {
      return Padding(
        padding: EdgeInsets.only(top: 16.h),
        child: AppErrorWidget(
          failure: error,
          compact: true,
          onRetry: () {
            controller.clearPaginationError();
            controller.loadMore();
          },
        ),
      );
    }

    if (!controller.hasMore && controller.tasks.length > 5) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text(
            'That’s everything',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(height: 8.h);
  }
}

/// Skeleton list shown during the first load.
class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
      itemCount: 5,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => const TaskCardSkeleton(),
    );
  }
}
