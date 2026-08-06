/// Task priority levels, ordered from least to most urgent.
enum TaskPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  urgent('urgent', 'Urgent');

  const TaskPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Tolerant parser: unknown values fall back to [medium] rather than
  /// throwing, and common aliases are accepted.
  static TaskPriority fromApi(String? value) {
    if (value == null) return TaskPriority.medium;

    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'low' || 'minor' || 'p4' || '1' => TaskPriority.low,
      'medium' || 'normal' || 'p3' || '2' => TaskPriority.medium,
      'high' || 'major' || 'p2' || '3' => TaskPriority.high,
      'urgent' || 'critical' || 'blocker' || 'p1' || '4' => TaskPriority.urgent,
      _ => TaskPriority.medium,
    };
  }

  /// Higher means more urgent — useful for client-side sorting.
  int get weight => index;

  bool get needsAttention =>
      this == TaskPriority.high || this == TaskPriority.urgent;
}
