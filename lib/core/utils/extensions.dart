import 'package:flutter/material.dart';

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
