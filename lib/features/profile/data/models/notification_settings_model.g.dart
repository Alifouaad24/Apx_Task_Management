// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSettingsModel _$NotificationSettingsModelFromJson(
  Map<String, dynamic> json,
) => NotificationSettingsModel(
  pushEnabled: json['pushEnabled'] as bool? ?? true,
  comments: json['comments'] as bool? ?? true,
  statusChanges: json['statusChanges'] as bool? ?? true,
  assignments: json['assignments'] as bool? ?? true,
  newTasks: json['newTasks'] as bool? ?? true,
);

Map<String, dynamic> _$NotificationSettingsModelToJson(
  NotificationSettingsModel instance,
) => <String, dynamic>{
  'pushEnabled': instance.pushEnabled,
  'comments': instance.comments,
  'statusChanges': instance.statusChanges,
  'assignments': instance.assignments,
  'newTasks': instance.newTasks,
};
