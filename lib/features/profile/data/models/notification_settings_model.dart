import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/notification_settings_entity.dart';

part 'notification_settings_model.g.dart';

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
