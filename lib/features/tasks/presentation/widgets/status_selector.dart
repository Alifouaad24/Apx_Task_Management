import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../tasks/domain/entities/task_status.dart';

/// Reusable status-change control.
///
/// Given the current status it renders the legal next steps (from
/// [TaskStatus.allowedTransitions]) and reports the user's choice. It knows
/// nothing about tasks, controllers or the network, so it can be dropped into
/// any screen that needs to move a task along.
class StatusSelector extends StatelessWidget {
  const StatusSelector({
    super.key,
    required this.current,
    required this.onSelected,
    this.isBusy = false,
  });

  final TaskStatus current;
  final ValueChanged<TaskStatus> onSelected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transitions = current.allowedTransitions;

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
              else
                StatusChip(
                  label: current.label,
                  apiValue: current.apiValue,
                ),
            ],
          ),
          SizedBox(height: 14.h),
          StatusPipeline(current: current),
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

  /// Opens the selector as a modal sheet — handy from a list or an app bar
  /// action where there is no room for the inline version.
  static Future<TaskStatus?> showSheet(
    BuildContext context, {
    required TaskStatus current,
  }) {
    return showModalBottomSheet<TaskStatus>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.changeStatus,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 16.h),
              StatusSelector(
                current: current,
                onSelected: (status) =>
                    Navigator.of(sheetContext).pop(status),
              ),
            ],
          ),
        ),
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

  final TaskStatus status;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.statusColor(status.apiValue, isDark: isDark);

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
                  status.isRejected
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

/// Horizontal stepper showing where the task sits in the workflow.
///
/// A rejected task is drawn as a single full-width error bar, because it has
/// left the pipeline rather than progressed through it.
class StatusPipeline extends StatelessWidget {
  const StatusPipeline({super.key, required this.current});

  final TaskStatus current;

  static const List<TaskStatus> _steps = [
    TaskStatus.newTask,
    TaskStatus.inProgress,
    TaskStatus.readyfortesting,
    TaskStatus.testing,
    TaskStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (current.isRejected) {
      final color = AppColors.statusColor('rejected', isDark: isDark);
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
            'Rejected',
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      );
    }

    final currentIndex = _steps.indexOf(current);

    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
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
                            _steps[i].apiValue,
                            isDark: isDark,
                          )
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
                if (i == currentIndex) ...[
                  SizedBox(height: 6.h),
                  Text(
                    _steps[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.statusColor(
                        _steps[i].apiValue,
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
