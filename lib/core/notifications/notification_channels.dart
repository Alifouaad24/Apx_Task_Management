import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The kind of event a push notification represents.
///
/// The backend is expected to send `type` in the FCM **data** payload; the
/// value decides which Android channel is used and where a tap navigates.
enum PushType {
  commentAdded('comment_added'),
  statusChanged('status_changed'),
  taskAssigned('task_assigned'),
  taskCreated('task_created'),
  general('general');

  const PushType(this.value);

  final String value;

  static PushType fromValue(String? raw) => PushType.values.firstWhere(
        (type) => type.value == raw,
        orElse: () => PushType.general,
      );
}

/// Android notification channel definitions.
///
/// Channels must be created at startup — Android caches a channel's importance
/// the first time it is registered, so changing importance later requires a new
/// channel id (hence the explicit `_v1` suffixes).
class NotificationChannels {
  const NotificationChannels._();

  static const AndroidNotificationChannel comments = AndroidNotificationChannel(
    'task_comments_v1',
    'Task comments',
    description: 'Someone commented on a task you follow.',
    importance: Importance.high,
    enableVibration: true,
  );

  static const AndroidNotificationChannel statusChanges =
      AndroidNotificationChannel(
    'task_status_v1',
    'Status changes',
    description: 'A task you follow moved to a new status.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel assignments =
      AndroidNotificationChannel(
    'task_assignments_v1',
    'Task assignments',
    description: 'You were assigned to a task.',
    importance: Importance.max,
    enableVibration: true,
  );

  static const AndroidNotificationChannel newTasks = AndroidNotificationChannel(
    'task_created_v1',
    'New tasks',
    description: 'A new task was created in your workspace.',
    importance: Importance.defaultImportance,
  );

  static const AndroidNotificationChannel general = AndroidNotificationChannel(
    'general_v1',
    'General',
    description: 'Everything else from APX Tasks.',
    importance: Importance.defaultImportance,
  );

  /// Every channel that must exist on the device.
  static const List<AndroidNotificationChannel> all = [
    comments,
    statusChanges,
    assignments,
    newTasks,
    general,
  ];

  /// Maps a push type onto its channel.
  static AndroidNotificationChannel forType(PushType type) => switch (type) {
        PushType.commentAdded => comments,
        PushType.statusChanged => statusChanges,
        PushType.taskAssigned => assignments,
        PushType.taskCreated => newTasks,
        PushType.general => general,
      };
}
