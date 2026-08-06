// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentModel _$AttachmentModelFromJson(Map<String, dynamic> json) =>
    AttachmentModel(
      id: AttachmentModel._asString(json['id']),
      fileName: AttachmentModel._asString(
        AttachmentModel._readFileName(json, 'fileName'),
      ),
      url: AttachmentModel._asString(AttachmentModel._readUrl(json, 'url')),
      mimeType: AttachmentModel._readMimeType(json, 'mimeType') as String?,
      size: AttachmentModel._asNullableInt(
        AttachmentModel._readSize(json, 'size'),
      ),
      uploadedAt: AttachmentModel._asNullableDate(json['uploadedAt']),
    );

Map<String, dynamic> _$AttachmentModelToJson(AttachmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'url': instance.url,
      'mimeType': instance.mimeType,
      'size': instance.size,
      'uploadedAt': AttachmentModel._dateToJson(instance.uploadedAt),
    };
