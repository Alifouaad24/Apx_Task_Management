import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/theme.dart';

// --------------------------------------------------------------------------
// App button
// --------------------------------------------------------------------------

/// Visual weight of an [AppButton].
enum AppButtonVariant { primary, secondary, outline, text, danger }

enum AppButtonSize { small, medium, large }

/// The app's single button component.
///
/// Handles the loading state internally (swapping the label for a spinner while
/// keeping the button's width stable) and blocks taps while busy, which removes
/// a whole class of double-submit bugs from the call sites.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  });

  /// Convenience constructors for the common variants.
  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.expanded = false,
  }) : variant = AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;

  /// When `false` the button hugs its content instead of filling the row.
  final bool expanded;

  double get _height => switch (size) {
        AppButtonSize.small => 38.h,
        AppButtonSize.medium => 46.h,
        AppButtonSize.large => 52.h,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDisabled = onPressed == null || isLoading;
    final effectiveOnPressed = isDisabled ? null : onPressed;

    final minimumSize = Size(expanded ? double.infinity : 0, _height);
    final padding = EdgeInsets.symmetric(
      horizontal: size == AppButtonSize.small ? 14.w : 20.w,
    );

    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      size: size,
    );

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            minimumSize: minimumSize,
            padding: padding,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            minimumSize: minimumSize,
            padding: padding,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            foregroundColor: scheme.primary,
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: minimumSize,
            padding: padding,
            foregroundColor: scheme.onSurface,
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(expanded ? double.infinity : 0, _height),
            padding: padding,
          ),
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            minimumSize: minimumSize,
            padding: padding,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: child,
        ),
    };
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.size,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      final indicatorSize = size == AppButtonSize.small ? 16.w : 20.w;
      return SizedBox(
        height: indicatorSize,
        width: indicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: DefaultTextStyle.of(context).style.color ??
              Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }

    if (icon == null) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: size == AppButtonSize.small ? 16.sp : 18.sp),
        SizedBox(width: 8.w),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

// --------------------------------------------------------------------------
// App text field
// --------------------------------------------------------------------------

/// Standard text input for the whole app.
///
/// Owns the obscure-text toggle for passwords so no screen has to keep that
/// piece of state itself.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;

  /// Server-side error surfaced under the field (client-side errors come from
  /// [validator]).
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          maxLines: _obscured ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: AppTextStyles.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            errorText: widget.errorText,
            counterText: '',
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 20.sp),
            suffixIcon: _buildSuffix(),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 20.sp,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
        tooltip: _obscured ? 'Show password' : 'Hide password',
      );
    }
    return widget.suffix;
  }
}

// --------------------------------------------------------------------------
// App loader
// --------------------------------------------------------------------------

/// Centred progress indicator with an optional caption.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message, this.size});

  final String? message;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimension = size ?? 32.w;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: dimension,
            width: dimension,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 14.h),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Trailing spinner shown while the next page of a paginated list loads.
class PaginationLoader extends StatelessWidget {
  const PaginationLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: SizedBox(
          height: 22.w,
          width: 22.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Blocking overlay used during logout and other full-screen operations.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: AppLoader(message: message),
    );
  }
}

/// Lightweight skeleton block with a subtle pulse, used by list placeholders.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius,
  });

  final double height;
  final double? width;
  final double? radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius ?? 8.r),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// App error widget
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Empty state widget
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Status chip
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// User avatar
// --------------------------------------------------------------------------

/// Circular avatar with a graceful fallback chain:
/// remote image → coloured initials → generic person icon.
///
/// The initials background is derived from the name, so the same person keeps
/// the same colour everywhere in the app.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size,
    this.showBorder = false,
  });

  final String name;
  final String? imageUrl;
  final double? size;
  final bool showBorder;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimension = size ?? 36.w;
    final background = AppColors.avatarColor(name, isDark: isDark);

    return Container(
      height: dimension,
      width: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: showBorder
            ? Border.all(color: Theme.of(context).colorScheme.surface, width: 2)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: (imageUrl != null && imageUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _Initials(
                initials: _initials,
                dimension: dimension,
              ),
              errorWidget: (_, __, ___) => _Initials(
                initials: _initials,
                dimension: dimension,
              ),
            )
          : _Initials(initials: _initials, dimension: dimension),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.dimension});

  final String initials;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    if (initials.isEmpty) {
      return Icon(
        Icons.person_rounded,
        size: dimension * 0.55,
        color: Colors.white,
      );
    }
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: Colors.white,
          fontSize: (dimension * 0.38).sp / 1, // scales with the avatar
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Overlapping avatar stack, used on the task card when several people are
/// involved (assignee + reporter).
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.people,
    this.size,
    this.maxVisible = 3,
  });

  /// `(name, imageUrl)` pairs.
  final List<({String name, String? imageUrl})> people;
  final double? size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 26.w;
    final visible = people.take(maxVisible).toList();
    final overflow = people.length - visible.length;

    return SizedBox(
      height: dimension,
      width: dimension + (visible.length - 1).clamp(0, maxVisible) * dimension * 0.65 +
          (overflow > 0 ? dimension * 0.65 : 0),
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * dimension * 0.65,
              child: UserAvatar(
                name: visible[i].name,
                imageUrl: visible[i].imageUrl,
                size: dimension,
                showBorder: true,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * dimension * 0.65,
              child: Container(
                height: dimension,
                width: dimension,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
