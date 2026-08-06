import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../tasks/domain/entities/task_entity.dart';

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
