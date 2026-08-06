import 'package:apx_task_management/features/tasks/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/user_avatar.dart';

/// A single entry in the comments timeline.
///
/// The current user's comments are right-aligned and tinted with the brand
/// colour (chat style); everyone else sits on the left. Long-pressing your own
/// comment opens the edit/delete menu.
class CommentBubble extends StatelessWidget {
  const CommentBubble({
    super.key,
    required this.comment,
    required this.isMine,
    required this.isLastInGroup,
    this.onEdit,
    this.onDelete,
    this.onRetry,
  });

  final CommentEntity comment;
  final bool isMine;
  final bool isLastInGroup;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bubbleColor = isMine
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.surfaceContainerHighest;

    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 16.h : 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine)
            SizedBox(
              width: 32.w,
              child: isLastInGroup
                  ? UserAvatar(
                      name: comment.addedBy,
                      imageUrl: comment.addedBy,
                      size: 28.w,
                    )
                  : null,
            ),
          SizedBox(width: 8.w),
          Flexible(
            child: GestureDetector(
              onLongPress: (onEdit == null && onDelete == null)
                  ? null
                  : () => _showActions(context),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (isLastInGroup && !isMine) ...[
                    Padding(
                      padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                      child: Text(
                        comment.addedBy,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14.r),
                        topRight: Radius.circular(14.r),
                        bottomLeft: Radius.circular(isMine ? 14.r : 4.r),
                        bottomRight: Radius.circular(isMine ? 4.r : 14.r),
                      ),
                      
                    ),
                    child: Text(
                      comment.content,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  _MetaLine(comment: comment, isMine: isMine, onRetry: onRetry),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          if (isMine)
            SizedBox(
              width: 32.w,
              child: isLastInGroup
                  ? UserAvatar(
                      name: comment.addedBy,
                      imageUrl: comment.addedBy,
                      size: 28.w,
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text(AppStrings.editComment),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  AppStrings.delete,
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onDelete!();
                },
              ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

/// Timestamp, "edited" marker and the pending/failed indicators.
class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.comment,
    required this.isMine,
    required this.onRetry,
  });

  final CommentEntity comment;
  final bool isMine;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppTextStyles.labelSmall.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // if (comment.isPending) ...[
        //   SizedBox(
        //     height: 9.w,
        //     width: 9.w,
        //     child: CircularProgressIndicator(
        //       strokeWidth: 1.4,
        //       color: scheme.onSurfaceVariant,
        //     ),
        //   ),
        //   SizedBox(width: 5.w),
        //   Text('Sending…', style: style),
        // ] else ...[
        //   Text(DateFormatter.relative(comment.addedOn), style: style),

        // ],
      ],
    );
  }
}
