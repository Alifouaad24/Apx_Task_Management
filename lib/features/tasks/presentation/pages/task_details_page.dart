import 'package:apx_task_management/features/tasks/presentation/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/presentation/widgets/comment_input.dart';
import 'package:apx_task_management/features/tasks/presentation/widgets/comments_timeline.dart';
import 'package:apx_task_management/features/tasks/presentation/widgets/status_selector.dart';
import 'package:apx_task_management/features/tasks/presentation/widgets/task_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/task_entity.dart';

class TaskDetailsPage extends StatefulWidget {
  const TaskDetailsPage({super.key});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  final ScrollController _detailsScrollController = ScrollController();
  late TaskEntity _task;
  @override
  void dispose() {
    _detailsScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _task = Get.arguments as TaskEntity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GetBuilder<TaskListController>(
          tag: _task.status.apiValue,
          builder: (controller) {
            return Text(_task.displayKey);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.refresh_rounded, size: 22.sp),
            tooltip: AppStrings.retry,
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: GetBuilder<TaskListController>(
        tag: _task.status.apiValue,
        builder: (controller) {
          // ✅ جيب أحدث نسخة من التاسك بدل الاعتماد على الـ snapshot الثابت
          final currentTask =
              controller.tasks.firstWhereOrNull((t) => t.id == _task.id) ??
              _task; // fallback للنسخة الأصلية لو مش لاقيها لأي سبب

          return RefreshIndicator(
            onRefresh: () async {},
            child: SingleChildScrollView(
              controller: _detailsScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TaskHeader(task: currentTask),
                  SizedBox(height: 16.h),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: StatusSelector(
                      current: currentTask.status,
                      isBusy: controller.isChangingStatus,
                      onSelected: (newStatus) =>
                          controller.changeStatusFor(currentTask.id, newStatus),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _DescriptionCard(
                      task: currentTask,
                    ), // ← استخدم currentTask
                  ),
                  SizedBox(height: 16.h),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TaskInfoSection(
                      task: currentTask,
                    ), // ← استخدم currentTask
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    child: _SectionTitle(
                      title: AppStrings.comments,
                      count: currentTask.commentsCount, // ← استخدم currentTask
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: CommentsTimeline(
                      tag: _task.status.apiValue,
                      task: currentTask, // ← استخدم currentTask
                    ),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CommentInput(
        tag: _task.status.apiValue,
        taskId: _task.id,
        task: _task,
      ),
    );
  }
}

/// Priority + status + title block at the top of the screen.
class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(
                label: task.status.label,
                apiValue: task.status.apiValue,
                compact: true,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            task.body,
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

  final TaskEntity task;

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool _expanded = false;

  static const int _collapsedLength = 220;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = widget.task.body.trim();
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
