import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/core/widgets.dart';
import 'package:apx_task_management/features/auth/auth_models.dart';
import 'package:apx_task_management/features/tasks/task_models.dart';

// --------------------------------------------------------------------------
// Task info section
// --------------------------------------------------------------------------

/// Card holding the task's people and dates.
class TaskInfoSection extends StatelessWidget {
  const TaskInfoSection({super.key, required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // _PersonRow(
          //   label: AppStrings.assignee,
          //   user: task.assignee,
          //   icon: Icons.person_outline_rounded,
          // ),
          // _Separator(),
          // _PersonRow(
          //   label: AppStrings.reporter,
          //   user: task.reporter,
          //   icon: Icons.flag_outlined,
          // ),
          // _Separator(),
          // _InfoRow(
          //   label: AppStrings.created,
          //   value: DateFormatter.full(task.createdAt),
          //   icon: Icons.calendar_today_outlined,
          // ),
          // _Separator(),
          _InfoRow(
            label: AppStrings.dueDate,
            value: task.createdAt == null
                ? '—'
                : DateFormatter.medium(task.createdAt),
            icon: Icons.event_outlined,
            // valueColor: task.status ? theme.colorScheme.error : null,
            // trailing: task.isOverdue
            //     ? Container(
            //         padding:
            //             EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            //         decoration: BoxDecoration(
            //           color: theme.colorScheme.error.withValues(alpha: 0.12),
            //           borderRadius: BorderRadius.circular(999.r),
            //         ),
            //         child: Text(
            //           'Overdue',
            //           style: AppTextStyles.labelSmall.copyWith(
            //             color: theme.colorScheme.error,
            //           ),
            //         ),
            //       )
            //     : null,
          ),
          _Separator(),
          // _InfoRow(
          //   label: AppStrings.updated,
          //   value: task.updatedAt == null
          //       ? '—'
          //       : '${DateFormatter.relative(task.updatedAt)} · '
          //           '${DateFormatter.full(task.updatedAt)}',
          //   icon: Icons.update_rounded,
          // ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.7),
      );
}

/// Label + value row with a leading icon.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 17.sp, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 12.w),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 8.w),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Row rendering a person with their avatar, or an "unassigned" placeholder.
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.label,
    required this.user,
    required this.icon,
  });

  final String label;
  final UserEntity? user;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 17.sp, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 12.w),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (user == null)
            Text(
              AppStrings.unassigned,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user!.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user!.jobTitle != null)
                    Text(
                      user!.jobTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            UserAvatar(
              name: user!.displayName,
              imageUrl: user!.avatarUrl,
              size: 30.w,
            ),
          ],
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Status selector
// --------------------------------------------------------------------------

/// Reusable status-change control.
///
/// Given the current status it renders the legal next steps (from
/// [TaskStatus.allowedTransitions]) and reports the user's choice. It knows
/// nothing about tasks, controllers or the network, so it can be dropped into
/// any screen that needs to move a task along.
class StatusSelector extends StatelessWidget {
  const StatusSelector({
    super.key,
    required this.current,
    required this.onSelected,
    this.isBusy = false,
  });

  final TaskStatus current;
  final ValueChanged<TaskStatus> onSelected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transitions = current.allowedTransitions;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Status',
                style: AppTextStyles.labelMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (isBusy)
                SizedBox(
                  height: 14.w,
                  width: 14.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                StatusChip(
                  label: current.label,
                  apiValue: current.apiValue,
                ),
            ],
          ),
          SizedBox(height: 14.h),
          StatusPipeline(current: current),
          SizedBox(height: 16.h),
          if (transitions.isEmpty)
            Text(
              AppStrings.noTransitions,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            Text(
              'Move to',
              style: AppTextStyles.labelMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final status in transitions)
                  _TransitionButton(
                    status: status,
                    enabled: !isBusy,
                    onTap: () => onSelected(status),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Opens the selector as a modal sheet — handy from a list or an app bar
  /// action where there is no room for the inline version.
  static Future<TaskStatus?> showSheet(
    BuildContext context, {
    required TaskStatus current,
  }) {
    return showModalBottomSheet<TaskStatus>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.changeStatus,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 16.h),
              StatusSelector(
                current: current,
                onSelected: (status) =>
                    Navigator.of(sheetContext).pop(status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tappable target status.
class _TransitionButton extends StatelessWidget {
  const _TransitionButton({
    required this.status,
    required this.enabled,
    required this.onTap,
  });

  final TaskStatus status;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.statusColor(status.apiValue, isDark: isDark);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.isRejected
                      ? Icons.cancel_outlined
                      : Icons.arrow_forward_rounded,
                  size: 15.sp,
                  color: color,
                ),
                SizedBox(width: 6.w),
                Text(
                  status.label,
                  style: AppTextStyles.labelMedium.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal stepper showing where the task sits in the workflow.
///
/// A rejected task is drawn as a single full-width error bar, because it has
/// left the pipeline rather than progressed through it.
class StatusPipeline extends StatelessWidget {
  const StatusPipeline({super.key, required this.current});

  final TaskStatus current;

  static const List<TaskStatus> _steps = [
    TaskStatus.newTask,
    TaskStatus.inProgress,
    TaskStatus.readyfortesting,
    TaskStatus.testing,
    TaskStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (current.isRejected) {
      final color = AppColors.statusColor('rejected', isDark: isDark);
      return Row(
        children: [
          Icon(Icons.block_rounded, size: 14.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Rejected',
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      );
    }

    final currentIndex = _steps.indexOf(current);

    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0) SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: i <= currentIndex
                        ? AppColors.statusColor(
                            _steps[i].apiValue,
                            isDark: isDark,
                          )
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
                if (i == currentIndex) ...[
                  SizedBox(height: 6.h),
                  Text(
                    _steps[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.statusColor(
                        _steps[i].apiValue,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// --------------------------------------------------------------------------
// Attachment list
// --------------------------------------------------------------------------

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
