import 'package:apx_task_management/features/tasks/domain/entities/task_entity.dart';
import 'package:apx_task_management/features/tasks/presentation/controllers/task_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';

class CommentInput extends StatelessWidget {
  const CommentInput({super.key, required this.tag, required this.taskId, required this.task});
  final String tag;
  final int taskId;
  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<TaskListController>(
      tag: tag,
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
                controller.isEditing
                    ? _EditingBanner(onCancel: () {})
                    : const SizedBox.shrink(),
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
                        onPressed: () => controller.sendComment(taskId), // ← هنا
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

class _EditingBanner extends StatelessWidget {
  const _EditingBanner({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 0),
      child: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            size: 14.sp,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 6.w),
          Text(
            AppStrings.editComment,
            style: AppTextStyles.labelSmall.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onCancel,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 16.sp),
            tooltip: AppStrings.cancel,
          ),
        ],
      ),
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
