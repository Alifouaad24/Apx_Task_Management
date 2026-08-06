import 'package:equatable/equatable.dart';

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
