import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Colour-coded badge for a task status.
///
/// Takes the raw API value plus a display label rather than the `TaskStatus`
/// enum, so this core widget stays independent of the tasks feature.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.apiValue,
    this.compact = false,
    this.showDot = true,
  });

  final String label;
  final String apiValue;
  final bool compact;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.statusColor(apiValue, isDark: isDark);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.w : 10.w,
        vertical: compact ? 3.h : 5.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              height: 6.w,
              width: 6.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: (compact
                    ? AppTextStyles.labelSmall
                    : AppTextStyles.labelMedium)
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Colour-coded badge for a task priority.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.label,
    required this.apiValue,
    this.compact = false,
  });

  final String label;
  final String apiValue;
  final bool compact;

  /// Arrow direction communicates urgency at a glance, alongside the colour —
  /// important for colour-blind users.
  IconData get _icon => switch (apiValue) {
        'low' => Icons.keyboard_arrow_down_rounded,
        'medium' => Icons.remove_rounded,
        'high' => Icons.keyboard_arrow_up_rounded,
        'urgent' => Icons.keyboard_double_arrow_up_rounded,
        _ => Icons.remove_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.priorityColor(apiValue, isDark: isDark);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.w : 8.w,
        vertical: compact ? 3.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 12.sp : 14.sp, color: color),
          SizedBox(width: 3.w),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
