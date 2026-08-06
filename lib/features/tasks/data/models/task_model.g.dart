// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
  featureId: (json['featureId'] as num).toInt(),
  body: TaskModel._asString(json['body']),
  status: TaskModel._asString(json['status']),
  insert_on: TaskModel._asDate(json['insert_on']),
  comments: json['comments'] == null
      ? const []
      : CommentModel.listFrom(json['comments']),
  globalSystem: json['globalSystem'] == null
      ? null
      : GlobalSystemModel.fromJson(
          json['globalSystem'] as Map<String, dynamic>,
        ),
  globalSystemId: (json['globalSystemId'] as num?)?.toInt(),
  business: json['business'] == null
      ? null
      : BusinessModel.fromJson(json['business'] as Map<String, dynamic>),
  business_id: (json['business_id'] as num?)?.toInt(),
  insert_by: json['insert_by'] as String?,
  visible: json['visible'] as bool? ?? true,
  Service: json['service'] == null
      ? null
      : ServiceModel.fromJson(
          json['service'] as Map<String, dynamic>,
        ),
  Service_id: (json['service_id']as num?)?.toInt(),
);

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
  'featureId': instance.featureId,
  'body': instance.body,
  'status': instance.status,
  'comments': instance.comments.map((e) => e.toJson()).toList(),
  'globalSystem': instance.globalSystem?.toJson(),
  'globalSystemId': instance.globalSystemId,
  'business': instance.business?.toJson(),
  'business_id': instance.business_id,
  'insert_on': TaskModel._dateToJson(instance.insert_on),
  'insert_by': instance.insert_by,
  'visible': instance.visible,
};

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) => CommentModel(
  commentId: (json['commentId'] as num).toInt(),
  commentContent: json['commentContent'] as String,
  addedBy: json['addedBy'] as String,
  addedOn: CommentModel._asDate(json['addedOn']),
  featureId: (json['featureId'] as num).toInt(),
  isRead: json['isRead'] as bool,
);

Map<String, dynamic> _$CommentModelToJson(CommentModel instance) =>
    <String, dynamic>{
      'commentId': instance.commentId,
      'commentContent': instance.commentContent,
      'addedBy': instance.addedBy,
      'addedOn': CommentModel._dateToJson(instance.addedOn),
      'featureId': instance.featureId,
      'isRead': instance.isRead,
    };

GlobalSystemModel _$GlobalSystemModelFromJson(Map<String, dynamic> json) =>
    GlobalSystemModel(
      globalSystemId: (json['globalSystemId'] as num).toInt(),
      globalSystemName: json['globalSystemName'] as String,
      globalSystemType: json['globalSystemType'] as String?,
      globalSystemUrl: json['globalSystemUrl'] as String?,
    );

Map<String, dynamic> _$GlobalSystemModelToJson(GlobalSystemModel instance) =>
    <String, dynamic>{
      'globalSystemId': instance.globalSystemId,
      'globalSystemName': instance.globalSystemName,
      'globalSystemType': instance.globalSystemType,
      'globalSystemUrl': instance.globalSystemUrl,
    };

BusinessModel _$BusinessModelFromJson(Map<String, dynamic> json) =>
    BusinessModel(
      business_id: (json['business_id'] as num).toInt(),
      business_name: json['business_name'] as String,
      business_LogoUrl: json['business_LogoUrl'] as String?,
      business_email: json['business_email'] as String?,
      is_active: json['is_active'] as bool? ?? true,
      role: json['role'] as String?,
    );

Map<String, dynamic> _$BusinessModelToJson(BusinessModel instance) =>
    <String, dynamic>{
      'business_id': instance.business_id,
      'business_name': instance.business_name,
      'business_LogoUrl': instance.business_LogoUrl,
      'business_email': instance.business_email,
      'is_active': instance.is_active,
      'role': instance.role,
    };
