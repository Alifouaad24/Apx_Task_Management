/// A business the signed-in user belongs to. The login response lists them
/// all; the board shows the tasks of the one currently selected.
class BusinessModel {
  const BusinessModel({required this.id, required this.name});

  final int id;
  final String name;

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
    id: _int(json['business_id'] ?? json['businessId'] ?? json['id']) ?? 0,
    name: (json['business_name'] ?? json['businessName'] ?? json['name'] ?? '')
        .toString(),
  );

  Map<String, dynamic> toJson() => {'business_id': id, 'business_name': name};

  /// Skips anything that is not a business object or has no id.
  static List<BusinessModel> listFrom(Object? value) => [
    if (value is List)
      for (final item in value)
        if (item is Map<String, dynamic>) BusinessModel.fromJson(item),
  ].where((b) => b.id != 0).toList();

  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  @override
  bool operator ==(Object other) => other is BusinessModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
