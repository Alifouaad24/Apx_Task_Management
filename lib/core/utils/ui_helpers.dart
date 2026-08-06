import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_strings.dart';
import '../errors/failures.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Snackbars, dialogs and bottom sheets, centralised so feedback looks the same
/// everywhere and controllers do not need a `BuildContext`.
class UiHelpers {
  const UiHelpers._();

  // ---------------------------------------------------------------------------
  // Snackbars
  // ---------------------------------------------------------------------------
  static void showSuccess(String message, {String? title}) => _snack(
        title: title ?? 'Done',
        message: message,
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );

  static void showError(String message, {String? title}) => _snack(
        title: title ?? AppStrings.somethingWentWrong,
        message: message,
        color: AppColors.danger,
        icon: Icons.error_rounded,
      );

  static void showInfo(String message, {String? title}) => _snack(
        title: title ?? 'Heads up',
        message: message,
        color: AppColors.info,
        icon: Icons.info_rounded,
      );

  /// Renders a [Failure] with the right tone (offline vs server error).
  static void showFailure(Failure failure) {
    final isOffline = failure is NetworkFailure;
    _snack(
      title: isOffline ? 'You are offline' : AppStrings.somethingWentWrong,
      message: failure.message,
      color: isOffline ? AppColors.warning : AppColors.danger,
      icon: isOffline ? Icons.wifi_off_rounded : Icons.error_rounded,
    );
  }

  static void _snack({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    // Replace any visible snackbar so rapid actions do not stack up.
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(12.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      borderRadius: 14.r,
      backgroundColor: Get.theme.colorScheme.surface,
      colorText: Get.theme.colorScheme.onSurface,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      borderColor: color.withValues(alpha: 0.35),
      borderWidth: 1,
      icon: Container(
        margin: EdgeInsets.only(left: 4.w),
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18.sp),
      ),
      titleText: Text(title, style: AppTextStyles.titleSmall),
      messageText: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(
          color: Get.theme.colorScheme.onSurfaceVariant,
        ),
      ),
      duration: const Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  /// Two-button confirmation. Resolves to `true` only when confirmed.
  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = AppStrings.confirm,
    String cancelLabel = AppStrings.cancel,
    bool isDestructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              cancelLabel,
              style: TextStyle(color: Get.theme.colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, 42.h),
              backgroundColor: isDestructive
                  ? Get.theme.colorScheme.error
                  : Get.theme.colorScheme.primary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    return result ?? false;
  }

  /// Dismisses the keyboard without needing a context.
  static void dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();
}
