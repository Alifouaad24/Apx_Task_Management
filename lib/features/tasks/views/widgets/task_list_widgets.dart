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

/// Dashboard list item: key and status dot, notes, date chips (with an
/// overdue deadline in red), assignee, comment count and age. Long-press or
/// the ⋯ button opens edit / delete.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});

  final TaskModel task;
  final VoidCallback onTap;

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = AppColors.statusColor(
      task.status?.colorKey ?? '',
      isDark: isDark,
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        // Shadows vanish on dark surfaces, so dark mode relies on the border.
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF101828).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showOptions(context),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.w, 8.h, 6.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopRow(
                  task: task,
                  statusColor: statusColor,
                  onMore: () => _showOptions(context),
                ),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 10.w),
                  child: Text(
                    task.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      decoration: (task.status?.isClosed ?? false)
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                _TaskDates(task: task),
                SizedBox(height: 14.h),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 10.w),
                  child: _FooterRow(task: task),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status dot + key, the unread badge and the options button.
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.task,
    required this.statusColor,
    required this.onMore,
  });

  final TaskModel task;
  final Color statusColor;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = Get.find<TaskListController>().unreadFromOthersCount(task);

    return Row(
      children: [
        Container(
          height: 8.w,
          width: 8.w,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          task.displayKey,
          style: AppTextStyles.labelMedium.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const Spacer(),
        if (unread > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_chat_unread_rounded,
                  size: 12.sp,
                  color: scheme.primary,
                ),
                SizedBox(width: 4.w),
                Text(
                  '$unread new',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          onPressed: onMore,
          tooltip: 'Options',
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.more_horiz_rounded,
            size: 20.sp,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Assignee on the left; comment count and age on the right.
class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = AppTextStyles.labelSmall.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final assignee = task.assigneeName;

    return Row(
      children: [
        if (assignee != null) ...[
          UserAvatar(name: assignee, size: 24.w),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              assignee,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else ...[
          Icon(
            Icons.person_off_outlined,
            size: 16.sp,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(width: 6.w),
          Text(AppStrings.unassigned, style: muted),
        ],
        SizedBox(width: 12.w),
        const Spacer(),
        if (task.commentsCount > 0) ...[
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 13.sp,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(width: 4.w),
          Text(task.commentsCount.compact, style: muted),
          SizedBox(width: 12.w),
        ],
        Icon(
          Icons.schedule_rounded,
          size: 13.sp,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: 4.w),
        Text(DateFormatter.relative(task.createdAt), style: muted),
      ],
    );
  }
}

/// Start, deadline, schedule and active duration as compact chips. The
/// deadline turns red once it has passed on an unfinished task.
class _TaskDates extends StatelessWidget {
  const _TaskDates({required this.task});

  final TaskModel task;

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  int? _activeDuration(DateTime? start, DateTime? end) {
    if (start == null) return null;

    final startDay = DateTime(start.year, start.month, start.day);
    final endDate = end ?? DateTime.now();
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);

    return endDay.difference(startDay).inDays.clamp(0, 999999);
  }

  bool _isOverdue(DateTime deadline, DateTime? end) {
    if (end != null) return false;
    final status = task.status;
    if (status != null && (status.isCompleted || status.isClosed)) {
      return false;
    }
    final now = DateTime.now();
    return deadline.isBefore(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    final start = _parseDate(task.startTaskProgressdDate);
    final deadline = _parseDate(task.deadLine);
    final end = _parseDate(task.endTaskDate);
    final duration = _activeDuration(start, end);

    final chips = <Widget>[
      if (start != null)
        _InfoChip(
          icon: Icons.play_arrow_rounded,
          text: 'Started ${DateFormatter.short(start)}',
        ),
      if (deadline != null)
        _InfoChip(
          icon: Icons.flag_outlined,
          text: 'Due ${DateFormatter.short(deadline)}',
          color: _isOverdue(deadline, end) ? AppColors.danger : null,
        ),
      if (task.scheduleDate != null)
        _InfoChip(
          icon: Icons.event_outlined,
          text: DateFormatter.short(task.scheduleDate),
        ),
      if (duration != null)
        _InfoChip(
          icon: Icons.timelapse_rounded,
          text: duration == 1 ? '1 day' : '$duration days',
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsetsDirectional.only(top: 12.h, end: 10.w),
      child: Wrap(spacing: 6.w, runSpacing: 6.h, children: chips),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;

  /// Overrides the neutral tint, e.g. red for an overdue deadline.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: tint),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: tint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(height: 8.w, width: 8.w, radius: 999.r),
              SizedBox(width: 8.w),
              SkeletonBox(height: 12.h, width: 48.w),
              const Spacer(),
              SkeletonBox(height: 18.h, width: 56.w, radius: 999.r),
            ],
          ),
          SizedBox(height: 14.h),
          SkeletonBox(height: 16.h),
          SizedBox(height: 6.h),
          SkeletonBox(height: 16.h, width: 180.w),
          SizedBox(height: 14.h),
          Row(
            children: [
              SkeletonBox(height: 22.h, width: 90.w, radius: 8.r),
              SizedBox(width: 6.w),
              SkeletonBox(height: 22.h, width: 70.w, radius: 8.r),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              SkeletonBox(height: 24.w, width: 24.w, radius: 999.r),
              SizedBox(width: 8.w),
              SkeletonBox(height: 12.h, width: 100.w),
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
                height: MediaQuery.sizeOf(context).height * 0.45,
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
            // Bottom room so the "New task" button never covers the last card.
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
            itemCount: tasks.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: 14.h),
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

    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Row(
        children: [
          Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              'That’s everything',
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
          Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
        ],
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
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      itemCount: 5,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => SizedBox(height: 14.h),
      itemBuilder: (_, __) => const TaskCardSkeleton(),
    );
  }
}
