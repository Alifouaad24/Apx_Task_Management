import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/theme.dart';

// --------------------------------------------------------------------------
// Date formatter
// --------------------------------------------------------------------------

/// Date/time formatting helpers shared by task cards, details and comments.
class DateFormatter {
  const DateFormatter._();

  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy');
  static final DateFormat _full = DateFormat('d MMM yyyy • HH:mm');
  static final DateFormat _timeOnly = DateFormat('HH:mm');

  /// `12 Mar 2026` — drops the year when the date is in the current year.
  static String short(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    return local.year == DateTime.now().year
        ? _dayMonth.format(local)
        : _dayMonthYear.format(local);
  }

  /// `12 Mar 2026` — always includes the year.
  static String medium(DateTime? date) =>
      date == null ? '—' : _dayMonthYear.format(date.toLocal());

  /// `12 Mar 2026 • 14:03`.
  static String full(DateTime? date) =>
      date == null ? '—' : _full.format(date.toLocal());

  static String time(DateTime? date) =>
      date == null ? '—' : _timeOnly.format(date.toLocal());

  /// Human relative label: `just now`, `5m ago`, `3h ago`, `Yesterday`,
  /// `4d ago`, then falls back to an absolute date.
  static String relative(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    final diff = DateTime.now().difference(local);

    if (diff.isNegative) {
      // Future date (e.g. a due date) — describe the remaining time instead.
      final ahead = local.difference(DateTime.now());
      if (ahead.inMinutes < 60) return 'in ${ahead.inMinutes}m';
      if (ahead.inHours < 24) return 'in ${ahead.inHours}h';
      if (ahead.inDays < 7) return 'in ${ahead.inDays}d';
      return short(local);
    }

    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return short(local);
  }

  /// Groups timeline entries under `Today` / `Yesterday` / a date header.
  static String dayHeader(DateTime date) {
    final local = DateTime(date.toLocal().year, date.toLocal().month, date.toLocal().day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final delta = today.difference(local).inDays;

    if (delta == 0) return 'Today';
    if (delta == 1) return 'Yesterday';
    return medium(local);
  }

  /// `true` when a due date has passed.
  static bool isOverdue(DateTime? due) =>
      due != null && due.toLocal().isBefore(DateTime.now());

  /// Whole days remaining until [due]; negative once overdue.
  static int? daysUntil(DateTime? due) {
    if (due == null) return null;
    final now = DateTime.now();
    final target = due.toLocal();
    return DateTime(target.year, target.month, target.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }
}

// --------------------------------------------------------------------------
// Validators
// --------------------------------------------------------------------------

/// Reusable form validators wired into [AppTextField.validator].
///
/// Every validator returns `null` when the value is acceptable, matching the
/// `FormFieldValidator<String>` signature.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return AppStrings.emailRequired;
    if (!_emailPattern.hasMatch(input)) return AppStrings.emailInvalid;
    return null;
  }

  static String? password(String? value, {int minLength = 5}) {
    final input = value ?? '';
    if (input.isEmpty) return AppStrings.passwordRequired;
    if (input.length < minLength) return AppStrings.passwordTooShort;
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if ((value?.trim() ?? '').isEmpty) return '$field is required';
    return null;
  }

  static String? maxLength(String? value, int max, {String field = 'This field'}) {
    if ((value ?? '').length > max) {
      return '$field must be at most $max characters';
    }
    return null;
  }

  /// Runs validators in order and returns the first error found.
  static String? compose(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validate in validators) {
      final error = validate(value);
      if (error != null) return error;
    }
    return null;
  }
}

// --------------------------------------------------------------------------
// Extensions
// --------------------------------------------------------------------------

/// Small quality-of-life extensions used across the presentation layer.

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  double get bottomInset => MediaQuery.viewInsetsOf(this).bottom;
}

extension StringX on String {
  /// `'in progress'` → `'In progress'`.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// `'ready_for_testing'` → `'Ready For Testing'`.
  String get titleCasedFromSnake => split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => word.capitalized)
      .join(' ');

  /// Truncates with an ellipsis, respecting word boundaries where possible.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    final cut = substring(0, maxLength);
    final lastSpace = cut.lastIndexOf(' ');
    return '${lastSpace > maxLength * 0.6 ? cut.substring(0, lastSpace) : cut}…';
  }

  bool get isBlank => trim().isEmpty;
}

extension NullableStringX on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// Returns `this` when it has content, otherwise [fallback].
  String orIfBlank(String fallback) => isNullOrBlank ? fallback : this!;
}

extension IntX on int {
  /// `1400` → `'1.4k'`, used for comment counters.
  String get compact {
    if (this < 1000) return '$this';
    if (this < 1000000) {
      final value = this / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}k';
    }
    final value = this / 1000000;
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}M';
  }

  /// Byte count → `'243 KB'`.
  String get readableFileSize {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }
}

extension ListX<T> on List<T> {
  /// Null-safe first element.
  T? get firstOrNull => isEmpty ? null : first;

  /// Inserts [separator] between every pair of elements.
  List<T> separatedBy(T separator) {
    if (length <= 1) return this;
    return [
      for (var i = 0; i < length; i++) ...[
        if (i > 0) separator,
        this[i],
      ],
    ];
  }
}

// --------------------------------------------------------------------------
// Ui helpers
// --------------------------------------------------------------------------

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
