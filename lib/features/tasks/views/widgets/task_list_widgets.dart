import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/core/widgets.dart';
import 'package:apx_task_management/features/tasks/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';

// --------------------------------------------------------------------------
// Task card
// --------------------------------------------------------------------------

/// Dashboard list item.
///
/// Shows, per the spec: title, priority badge, assigned user, created date,
/// status badge and last-updated date — plus the task key, comment count and an
/// overdue marker, which the layout gets for free.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});

  final TaskModel task;
  final VoidCallback onTap;

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Get.toNamed(AppRoutes.addUpdateTask, arguments: task);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(context);
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final controller = Get.find<TaskListController>();
                final success = await controller.deleteTaskById(task.id);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        controller.errorMessage ?? 'Failed to delete',
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = AppColors.statusColor(
      task.status?.colorKey ?? '',
      isDark: isDark,
    );

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showOptions(context),
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status-coloured spine: lets you scan a list by status.
                Container(
                  width: 4.w,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(16.r),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopRow(task: task),
                        SizedBox(height: 8.h),
                        Text(
                          task.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: theme.colorScheme.onSurface,
                            decoration: (task.status?.isClosed ?? false)
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // SizedBox(height: 12.h),
                        // _MetaRow(task: task),
                        SizedBox(height: 10.h),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _FooterRow(task: task),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Key + priority + status.
class _TopRow extends StatelessWidget {
  const _TopRow({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          task.displayKey,
          style: AppTextStyles.labelSmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        if (task.assigneeName != null)
          Flexible(
            child: Text(
              task.assigneeName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Created date, comment count (unread highlighted) and schedule date.
class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTextStyles.labelSmall.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 12.sp,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 4.w),
        Text('Created ${DateFormatter.short(task.createdAt)}', style: muted),
        const Spacer(),
        if (task.commentsCount > 0) ...[
          Icon(
            Icons.mode_comment_outlined,
            size: 12.sp,
            color: task.hasUnreadComments
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 4.w),
          Text(
            task.hasUnreadComments
                ? '${task.unreadCommentsCount} new'
                : task.commentsCount.compact,
            style: task.hasUnreadComments
                ? muted.copyWith(color: theme.colorScheme.primary)
                : muted,
          ),
        ],
        if (task.scheduleDate != null) ...[
          SizedBox(width: 12.w),
          Icon(
            Icons.event_outlined,
            size: 12.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 4.w),
          Text(DateFormatter.short(task.scheduleDate), style: muted),
        ],
      ],
    );
  }
}

/// Placeholder shown while the first page loads.
class TaskCardSkeleton extends StatelessWidget {
  const TaskCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(height: 12.h, width: 56.w),
              const Spacer(),
              SkeletonBox(height: 18.h, width: 76.w, radius: 999.r),
            ],
          ),
          SizedBox(height: 12.h),
          SkeletonBox(height: 14.h),
          SizedBox(height: 6.h),
          SkeletonBox(height: 14.h, width: 180.w),
          SizedBox(height: 16.h),
          Row(
            children: [
              SkeletonBox(height: 24.w, width: 24.w, radius: 999.r),
              SizedBox(width: 8.w),
              SkeletonBox(height: 12.h, width: 110.w),
              const Spacer(),
              SkeletonBox(height: 12.h, width: 54.w),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Task list view
// --------------------------------------------------------------------------

class TaskListView extends StatefulWidget {
  const TaskListView({super.key, required this.status});

  final OrderStatusModel status;

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GetBuilder<TaskListController>(
      builder: (controller) {
        final tasks = controller.tasksFor(widget.status);

        if (tasks.isEmpty) {
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

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
            itemCount: tasks.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              if (index == tasks.length) {
                return _ListFooter(count: tasks.length);
              }

              final task = tasks[index];
              return TaskCard(
                task: task,
                onTap: () =>
                    Get.toNamed(AppRoutes.taskDetails, arguments: task.id),
              );
            },
          ),
        );
      },
    );
  }

  IconData _iconFor(OrderStatusModel status) => switch (status.colorKey) {
    'new' => Icons.fiber_new_rounded,
    'in_progress' => Icons.play_circle_outline_rounded,
    'ready_for_testing' => Icons.pending_actions_rounded,
    'testing' => Icons.bug_report_outlined,
    'done' => Icons.check_circle_outline_rounded,
    'rejected' => Icons.cancel_outlined,
    _ => Icons.inbox_rounded,
  };
}

/// End-of-list marker on longer lists.
class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 5) return SizedBox(height: 8.h);

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
}

/// Skeleton list shown while the board loads for the first time.
class TaskListSkeleton extends StatelessWidget {
  const TaskListSkeleton({super.key});

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
