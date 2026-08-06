import 'package:apx_task_management/features/tasks/data/models/task_model.dart';
import 'package:apx_task_management/features/tasks/domain/entities/task_entity.dart';
import 'package:apx_task_management/features/tasks/presentation/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/presentation/widgets/comment_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_widget.dart';

/// The chat-style comments thread, grouped by day.
///
/// Rendered inside the task details scroll view, so it shrink-wraps and never
/// scrolls itself.
class CommentsTimeline extends GetView<TaskListController> {
  const CommentsTimeline({super.key, required this.tag, required this.task});
  final String tag;
  final TaskEntity task;
  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaskListController>(
      tag: tag,
      builder: (controller) {
        if (controller.isCommentsLoading && task.comments.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 32.h),
            child: const AppLoader(),
          );
        }

        if (controller.commentsFailure != null && task.comments.isEmpty) {
          return AppErrorWidget(
            failure: controller.commentsFailure,
            compact: true,
            onRetry: () {},
          );
        }

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
      },
    );
  }

  List<Widget> _buildTimeline(
    BuildContext context,
    List<CommentEntity> comments,
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
