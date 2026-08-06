import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_status.dart';

part 'task_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TaskModel {
  const TaskModel({
    required this.featureId,
    required this.Service,
    required this.Service_id,
    required this.body,
    required this.status,
    required this.insert_on,
    this.comments = const [],
    this.globalSystem,
    this.globalSystemId,
    this.business,
    this.business_id,
    this.insert_by,
    this.visible = true,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  final int featureId;

  @JsonKey(fromJson: _asString)
  final String body;

  @JsonKey(fromJson: _asString)
  final String status;

  @JsonKey(fromJson: CommentModel.listFrom)
  final List<CommentModel> comments;

  final GlobalSystemModel? globalSystem;
  final int? globalSystemId;

  final BusinessModel? business;
  final int? business_id;

  final ServiceModel? Service;
  final int? Service_id;

  @JsonKey(fromJson: _asDate, toJson: _dateToJson)
  final DateTime insert_on;

  final String? insert_by;

  final bool visible;

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  TaskEntity toEntity() {
    return TaskEntity(
      id: featureId,
      body: body,
      status: TaskStatus.fromApi(status),
      createdAt: insert_on,
      comments: comments
          .map((comment) => comment.toEntity())
          .toList(growable: false),
      globalSystem: globalSystem?.toEntity(),
      Service: Service?.toEntity(),
      business: business?.toEntity(),
      insertBy: insert_by,
      visible: visible,
    );
  }

  static List<TaskModel> listFrom(List<dynamic> json) {
    final result = <TaskModel>[];

    for (final item in json) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(TaskModel.fromJson(item));
        } catch (_) {
          continue;
        }
      }
    }

    return result;
  }

  static String _asString(Object? value) {
    return value?.toString() ?? '';
  }

  static DateTime _asDate(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static String _dateToJson(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

@JsonSerializable(explicitToJson: true)
class CommentModel {
  const CommentModel({
    required this.commentId,
    required this.commentContent,
    required this.addedBy,
    required this.addedOn,
    required this.featureId,
    required this.isRead,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  final int commentId;

  final String commentContent;

  final String addedBy;

  @JsonKey(fromJson: _asDate, toJson: _dateToJson)
  final DateTime addedOn;

  final int featureId;

  final bool isRead;

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);

  CommentEntity toEntity() {
    return CommentEntity(
      id: commentId,
      content: commentContent,
      addedBy: addedBy,
      addedOn: addedOn,
      featureId: featureId,
      isRead: isRead,
    );
  }

  static DateTime _asDate(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static String _dateToJson(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  static List<CommentModel> listFrom(Object? json) {
    if (json is! List) {
      return const [];
    }

    final result = <CommentModel>[];

    for (final item in json) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(CommentModel.fromJson(item));
        } catch (_) {
          continue;
        }
      }
    }

    return result;
  }
}

@JsonSerializable(explicitToJson: true)
class GlobalSystemModel {
  const GlobalSystemModel({
    required this.globalSystemId,
    required this.globalSystemName,
    this.globalSystemType,
    this.globalSystemUrl,
  });

  factory GlobalSystemModel.fromJson(Map<String, dynamic> json) =>
      _$GlobalSystemModelFromJson(json);

  final int globalSystemId;

  final String globalSystemName;

  final String? globalSystemType;

  final String? globalSystemUrl;

  Map<String, dynamic> toJson() => _$GlobalSystemModelToJson(this);

  GlobalSystemEntity toEntity() {
    return GlobalSystemEntity(
      id: globalSystemId,
      name: globalSystemName,
      type: globalSystemType,
      url: globalSystemUrl,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BusinessModel {
  const BusinessModel({
    required this.business_id,
    required this.business_name,
    this.business_LogoUrl,
    this.business_email,
    this.is_active = true,
    this.role,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessModelFromJson(json);

  final int business_id;
  final String business_name;
  final String? business_LogoUrl;
  final String? business_email;
  final bool is_active;
  final String? role;

  Map<String, dynamic> toJson() => _$BusinessModelToJson(this);

  BusinessEntity toEntity() {
    return BusinessEntity(
      id: business_id,
      name: business_name,
      logoUrl: business_LogoUrl,
      email: business_email,
      isActive: is_active,
      role: role,
    );
  }
}

class CommentEntity extends Equatable {
  const CommentEntity({
    required this.id,
    required this.content,
    required this.addedBy,
    required this.addedOn,
    required this.featureId,
    required this.isRead,
  });

  final int id;
  final String content;
  final String addedBy;
  final DateTime addedOn;
  final int featureId;
  final bool isRead;

  @override
  List<Object?> get props => [id, content, addedBy, addedOn, featureId, isRead];
}

class GlobalSystemEntity extends Equatable {
  const GlobalSystemEntity({
    required this.id,
    required this.name,
    this.type,
    this.url,
  });

  final int id;
  final String name;
  final String? type;
  final String? url;

  @override
  List<Object?> get props => [id, name, type, url];
}

class BusinessEntity extends Equatable {
  const BusinessEntity({
    required this.id,
    required this.name,
    this.logoUrl,
    this.email,
    this.isActive = true,
    this.role,
  });

  final int id;
  final String name;
  final String? logoUrl;
  final String? email;
  final bool isActive;
  final String? role;

  @override
  List<Object?> get props => [id, name, logoUrl, email, isActive, role];
}

class ServiceEntity {
  const ServiceEntity({required this.id, required this.name});

  final int id;
  final String name;
}

class ServiceModel extends ServiceEntity {
  const ServiceModel({required super.id, required super.name});

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['service_id'] as int? ?? 0,
      // Service مفهاش حقل "name"، فبنستخدم الـ description كعنوان عرض
      name: json['description'] as String? ?? '',
    );
  }

  ServiceEntity toEntity() {
    return ServiceEntity(id: id, name: name);
  }
}
