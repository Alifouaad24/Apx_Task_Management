import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/core/widgets.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';

// --------------------------------------------------------------------------
// Task info section
// --------------------------------------------------------------------------

/// Card holding the task's people and dates. Rows the API left empty are
/// skipped.
class TaskInfoSection extends StatelessWidget {
  const TaskInfoSection({super.key, required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = [
      if (task.scheduleDate != null) DateFormatter.medium(task.scheduleDate),
      if (task.scheduleTime != null) task.scheduleTime!,
    ].join(' · ');

    final rows = <Widget>[
      if (task.customerName != null)
        _InfoRow(
          label: 'Customer',
          value: task.customerName!,
          icon: Icons.storefront_outlined,
        ),
      if (task.assignerName != null)
        _InfoRow(
          label: 'Assigner',
          value: task.assignerName!,
          icon: Icons.flag_outlined,
        ),
      _InfoRow(
        label: AppStrings.assignee,
        value: task.assigneeName ?? AppStrings.unassigned,
        icon: Icons.person_outline_rounded,
      ),
      if (schedule.isNotEmpty)
        _InfoRow(
          label: 'Scheduled',
          value: schedule,
          icon: Icons.event_outlined,
        ),
      if (task.createdAt != null)
        _InfoRow(
          label: AppStrings.created,
          value: DateFormatter.full(task.createdAt),
          icon: Icons.calendar_today_outlined,
        ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) _Separator(),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.7),
  );
}

/// Label + value row with a leading icon.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 17.sp, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 12.w),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Status selector
// --------------------------------------------------------------------------

/// Reusable status-change control.
///
/// The statuses come from the server, so there is no fixed workflow: any
/// status other than the current one is offered. It knows nothing about
/// tasks, controllers or the network.
class StatusSelector extends StatelessWidget {
  const StatusSelector({
    super.key,
    required this.current,
    required this.statuses,
    required this.onSelected,
    this.isBusy = false,
  });

  final OrderStatusModel? current;
  final List<OrderStatusModel> statuses;
  final ValueChanged<OrderStatusModel> onSelected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = this.current;
    final transitions = statuses.where((s) => s != current).toList();

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
              Text(
                'Status',
                style: AppTextStyles.labelMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (isBusy)
                SizedBox(
                  height: 14.w,
                  width: 14.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              else if (current != null)
                StatusChip(label: current.label, apiValue: current.colorKey),
            ],
          ),
          SizedBox(height: 14.h),
          StatusPipeline(current: current, statuses: statuses),
          SizedBox(height: 16.h),
          if (transitions.isEmpty)
            Text(
              AppStrings.noTransitions,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            Text(
              'Move to',
              style: AppTextStyles.labelMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final status in transitions)
                  _TransitionButton(
                    status: status,
                    enabled: !isBusy,
                    onTap: () => onSelected(status),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One tappable target status.
class _TransitionButton extends StatelessWidget {
  const _TransitionButton({
    required this.status,
    required this.enabled,
    required this.onTap,
  });

  final OrderStatusModel status;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.statusColor(status.colorKey, isDark: isDark);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.isClosed
                      ? Icons.cancel_outlined
                      : Icons.arrow_forward_rounded,
                  size: 15.sp,
                  color: color,
                ),
                SizedBox(width: 6.w),
                Text(
                  status.label,
                  style: AppTextStyles.labelMedium.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal stepper showing where the task sits among the service's
/// statuses, in the order the server lists them.
///
/// A closed task is drawn as a single full-width bar, because it has left the
/// flow rather than progressed through it.
class StatusPipeline extends StatelessWidget {
  const StatusPipeline({
    super.key,
    required this.current,
    required this.statuses,
  });

  final OrderStatusModel? current;
  final List<OrderStatusModel> statuses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final current = this.current;

    if (current != null && current.isClosed) {
      final color = AppColors.statusColor(current.colorKey, isDark: isDark);
      return Row(
        children: [
          Icon(Icons.block_rounded, size: 14.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            current.label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      );
    }

    final steps = statuses.where((s) => !s.isClosed).toList();
    final currentIndex = current == null ? -1 : steps.indexOf(current);

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: i <= currentIndex
                        ? AppColors.statusColor(
                            steps[i].colorKey,
                            isDark: isDark,
                          )
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
                if (i == currentIndex) ...[
                  SizedBox(height: 6.h),
                  Text(
                    steps[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.statusColor(
                        steps[i].colorKey,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
