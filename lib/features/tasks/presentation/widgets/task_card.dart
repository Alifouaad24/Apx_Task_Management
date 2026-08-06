import 'package:apx_task_management/features/tasks/presentation/controllers/task_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_utils/get_utils.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/task_entity.dart';

/// Dashboard list item.
///
/// Shows, per the spec: title, priority badge, assigned user, created date,
/// status badge and last-updated date — plus the task key, comment count and an
/// overdue marker, which the layout gets for free.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});

  final TaskEntity task;
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
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final controller = Get.find<TaskListController>(
                    tag: task.status.apiValue,
                  );
                  await controller.prepareEdit(task); // ← ضفنا await
                  Get.toNamed(
                    '/addUpdateTask',
                    arguments: task.status.apiValue,
                  );
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
                final controller = Get.find<TaskListController>(
                  tag: task.status.apiValue,
                );
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
      task.status.apiValue,
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
                          task.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: theme.colorScheme.onSurface,
                            decoration: task.status.isRejected
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

  final TaskEntity task;

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
        // SizedBox(width: 8.w),
        // PriorityBadge(
        //   label: task.status.label,
        //   apiValue: task.status.apiValue,
        //   compact: true,
        // ),
        const Spacer(),
        // StatusChip(
        //   label: task.status.apiValue,
        //   apiValue: task.status.apiValue,
        //   compact: true,
        // ),
      ],
    );
  }
}

/// Assignee + due date.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // if (task.isAssigned) ...[
        //   UserAvatar(
        //     name: task.assignee!.displayName,
        //     imageUrl: task.assignee!.avatarUrl,
        //     size: 24.w,
        //   ),
        //   SizedBox(width: 8.w),
        //   Flexible(
        //     child: Text(
        //       task.assignee!.displayName,
        //       maxLines: 1,
        //       overflow: TextOverflow.ellipsis,
        //       style: AppTextStyles.bodySmall.copyWith(
        //         color: theme.colorScheme.onSurface,
        //       ),
        //     ),
        //   ),
        // ] else ...[
        Icon(
          Icons.person_off_outlined,
          size: 16.sp,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 6.w),
        Text(
          AppStrings.unassigned,
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Spacer(),
      ],

      // if (task.dueDate != null) _DueDateChip(task: task),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = task.isBlank;
    final color = overdue ?? false
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          overdue ?? false ? Icons.event_busy_rounded : Icons.event_outlined,
          size: 14.sp,
          color: color,
        ),
        SizedBox(width: 4.w),
        Text(
          DateFormatter.short(task.createdAt),
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: overdue ?? false ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Created date, comment count and last-updated date.
class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.task});

  final TaskEntity task;

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
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 4.w),
          Text(task.commentsCount.compact, style: muted),
          SizedBox(width: 12.w),
        ],
        Icon(
          Icons.update_rounded,
          size: 12.sp,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 4.w),
        Text(
          DateFormatter.relative(task.createdAt ?? task.createdAt),
          style: muted,
        ),
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
