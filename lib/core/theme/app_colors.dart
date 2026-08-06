import 'package:flutter/material.dart';

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
