import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../controllers/profile_controller.dart';

/// Account details, appearance and notification preferences.
class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: Obx(() {
        if (controller.isLoading.value && controller.user.value == null) {
          return const AppLoader();
        }

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
            children: [
              const _ProfileCard(),
              SizedBox(height: 24.h),
              const _AppearanceSection(),
              SizedBox(height: 24.h),
              const _NotificationsSection(),
              SizedBox(height: 24.h),
              const _AboutSection(),
              SizedBox(height: 28.h),
              Obx(
                () => AppButton.danger(
                  label: AppStrings.signOut,
                  icon: Icons.logout_rounded,
                  isLoading: controller.isSigningOut.value,
                  onPressed: controller.signOut,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Avatar, name, email and job title.
class _ProfileCard extends GetView<ProfileController> {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final user = controller.user.value;

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            UserAvatar(
              name: user?.displayName ?? '',
              imageUrl: user?.avatarUrl,
              size: 60.w,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    user?.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (user?.jobTitle != null) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        user!.jobTitle!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Light / dark / system theme switch.
class _AppearanceSection extends GetView<ProfileController> {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: AppStrings.appearance,
      child: Obx(
        () => Column(
          children: [
            for (final entry in const {
              ThemeMode.light: (AppStrings.themeLight, Icons.light_mode_outlined),
              ThemeMode.dark: (AppStrings.themeDark, Icons.dark_mode_outlined),
              ThemeMode.system: (
                AppStrings.themeSystem,
                Icons.brightness_auto_outlined
              ),
            }.entries)
              RadioListTile<ThemeMode>(
                value: entry.key,
                // ignore: deprecated_member_use — groupValue/onChanged keep this
                // widget usable across the Flutter versions this project targets.
                groupValue: controller.themeModeRx.value,
                onChanged: (mode) {
                  if (mode != null) controller.setThemeMode(mode);
                },
                contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                title: Row(
                  children: [
                    Icon(entry.value.$2, size: 18.sp),
                    SizedBox(width: 10.w),
                    Text(entry.value.$1, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Per-category push toggles.
class _NotificationsSection extends GetView<ProfileController> {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: AppStrings.notifications,
      child: Obx(() {
        final settings = controller.settings.value;
        final enabled = settings.pushEnabled;

        return Column(
          children: [
            SwitchListTile(
              value: settings.pushEnabled,
              onChanged: controller.togglePush,
              title: Text(
                AppStrings.pushNotifications,
                style: AppTextStyles.bodyMedium,
              ),
              subtitle: Text(
                'Master switch for everything below',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
            ),
            const Divider(height: 1),
            _ToggleTile(
              label: AppStrings.commentNotifications,
              value: settings.comments,
              enabled: enabled,
              onChanged: controller.toggleComments,
            ),
            _ToggleTile(
              label: AppStrings.statusNotifications,
              value: settings.statusChanges,
              enabled: enabled,
              onChanged: controller.toggleStatusChanges,
            ),
            _ToggleTile(
              label: AppStrings.assignmentNotifications,
              value: settings.assignments,
              enabled: enabled,
              onChanged: controller.toggleAssignments,
            ),
            _ToggleTile(
              label: AppStrings.newTaskNotifications,
              value: settings.newTasks,
              enabled: enabled,
              onChanged: controller.toggleNewTasks,
            ),
          ],
        );
      }),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;

  /// Sub-toggles grey out when the master switch is off.
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled && value,
      onChanged: enabled ? onChanged : null,
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: enabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
      dense: true,
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Section(
      title: AppStrings.about,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
            leading: Icon(Icons.info_outline_rounded, size: 20.sp),
            title: Text(AppStrings.version, style: AppTextStyles.bodyMedium),
            trailing: Text(
              '1.0.0',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (AppConfig.useMockApi)
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
              leading: Icon(
                Icons.science_outlined,
                size: 20.sp,
                color: theme.colorScheme.primary,
              ),
              title: Text('Demo mode', style: AppTextStyles.bodyMedium),
              subtitle: Text(
                'Served by the in-memory mock API',
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Titled card wrapper used by every section on this screen.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
          child: Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: child,
        ),
      ],
    );
  }
}
