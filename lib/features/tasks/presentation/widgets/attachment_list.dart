import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../tasks/domain/entities/attachment_entity.dart';

/// Horizontal strip of a task's attachments.
///
/// Image attachments render an actual thumbnail through
/// `cached_network_image`; everything else gets a typed file icon.
class AttachmentList extends StatelessWidget {
  const AttachmentList({
    super.key,
    required this.attachments,
    this.onTap,
  });

  final List<AttachmentEntity> attachments;
  final void Function(AttachmentEntity attachment)? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: attachments.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return _AttachmentTile(
            attachment: attachment,
            onTap: onTap == null ? null : () => onTap!(attachment),
          );
        },
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, this.onTap});

  final AttachmentEntity attachment;
  final VoidCallback? onTap;

  IconData get _icon {
    if (attachment.isPdf) return Icons.picture_as_pdf_outlined;
    return switch (attachment.extension) {
      'doc' || 'docx' => Icons.description_outlined,
      'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
      'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
      'mp4' || 'mov' || 'avi' => Icons.videocam_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 150.w,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            padding: EdgeInsets.all(10.w),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    height: 44.w,
                    width: 44.w,
                    child: attachment.isImage
                        ? CachedNetworkImage(
                            imageUrl: attachment.url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => ColoredBox(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (_, __, ___) => _IconBox(
                              icon: Icons.broken_image_outlined,
                            ),
                          )
                        : _IconBox(icon: _icon),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        attachment.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (attachment.sizeInBytes != null) ...[
                        SizedBox(height: 3.h),
                        Text(
                          attachment.sizeInBytes!.readableFileSize,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.primary.withValues(alpha: 0.10),
      child: Center(
        child: Icon(icon, size: 20.sp, color: theme.colorScheme.primary),
      ),
    );
  }
}
