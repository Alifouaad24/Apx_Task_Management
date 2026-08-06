import 'package:apx_task_management/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../controllers/home_controller.dart';
import '../widgets/task_list_view.dart';

/// The dashboard: a greeting header, a search field and one tab per status.
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _DashboardHeader(),
            const _StatusTabBar(),
            SizedBox(height: 4.h),
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: [
                  for (final status in controller.statuses)
                    TaskListView(status: status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Greeting, avatar and the collapsible search field.
class _DashboardHeader extends GetView<HomeController> {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<HomeController>(
      builder: (controller) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.greeting,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        IconButton(
                          onPressed: () => Get.toNamed(
                            '/addUpdateTask',
                            arguments: controller.currentStatus.apiValue,
                          ),
                          icon: const Icon(Icons.add_task),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: controller.toggleSearch,
                    tooltip: controller.isSearching ? 'Close search' : 'Search',
                    icon: Icon(
                      controller.isSearching
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      size: 22.sp,
                    ),
                  ),

                  SizedBox(width: 4.w),

                  GestureDetector(
                    onTap: controller.openProfile,
                    child: UserAvatar(
                      name: controller.userName,
                      imageUrl: controller.userAvatar,
                      size: 40.w,
                    ),
                  ),
                ],
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: controller.isSearching
                    ? Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: TextField(
                          controller: controller.searchController,
                          onChanged: controller.onSearchChanged,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by title or key…',
                            prefixIcon: Icon(Icons.search_rounded, size: 20.sp),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Scrollable pill tab bar, one tab per [TaskStatus].
class _StatusTabBar extends GetView<HomeController> {
  const _StatusTabBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: TabBar(
          controller: controller.tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          labelPadding: EdgeInsets.symmetric(horizontal: 14.w),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: [
            for (final status in controller.statuses)
              Tab(height: 36.h, text: status.label),
          ],
        ),
      ),
    );
  }
}
