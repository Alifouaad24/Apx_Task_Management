import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/core/widgets.dart';
import 'package:apx_task_management/features/tasks/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';

// --------------------------------------------------------------------------
// Comment bubble
// --------------------------------------------------------------------------

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

  final CommentModel comment;
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

  final CommentModel comment;
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
      children: [Text(DateFormatter.relative(comment.addedOn), style: style)],
    );
  }
}

// --------------------------------------------------------------------------
// Comment input
// --------------------------------------------------------------------------

class CommentInput extends StatelessWidget {
  const CommentInput({super.key, required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<TaskListController>(
      builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.inputController,
                          focusNode: controller.inputFocus,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: AppStrings.writeComment,
                            isDense: true,
                            filled: true,
                            fillColor:
                                theme.colorScheme.surfaceContainerHighest,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22.r),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _SendButton(
                        isBusy: controller.isSending,
                        onPressed: () => controller.sendComment(taskId),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44.w,
      width: 44.w,
      child: Material(
        color: theme.colorScheme.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isBusy ? null : onPressed,
          child: Center(
            child: isBusy
                ? SizedBox(
                    height: 18.w,
                    width: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    size: 18.sp,
                    color: theme.colorScheme.onPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Comments timeline
// --------------------------------------------------------------------------

/// The chat-style comments thread, grouped by day.
///
/// Rendered inside the task details scroll view, so it shrink-wraps and never
/// scrolls itself.
class CommentsTimeline extends StatelessWidget {
  const CommentsTimeline({super.key, required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    if (task.comments.isEmpty) {
      return const EmptyStateWidget(
        title: AppStrings.noComments,
        subtitle: AppStrings.noCommentsSubtitle,
        icon: Icons.forum_outlined,
        compact: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _buildTimeline(context, task.comments),
    );
  }

  List<Widget> _buildTimeline(
    BuildContext context,
    List<CommentModel> comments,
  ) {
    final widgets = <Widget>[];
    String? currentDay;

    for (var i = 0; i < comments.length; i++) {
      final comment = comments[i];
      final day = DateFormatter.dayHeader(comment.addedOn);

      if (day != currentDay) {
        currentDay = day;
        widgets.add(_DayDivider(label: day));
      }

      final next = i + 1 < comments.length ? comments[i + 1] : null;

      final isLastInGroup =
          next == null || DateFormatter.dayHeader(next.addedOn) != day;

      widgets.add(
        CommentBubble(
          comment: comment,
          isLastInGroup: isLastInGroup,
          isMine: true,
        ),
      );
    }

    return widgets;
  }
}

/// Today / Yesterday / date separator.
class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant,
              endIndent: 12.w,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant,
              indent: 12.w,
            ),
          ),
        ],
      ),
    );
  }
}
