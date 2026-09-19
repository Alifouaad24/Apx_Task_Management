import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/core/widgets.dart';
import 'package:apx_task_management/features/tasks/views/widgets/comment_widgets.dart';
import 'package:apx_task_management/features/tasks/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/views/widgets/task_detail_widgets.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';

/// Opened with a task id (or a [TaskModel]) as the route argument. Always
/// renders the board's live copy, so status changes and new comments show up
/// immediately.
class TaskDetailsPage extends StatefulWidget {
  const TaskDetailsPage({super.key});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  final ScrollController _detailsScrollController = ScrollController();
  final TaskListController _board = Get.find<TaskListController>();
  late final int? _taskId = switch (Get.arguments) {
    final int id => id,
    final TaskModel task => task.id,
    final String id => int.tryParse(id),
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    final id = _taskId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _board.markCommentsRead(id),
      );
    }
  }

  @override
  void dispose() {
    _detailsScrollController.dispose();
    super.dispose();
  }

  Future<void> _changeStatus(TaskModel task, OrderStatusModel status) async {
    final success = await _board.changeStatusFor(task, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? AppStrings.statusUpdated
              : _board.errorMessage ?? AppStrings.somethingWentWrong,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaskListController>(
      builder: (controller) {
        final id = _taskId;
        final task = id == null ? null : controller.taskById(id);

        if (task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : EmptyStateWidget(
                    title: 'Task not found',
                    subtitle: 'It may have been deleted.',
                    actionLabel: AppStrings.retry,
                    onAction: controller.reload,
                  ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(task.displayKey),
            actions: [
              IconButton(
                onPressed: controller.reload,
                icon: Icon(Icons.refresh_rounded, size: 22.sp),
                tooltip: AppStrings.retry,
              ),
              SizedBox(width: 4.w),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: controller.reload,
            child: SingleChildScrollView(
              controller: _detailsScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TaskHeader(task: task),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: StatusSelector(
                      current: task.status,
                      statuses: controller.statuses,
                      isBusy: controller.isChangingStatus,
                      onSelected: (status) => _changeStatus(task, status),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _DescriptionCard(task: task),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TaskInfoSection(task: task),
                  ),
                  SizedBox(height: 20.h),
                  _SectionTitle(
                    title: AppStrings.comments,
                    count: task.commentsCount,
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: CommentsTimeline(task: task),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          bottomNavigationBar: CommentInput(taskId: task.id),
        );
      },
    );
  }
}

/// Status + notes block at the top of the screen.
class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.status != null) ...[
            Row(
              children: [
                StatusChip(
                  label: task.status!.label,
                  apiValue: task.status!.colorKey,
                  compact: true,
                ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
          Text(
            task.notes,
            style: AppTextStyles.headlineSmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Description card with an expand/collapse control for long text.
class _DescriptionCard extends StatefulWidget {
  const _DescriptionCard({required this.task});

  final TaskModel task;

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool _expanded = false;

  static const int _collapsedLength = 220;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = widget.task.notes.trim();
    final isEmpty = description.isEmpty;
    final isLong = description.length > _collapsedLength;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.description,
            style: AppTextStyles.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isEmpty
                ? AppStrings.noDescription
                : (_expanded || !isLong
                      ? description
                      : description.truncate(_collapsedLength)),
            style: AppTextStyles.bodyMedium.copyWith(
              color: isEmpty
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
              fontStyle: isEmpty ? FontStyle.italic : null,
            ),
          ),
          if (isLong) ...[
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Show more',
                style: AppTextStyles.labelMedium.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section heading with an optional count pill.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (count != null && count! > 0) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
