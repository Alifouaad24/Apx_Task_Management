/// Per-category push notification preferences.
///
/// The JSON keys are also read by `NotificationService` to decide whether to
/// show a notification, so keep them in sync.
class NotificationSettingsModel {
  const NotificationSettingsModel({
    this.pushEnabled = true,
    this.comments = true,
    this.statusChanges = true,
    this.assignments = true,
    this.newTasks = true,
  });

  /// Master switch — when `false` every category is muted.
  final bool pushEnabled;

  final bool comments;
  final bool statusChanges;
  final bool assignments;
  final bool newTasks;

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) =>
      NotificationSettingsModel(
        pushEnabled: json['pushEnabled'] as bool? ?? true,
        comments: json['comments'] as bool? ?? true,
        statusChanges: json['statusChanges'] as bool? ?? true,
        assignments: json['assignments'] as bool? ?? true,
        newTasks: json['newTasks'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'pushEnabled': pushEnabled,
        'comments': comments,
        'statusChanges': statusChanges,
        'assignments': assignments,
        'newTasks': newTasks,
      };

  NotificationSettingsModel copyWith({
    bool? pushEnabled,
    bool? comments,
    bool? statusChanges,
    bool? assignments,
    bool? newTasks,
  }) {
    return NotificationSettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      comments: comments ?? this.comments,
      statusChanges: statusChanges ?? this.statusChanges,
      assignments: assignments ?? this.assignments,
      newTasks: newTasks ?? this.newTasks,
    );
  }
}
