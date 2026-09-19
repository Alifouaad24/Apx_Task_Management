import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_models.g.dart';

// --------------------------------------------------------------------------
// Task status
// --------------------------------------------------------------------------

/// The six task statuses, and the rules for moving between them.
///
/// The transition table lives here — in the domain — so the UI cannot invent an
/// illegal move and the server is not the only thing enforcing the workflow.
enum TaskStatus {
  newTask('New', 'New'),
  inProgress('On progress', 'On progress'),
  readyfortesting('Waiting response', 'Waiting response'),
  testing('Testing', 'Testing'),
  completed('Completed', 'Completed'),
  closed('Closed', 'Closed');

  const TaskStatus(this.apiValue, this.label);

  /// Value exchanged with the backend.
  final String apiValue;

  /// Human readable label shown in tabs, chips and the status selector.
  final String label;

  /// Tab order on the dashboard.
  static const List<TaskStatus> tabOrder = [
    TaskStatus.newTask,
    TaskStatus.inProgress,
    TaskStatus.readyfortesting,
    TaskStatus.testing,
    TaskStatus.completed,
    TaskStatus.closed,
  ];

  /// Parses an API value, defaulting to [newTask] so one malformed record can
  /// never crash a list.
  static TaskStatus fromApi(String? value) {
    if (value == null) return TaskStatus.newTask;
    final normalized = value.trim().toLowerCase();
    return TaskStatus.values.firstWhere(
      (status) => status.apiValue.toLowerCase() == normalized,
      orElse: () => TaskStatus.newTask,
    );
  }

  /// The happy-path pipeline: New → In Progress → Ready For Testing →
  /// Testing → Done.
  static const List<TaskStatus> _pipeline = [
    TaskStatus.newTask,
    TaskStatus.inProgress,
    TaskStatus.readyfortesting,
    TaskStatus.testing,
    TaskStatus.completed,
    TaskStatus.closed,
  ];

  /// The next step in the pipeline, or `null` at the end of it.
  TaskStatus? get nextInPipeline {
    final index = _pipeline.indexOf(this);
    if (index == -1 || index == _pipeline.length - 1) return null;
    return _pipeline[index + 1];
  }

  /// Statuses this task may legally move to.
  ///
  /// Per the workflow spec: one step forward along the pipeline, or straight to
  /// [rejected] from anywhere. [rejected] is terminal — relax this list if the
  /// product later needs a "reopen" action.
List<TaskStatus> get allowedTransitions {
  final index = _pipeline.indexOf(this);
  if (index == -1 || index == _pipeline.length - 1) return const [];
  return _pipeline.sublist(index + 1);
}

  bool canTransitionTo(TaskStatus target) =>
      allowedTransitions.contains(target);

  /// `true` when no further movement is possible.
  bool get isTerminal => allowedTransitions.isEmpty;

  bool get isDone => this == TaskStatus.completed;

  bool get isRejected => this == TaskStatus.closed;

  /// How far along the pipeline this status is, as 0.0–1.0. Rejected reports 1
  /// because the task has left the pipeline entirely.
  double get progress {
    if (this == TaskStatus.closed) return 1;
    final index = _pipeline.indexOf(this);
    if (index <= 0) return 0;
    return index / (_pipeline.length - 1);
  }
}

// --------------------------------------------------------------------------
// Task priority
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Task entity
// --------------------------------------------------------------------------

class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.body,
    required this.status,
    required this.createdAt,
    this.comments = const [],
    this.globalSystem,
    this.business,
    this.insertBy,
    this.visible = true,
    this.Service
  });

  final int id;
  final String body;
  final TaskStatus status;
  final DateTime createdAt;
  final List<CommentEntity> comments;
  final GlobalSystemEntity? globalSystem;
  final BusinessEntity? business;
  final ServiceEntity? Service;
  final String? insertBy;
  final bool visible;

  String get displayKey => '#$id';
  int get commentsCount => comments.length;
  int get unreadCommentsCount => comments.where((c) => !c.isRead).length;
  bool get hasUnreadComments => unreadCommentsCount > 0;

  TaskEntity copyWith({
    String? body,
    TaskStatus? status,
    List<CommentEntity>? comments,
    bool? visible,
  }) {
    return TaskEntity(
      id: id,
      body: body ?? this.body,
      status: status ?? this.status,
      createdAt: createdAt,
      comments: comments ?? this.comments,
      Service: Service ?? this.Service,
      globalSystem: globalSystem,
      business: business,
      insertBy: insertBy,
      visible: visible ?? this.visible,
    );
  }

  @override
  List<Object?> get props => [
    id,
    body,
    status,
    createdAt,
    comments,
    globalSystem,
    business,
    insertBy,
    visible,
  ];
}

// --------------------------------------------------------------------------
// Attachment entity
// --------------------------------------------------------------------------

/// A file attached to a task.
class AttachmentEntity extends Equatable {
  const AttachmentEntity({
    required this.id,
    required this.fileName,
    required this.url,
    this.mimeType,
    this.sizeInBytes,
    this.uploadedAt,
  });

  final String id;
  final String fileName;
  final String url;
  final String? mimeType;
  final int? sizeInBytes;
  final DateTime? uploadedAt;

  /// Lower-case extension without the dot, e.g. `pdf`.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// Images get an inline thumbnail; everything else gets a file icon.
  bool get isImage {
    if (mimeType != null) return mimeType!.startsWith('image/');
    return const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic']
        .contains(extension);
  }

  bool get isPdf =>
      mimeType == 'application/pdf' || extension == 'pdf';

  @override
  List<Object?> get props =>
      [id, fileName, url, mimeType, sizeInBytes, uploadedAt];
}

// --------------------------------------------------------------------------
// Task model
// --------------------------------------------------------------------------

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

  /// The API spells these two in snake_case, unlike the fields around them.
  @JsonKey(name: 'service')
  final ServiceModel? Service;

  @JsonKey(name: 'service_id')
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

  /// Mirrors [ServiceModel.fromJson]. Written by hand because the model is not
  /// `@JsonSerializable` — its fields come from [ServiceEntity] and the wire
  /// names differ. `TaskModel`'s generated `toJson` needs this to exist.
  Map<String, dynamic> toJson() => {'service_id': id, 'description': name};

  ServiceEntity toEntity() {
    return ServiceEntity(id: id, name: name);
  }
}

// --------------------------------------------------------------------------
// Attachment model
// --------------------------------------------------------------------------

/// JSON representation of a task attachment.
@JsonSerializable()
class AttachmentModel {
  const AttachmentModel({
    required this.id,
    required this.fileName,
    required this.url,
    this.mimeType,
    this.size,
    this.uploadedAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$AttachmentModelFromJson(json);

  @JsonKey(fromJson: _asString)
  final String id;

  /// Accepts `fileName`, `name` or `filename`.
  @JsonKey(readValue: _readFileName, fromJson: _asString)
  final String fileName;

  @JsonKey(readValue: _readUrl, fromJson: _asString)
  final String url;

  @JsonKey(readValue: _readMimeType)
  final String? mimeType;

  /// Size in bytes; some backends send it as a string.
  @JsonKey(readValue: _readSize, fromJson: _asNullableInt)
  final int? size;

  @JsonKey(fromJson: _asNullableDate, toJson: _dateToJson)
  final DateTime? uploadedAt;

  Map<String, dynamic> toJson() => _$AttachmentModelToJson(this);

  AttachmentEntity toEntity() => AttachmentEntity(
        id: id,
        fileName: fileName,
        url: url,
        mimeType: mimeType,
        sizeInBytes: size,
        uploadedAt: uploadedAt,
      );

  /// Parses a list, silently dropping malformed entries — a single bad
  /// attachment must not take down the whole task detail screen.
  static List<AttachmentModel> listFrom(Object? json) {
    if (json is! List) return const [];
    final result = <AttachmentModel>[];
    for (final item in json) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(AttachmentModel.fromJson(item));
        } catch (_) {
          continue;
        }
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Converters
  // ---------------------------------------------------------------------------
  static String _asString(Object? value) => value?.toString() ?? '';

  static int? _asNullableInt(Object? value) => switch (value) {
        final num v => v.toInt(),
        final String v => int.tryParse(v),
        _ => null,
      };

  static DateTime? _asNullableDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _dateToJson(DateTime? value) => value?.toUtc().toIso8601String();

  static Object? _readFileName(Map<dynamic, dynamic> json, String key) =>
      json['fileName'] ?? json['name'] ?? json['filename'] ?? 'file';

  static Object? _readUrl(Map<dynamic, dynamic> json, String key) =>
      json['url'] ?? json['downloadUrl'] ?? json['path'] ?? '';

  static Object? _readMimeType(Map<dynamic, dynamic> json, String key) =>
      json['mimeType'] ?? json['mime_type'] ?? json['contentType'];

  static Object? _readSize(Map<dynamic, dynamic> json, String key) =>
      json['size'] ?? json['sizeInBytes'] ?? json['bytes'];
}
