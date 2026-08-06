import 'package:apx_task_management/features/tasks/data/models/task_model.dart';
import 'package:equatable/equatable.dart';
import 'task_status.dart';

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




