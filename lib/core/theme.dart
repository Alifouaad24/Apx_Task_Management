import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// --------------------------------------------------------------------------
// App colors
// --------------------------------------------------------------------------

/// The app's colour palette.
///
/// Brand + neutral colours drive the Material 3 [ColorScheme]; the semantic
/// status/priority colours are exposed as light/dark pairs and resolved through
/// [AppColors.statusColor] / [AppColors.priorityColor] so widgets never branch
/// on brightness themselves.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF4F46E5); // indigo 600
  static const Color primaryDark = Color(0xFF818CF8); // indigo 400
  static const Color secondary = Color(0xFF0EA5E9); // sky 500
  static const Color tertiary = Color(0xFFEC4899); // pink 500

  // ---------------------------------------------------------------------------
  // Neutrals — light
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF0F6);
  static const Color lightOutline = Color(0xFFE2E5EE);
  static const Color lightTextPrimary = Color(0xFF101828);
  static const Color lightTextSecondary = Color(0xFF667085);

  // ---------------------------------------------------------------------------
  // Neutrals — dark
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0B0F1A);
  static const Color darkSurface = Color(0xFF141A28);
  static const Color darkSurfaceVariant = Color(0xFF1D2536);
  static const Color darkOutline = Color(0xFF2A3346);
  static const Color darkTextPrimary = Color(0xFFF2F4F7);
  static const Color darkTextSecondary = Color(0xFF98A2B3);

  // ---------------------------------------------------------------------------
  // Feedback
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF12B76A);
  static const Color warning = Color(0xFFF79009);
  static const Color danger = Color(0xFFF04438);
  static const Color info = Color(0xFF2E90FA);

  // ---------------------------------------------------------------------------
  // Task status — keyed by the API value so the mapping stays declarative
  // ---------------------------------------------------------------------------
  static const Map<String, Color> _statusLight = {
    'new': Color(0xFF667085),
    'in_progress': Color(0xFF2E90FA),
    'ready_for_testing': Color(0xFF7A5AF8),
    'testing': Color(0xFFF79009),
    'done': Color(0xFF12B76A),
    'rejected': Color(0xFFF04438),
  };

  static const Map<String, Color> _statusDark = {
    'new': Color(0xFF98A2B3),
    'in_progress': Color(0xFF53B1FD),
    'ready_for_testing': Color(0xFFA48AFB),
    'testing': Color(0xFFFDB022),
    'done': Color(0xFF32D583),
    'rejected': Color(0xFFFDA29B),
  };

  /// Resolves the accent colour for a task status API value.
  static Color statusColor(String apiValue, {required bool isDark}) {
    final table = isDark ? _statusDark : _statusLight;
    return table[apiValue] ?? (isDark ? darkTextSecondary : lightTextSecondary);
  }

  // ---------------------------------------------------------------------------
  // Priority
  // ---------------------------------------------------------------------------
  static const Map<String, Color> _priorityLight = {
    'low': Color(0xFF12B76A),
    'medium': Color(0xFF2E90FA),
    'high': Color(0xFFF79009),
    'urgent': Color(0xFFF04438),
  };

  static const Map<String, Color> _priorityDark = {
    'low': Color(0xFF32D583),
    'medium': Color(0xFF53B1FD),
    'high': Color(0xFFFDB022),
    'urgent': Color(0xFFFDA29B),
  };

  static Color priorityColor(String apiValue, {required bool isDark}) {
    final table = isDark ? _priorityDark : _priorityLight;
    return table[apiValue] ?? (isDark ? darkTextSecondary : lightTextSecondary);
  }

  /// Deterministic avatar background derived from a user's name, so the same
  /// person always gets the same colour without the backend sending one.
  static Color avatarColor(String seed, {required bool isDark}) {
    const palette = <Color>[
      Color(0xFF4F46E5),
      Color(0xFF0EA5E9),
      Color(0xFF12B76A),
      Color(0xFFF79009),
      Color(0xFFEC4899),
      Color(0xFF7A5AF8),
      Color(0xFF06AED4),
    ];
    if (seed.isEmpty) return palette.first;
    final index = seed.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
    final base = palette[index];
    return isDark ? Color.lerp(base, Colors.white, 0.2)! : base;
  }

  /// Brand gradient used on the splash screen and primary CTAs.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7A5AF8), Color(0xFF0EA5E9)],
  );
}

// --------------------------------------------------------------------------
// App text styles
// --------------------------------------------------------------------------

/// Typography scale.
///
/// Sizes go through ScreenUtil's `.sp` so text tracks the design canvas defined
/// in [AppConfig]. These getters must only be read after `ScreenUtilInit` has
/// run — which is guaranteed since [AppTheme] is built inside its builder.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get displayLarge => TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
      );

  static TextStyle get titleLarge => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleSmall => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get labelLarge => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      );

  /// Assembles the Material 3 [TextTheme] used by [AppTheme].
  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: displayLarge.copyWith(color: primary),
        headlineMedium: headlineMedium.copyWith(color: primary),
        headlineSmall: headlineSmall.copyWith(color: primary),
        titleLarge: titleLarge.copyWith(color: primary),
        titleMedium: titleMedium.copyWith(color: primary),
        titleSmall: titleSmall.copyWith(color: primary),
        bodyLarge: bodyLarge.copyWith(color: primary),
        bodyMedium: bodyMedium.copyWith(color: secondary),
        bodySmall: bodySmall.copyWith(color: secondary),
        labelLarge: labelLarge.copyWith(color: primary),
        labelMedium: labelMedium.copyWith(color: secondary),
        labelSmall: labelSmall.copyWith(color: secondary),
      );
}

// --------------------------------------------------------------------------
// App theme
// --------------------------------------------------------------------------

/// Material 3 light & dark themes.
///
/// Both themes share one builder so a component tweak can never drift between
/// brightnesses.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.primaryDark : AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      surfaceContainerLowest:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      surfaceContainerHighest:
          isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      outlineVariant: isDark ? AppColors.darkOutline : AppColors.lightOutline,
      error: AppColors.danger,
    );

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final textTheme = AppTextStyles.textTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // ---------------------------------------------------------------------
      // App bar
      // ---------------------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      // ---------------------------------------------------------------------
      // Cards & surfaces
      // ---------------------------------------------------------------------
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: outline),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),

      // ---------------------------------------------------------------------
      // Inputs
      // ---------------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        floatingLabelStyle:
            AppTextStyles.labelMedium.copyWith(color: scheme.primary),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: scheme.error),
        border: _inputBorder(outline),
        enabledBorder: _inputBorder(outline),
        focusedBorder: _inputBorder(scheme.primary, width: 1.6),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.6),
        disabledBorder: _inputBorder(outline.withValues(alpha: 0.5)),
      ),

      // ---------------------------------------------------------------------
      // Buttons
      // ---------------------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(double.infinity, 52.h),
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, 52.h),
          textStyle: AppTextStyles.labelLarge,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),

      // ---------------------------------------------------------------------
      // Tabs
      // ---------------------------------------------------------------------
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onPrimary,
        unselectedLabelColor: textSecondary,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        indicator: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(999.r),
        ),
      ),

      // ---------------------------------------------------------------------
      // Chips, sheets, dialogs
      // ---------------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide.none,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: textPrimary),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999.r),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFF1D2939),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
        titleTextStyle: AppTextStyles.titleSmall.copyWith(color: textPrimary),
        subtitleTextStyle:
            AppTextStyles.bodySmall.copyWith(color: textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (isDark ? AppColors.darkTextSecondary : Colors.white),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: color, width: width),
      );
}
