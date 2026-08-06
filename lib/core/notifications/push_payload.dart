import 'dart:convert';

import 'notification_channels.dart';

/// Typed view over an FCM message.
///
/// Expected data payload from the backend:
/// ```json
/// {
///   "type": "comment_added",
///   "taskId": "142",
///   "commentId": "1042",
///   "title": "Lina commented on APX-142",
///   "body": "I can reproduce it on a Pixel 7."
/// }
/// ```
/// `title`/`body` fall back to the FCM `notification` block when present.
class PushPayload {
  const PushPayload({
    required this.type,
    this.taskId,
    this.commentId,
    this.title,
    this.body,
    this.raw = const {},
  });

  final PushType type;
  final String? taskId;
  final String? commentId;
  final String? title;
  final String? body;
  final Map<String, dynamic> raw;

  factory PushPayload.fromData(
    Map<String, dynamic> data, {
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    String? read(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
      return null;
    }

    return PushPayload(
      type: PushType.fromValue(read(['type', 'notification_type'])),
      taskId: read(['taskId', 'task_id']),
      commentId: read(['commentId', 'comment_id']),
      title: read(['title']) ?? fallbackTitle,
      body: read(['body', 'message']) ?? fallbackBody,
      raw: data,
    );
  }

  /// Rebuilds a payload from the JSON string carried by a local notification.
  factory PushPayload.fromJsonString(String? source) {
    if (source == null || source.isEmpty) {
      return const PushPayload(type: PushType.general);
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return PushPayload.fromData(decoded);
      }
    } catch (_) {
      // Malformed payload — degrade to a plain notification tap.
    }
    return const PushPayload(type: PushType.general);
  }

  /// Serialised form attached to the local notification so the tap handler can
  /// recover the routing information.
  String toJsonString() => jsonEncode({
        ...raw,
        'type': type.value,
        if (taskId != null) 'taskId': taskId,
        if (commentId != null) 'commentId': commentId,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
      });

  /// `true` when tapping should open a task.
  bool get opensTask => taskId != null && taskId!.isNotEmpty;

  /// `true` when the details screen should jump to the comments section.
  bool get opensComments =>
      opensTask &&
      (type == PushType.commentAdded || commentId != null);

  /// Fallback copy when the server sent data only (a silent/data-only push).
  String get resolvedTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return switch (type) {
      PushType.commentAdded => 'New comment',
      PushType.statusChanged => 'Task status changed',
      PushType.taskAssigned => 'You were assigned a task',
      PushType.taskCreated => 'New task created',
      PushType.general => 'APX Tasks',
    };
  }

  String get resolvedBody => (body != null && body!.isNotEmpty)
      ? body!
      : 'Open the app to see the details.';

  /// Stable notification id so an update for the same task replaces the old
  /// notification instead of stacking a duplicate.
  int get notificationId {
    final seed = '${type.value}:${taskId ?? ''}:${commentId ?? ''}';
    return seed.hashCode & 0x7FFFFFFF;
  }
}
