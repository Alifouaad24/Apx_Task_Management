import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/attachment_entity.dart';

part 'attachment_model.g.dart';

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
