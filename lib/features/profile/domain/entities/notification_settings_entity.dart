import 'package:equatable/equatable.dart';

/// Per-category push notification preferences.
///
/// Mirrors the [PushType] values so [NotificationService] can mute a category
/// before rendering a local notification.
class NotificationSettingsEntity extends Equatable {
  const NotificationSettingsEntity({
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

  NotificationSettingsEntity copyWith({
    bool? pushEnabled,
    bool? comments,
    bool? statusChanges,
    bool? assignments,
    bool? newTasks,
  }) {
    return NotificationSettingsEntity(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      comments: comments ?? this.comments,
      statusChanges: statusChanges ?? this.statusChanges,
      assignments: assignments ?? this.assignments,
      newTasks: newTasks ?? this.newTasks,
    );
  }

  @override
  List<Object?> get props =>
      [pushEnabled, comments, statusChanges, assignments, newTasks];
}
