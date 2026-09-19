import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_models.g.dart';

// --------------------------------------------------------------------------
// Notification settings entity
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Notification settings model
// --------------------------------------------------------------------------

/// JSON form of the notification preferences.
///
/// The key names here are the contract shared with [NotificationService], which
/// reads the same payload straight out of SharedPreferences to decide whether
/// to render a notification.
@JsonSerializable()
class NotificationSettingsModel {
  const NotificationSettingsModel({
    this.pushEnabled = true,
    this.comments = true,
    this.statusChanges = true,
    this.assignments = true,
    this.newTasks = true,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsModelFromJson(json);

  @JsonKey(defaultValue: true)
  final bool pushEnabled;

  @JsonKey(defaultValue: true)
  final bool comments;

  @JsonKey(defaultValue: true)
  final bool statusChanges;

  @JsonKey(defaultValue: true)
  final bool assignments;

  @JsonKey(defaultValue: true)
  final bool newTasks;

  Map<String, dynamic> toJson() => _$NotificationSettingsModelToJson(this);

  NotificationSettingsEntity toEntity() => NotificationSettingsEntity(
        pushEnabled: pushEnabled,
        comments: comments,
        statusChanges: statusChanges,
        assignments: assignments,
        newTasks: newTasks,
      );

  factory NotificationSettingsModel.fromEntity(
    NotificationSettingsEntity entity,
  ) =>
      NotificationSettingsModel(
        pushEnabled: entity.pushEnabled,
        comments: entity.comments,
        statusChanges: entity.statusChanges,
        assignments: entity.assignments,
        newTasks: entity.newTasks,
      );

  /// Safe parse used when reading from disk, where the payload may predate a
  /// newer field.
  static NotificationSettingsModel? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return NotificationSettingsModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
