import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/core/widgets.dart';
import 'package:apx_task_management/features/auth/models/business_model.dart';
import 'package:apx_task_management/features/tasks/controllers/home_controller.dart';
import 'package:apx_task_management/features/tasks/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/views/widgets/task_list_widgets.dart';

/// The dashboard: a greeting header, a search field and one tab per status
/// the server returns.
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
            Expanded(
              child: GetBuilder<TaskListController>(
                builder: (board) => GetBuilder<HomeController>(
                  builder: (controller) => _buildBoard(context, board),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, TaskListController board) {
    final tabController = controller.tabController;

    // Statuses are loaded before anything else, so until they arrive there is
    // no board to show — only its loading or error state.
    if (tabController == null || controller.statuses.isEmpty) {
      if (board.isLoading) {
        return const TaskListSkeleton();
      }
      if (board.failure != null) {
        return AppErrorWidget(failure: board.failure, onRetry: board.reload);
      }
      return EmptyStateWidget(
        title: 'No statuses',
        subtitle: 'This service has no task statuses configured.',
        icon: Icons.view_week_outlined,
      );
    }

    return Column(
      children: [
        _StatusTabBar(tabController: tabController),
        SizedBox(height: 2.h),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              for (final status in controller.statuses)
                TaskListView(key: ValueKey(status.id), status: status),
            ],
          ),
        ),
      ],
    );
  }
}

/// Greeting, business picker, avatar and the collapsible search field.
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
                        const _BusinessSelector(),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: controller.openCreateTask,
                    tooltip: 'New task',
                    icon: Icon(Icons.add_task, size: 22.sp),
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
                            hintText: 'Search by notes, customer or #id…',
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

/// The current business; tapping it lists the others to switch to.
class _BusinessSelector extends StatelessWidget {
  const _BusinessSelector();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<TaskListController>(
      builder: (board) {
        final current = board.currentBusiness;
        if (current == null) return const SizedBox.shrink();

        final canSwitch = board.businesses.length > 1;
        final label = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 18.sp,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                current.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (canSwitch)
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        );

        if (!canSwitch) return label;

        return PopupMenuButton<BusinessModel>(
          tooltip: 'Switch business',
          initialValue: current,
          onSelected: board.selectBusiness,
          position: PopupMenuPosition.under,
          itemBuilder: (context) => [
            for (final business in board.businesses)
              CheckedPopupMenuItem(
                value: business,
                checked: business == current,
                child: Text(business.name),
              ),
          ],
          child: label,
        );
      },
    );
  }
}

/// Scrollable pill tab bar, one tab per status from the server.
class _StatusTabBar extends GetView<HomeController> {
  const _StatusTabBar({required this.tabController});

  final TabController tabController;

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
          controller: tabController,
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
