import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../errors/failures.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Renders a [Failure] with an icon, a readable message and a retry action.
///
/// Taking the failure (rather than a plain string) lets the widget pick the
/// right icon and title per failure type, so error screens stay consistent
/// without every controller repeating that mapping.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.failure,
    this.message,
    this.onRetry,
    this.compact = false,
  });

  final Failure? failure;

  /// Overrides the message derived from [failure].
  final String? message;
  final VoidCallback? onRetry;

  /// Slimmer layout for inline use (e.g. inside a list section).
  final bool compact;

  IconData get _icon {
    return switch (failure) {
      NetworkFailure() => Icons.wifi_off_rounded,
      TimeoutFailure() => Icons.timer_off_outlined,
      UnauthorizedFailure() => Icons.lock_outline_rounded,
      ForbiddenFailure() => Icons.block_outlined,
      NotFoundFailure() => Icons.search_off_rounded,
      ServerFailure() => Icons.cloud_off_rounded,
      _ => Icons.error_outline_rounded,
    };
  }

  String get _title {
    return switch (failure) {
      NetworkFailure() => 'You are offline',
      TimeoutFailure() => 'This is taking too long',
      UnauthorizedFailure() => 'Session expired',
      ForbiddenFailure() => 'Not allowed',
      NotFoundFailure() => 'Nothing here',
      ServerFailure() => 'Server problem',
      _ => AppStrings.somethingWentWrong,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = message ?? failure?.message ?? AppStrings.somethingWentWrong;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32.w,
          vertical: compact ? 16.h : 32.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 12.w : 18.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                size: compact ? 24.sp : 34.sp,
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: compact ? 12.h : 18.h),
            if (!compact) ...[
              Text(
                _title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium
                    .copyWith(color: theme.colorScheme.onSurface),
              ),
              SizedBox(height: 6.h),
            ],
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 20.h),
              AppButton.outline(
                label: AppStrings.retry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
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
