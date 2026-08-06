import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Friendly placeholder for lists with nothing in them.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32.w,
          vertical: compact ? 20.h : 40.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: compact ? 56.w : 84.w,
              width: compact ? 56.w : 84.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.16),
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: compact ? 26.sp : 38.sp,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: compact ? 14.h : 20.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium
                  .copyWith(color: theme.colorScheme.onSurface),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6.h),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 20.h),
              AppButton.outline(
                label: actionLabel!,
                onPressed: onAction,
                size: AppButtonSize.medium,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
