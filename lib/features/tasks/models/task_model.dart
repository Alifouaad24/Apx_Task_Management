// --------------------------------------------------------------------------
// Order status
// --------------------------------------------------------------------------

/// A task status, as served by `UniversalOrder/GetAllOrderStatusByService`.
///
/// Statuses are data, not code: the service decides which ones exist and in
/// what order, and the dashboard builds one tab per status.
class OrderStatusModel {
  const OrderStatusModel({
    required this.id,
    required this.nameEn,
    this.nameAr = '',
    this.serviceId,
  });

  final int id;
  final String nameEn;
  final String nameAr;
  final int? serviceId;

  String get label => nameEn;

  String get _normalized => nameEn.trim().toLowerCase();

  bool get isNew => _normalized == 'new';
  bool get isCompleted => _normalized == 'completed';
  bool get isClosed => _normalized == 'closed';

  /// Key into `AppColors.statusColor`, so known statuses keep their colours.
  /// Statuses the app has never seen fall back to the neutral colour.
  String get colorKey => switch (_normalized) {
    'new' => 'new',
    'on progress' || 'in progress' => 'in_progress',
    'waiting response' => 'ready_for_testing',
    'testing' => 'testing',
    'completed' => 'done',
    'closed' => 'rejected',
    _ => _normalized,
  };

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) =>
      OrderStatusModel(
        id: (json['orderStatusId'] as num).toInt(),
        nameEn: json['statusEn']?.toString() ?? '',
        nameAr: json['statusAr']?.toString() ?? '',
        serviceId: (json['service_id'] as num?)?.toInt(),
      );

  static List<OrderStatusModel> listFrom(Object? json) =>
      _parseList(json, OrderStatusModel.fromJson);

  @override
  bool operator ==(Object other) => other is OrderStatusModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// --------------------------------------------------------------------------
// Task model
// --------------------------------------------------------------------------

/// A task (the API calls it a "GlobalOrder").
///
/// Parsing is deliberately lenient: only the id is required, so a field the
/// backend renames or drops degrades one line of UI instead of the whole list.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.notes,
    this.status,
    this.createdAt,
    this.scheduleDate,
    this.scheduleTime,
    this.comments = const [],
    this.businessId,
    this.serviceId,
    this.customerName,
    this.assignerName,
    this.assigneeName,
  });

  final int id;
  final String notes;
  final OrderStatusModel? status;
  final DateTime? createdAt;
  final DateTime? scheduleDate;
  final String? scheduleTime;
  final List<CommentModel> comments;
  final int? businessId;
  final int? serviceId;
  final String? customerName;
  final String? assignerName;
  final String? assigneeName;

  String get displayKey => '#$id';
  int get commentsCount => comments.length;
  int get unreadCommentsCount => comments.where((c) => !c.isRead).length;
  bool get hasUnreadComments => unreadCommentsCount > 0;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final statusJson = json['orderStatus'];
    return TaskModel(
      id: (json['globalOrderId'] as num).toInt(),
      notes: json['notes']?.toString() ?? '',
      status: statusJson is Map<String, dynamic>
          ? OrderStatusModel.fromJson(statusJson)
          : null,
      createdAt: _parseDate(
        _first(json, const ['insert_on', 'insertOn', 'createdOn', 'orderDate']),
      ),
      scheduleDate: _parseDate(json['schedule_dt']),
      scheduleTime: _nonEmpty(json['schedule_time']),
      comments: _parseList(json['comments'], CommentModel.fromJson),
      businessId: (json['business_id'] as num?)?.toInt(),
      serviceId: (json['service_id'] as num?)?.toInt(),
      customerName: _nonEmpty(
        _first(json, const ['customerName', 'globalCustomerName']),
      ),
      assignerName: _nonEmpty(_first(json, const ['assignerName', 'assigner'])),
      assigneeName: _nonEmpty(_first(json, const ['assigneeName', 'assignee'])),
    );
  }

  /// Parses a list, skipping malformed entries instead of failing the lot.
  static List<TaskModel> listFrom(Object? json) =>
      _parseList(json, TaskModel.fromJson);

  TaskModel copyWith({
    String? notes,
    OrderStatusModel? status,
    List<CommentModel>? comments,
  }) {
    return TaskModel(
      id: id,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      comments: comments ?? this.comments,
      businessId: businessId,
      serviceId: serviceId,
      customerName: customerName,
      assignerName: assignerName,
      assigneeName: assigneeName,
    );
  }
}

// --------------------------------------------------------------------------
// Comment model
// --------------------------------------------------------------------------

class CommentModel {
  const CommentModel({
    required this.id,
    required this.content,
    required this.addedBy,
    required this.addedOn,
    required this.isRead,
  });

  final int id;
  final String content;
  final String addedBy;
  final DateTime addedOn;
  final bool isRead;

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: (json['commentId'] as num?)?.toInt() ?? 0,
    content: json['commentContent']?.toString() ?? '',
    addedBy: json['addedBy']?.toString() ?? '',
    addedOn: _parseDate(json['addedOn']) ?? DateTime.now(),
    isRead: json['isRead'] as bool? ?? true,
  );
}

// --------------------------------------------------------------------------
// Lookups (assign types and the lists they point at)
// --------------------------------------------------------------------------

/// One entry of `Orders/GetAllAssignTypes`: Business, Customer, System, User.
class AssignTypeModel {
  const AssignTypeModel({required this.id, required this.type});

  final int id;
  final String type;

  factory AssignTypeModel.fromJson(Map<String, dynamic> json) =>
      AssignTypeModel(
        id: (json['assign_typeId'] as num).toInt(),
        type: json['type']?.toString() ?? '',
      );

  static List<AssignTypeModel> listFrom(Object? json) =>
      _parseList(json, AssignTypeModel.fromJson);
}

/// A pickable `{id, name}` pair. Businesses, customers, systems and users all
/// come back in different shapes; the datasource flattens them into this.
///
/// [id] stays a string because user ids are GUIDs.
class LookupOption {
  const LookupOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) => other is LookupOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// --------------------------------------------------------------------------
// Task form data
// --------------------------------------------------------------------------

/// Body of `Orders/AddGlobalOrder`.
class NewTaskData {
  const NewTaskData({
    required this.notes,
    required this.businessId,
    required this.serviceId,
    this.statusId,
    this.customerId,
    this.scheduleDate,
    this.scheduleTime,
    this.assignerTypeId,
    this.assignerId,
    this.assigneeTypeId,
    this.assigneeId,
  });

  final String notes;
  final int businessId;
  final int serviceId;
  final int? statusId;
  final String? customerId;

  /// `yyyy-MM-dd`.
  final String? scheduleDate;

  /// `HH:mm`.
  final String? scheduleTime;
  final int? assignerTypeId;
  final String? assignerId;
  final int? assigneeTypeId;
  final String? assigneeId;

  Map<String, dynamic> toJson() => {
    'Business_id': businessId,
    'GlobalCustomerId': customerId == null ? null : int.tryParse(customerId!),
    'Schedule_dt': scheduleDate,
    'Schedule_time': scheduleTime,
    'OrderStatusId': statusId,
    'Notes': notes,
    'Service_id': serviceId,
    'AssignerTypeId': assignerTypeId,
    'AssignerId': assignerId,
    'AssigneeTypeId': assigneeTypeId,
    'AssigneeId': assigneeId,
  };
}

// --------------------------------------------------------------------------
// Parsing helpers
// --------------------------------------------------------------------------

DateTime? _parseDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

Object? _first(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}

String? _nonEmpty(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

List<T> _parseList<T>(Object? json, T Function(Map<String, dynamic>) fromJson) {
  if (json is! List) return const [];
  final result = <T>[];
  for (final item in json) {
    if (item is! Map<String, dynamic>) continue;
    try {
      result.add(fromJson(item));
    } catch (_) {
      // One malformed record must not break the whole list.
    }
  }
  return result;
}
