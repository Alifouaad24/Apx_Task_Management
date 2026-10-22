import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/core/widgets.dart';
import 'package:apx_task_management/features/auth/models/business_model.dart';
import 'package:apx_task_management/features/tasks/controllers/home_controller.dart';
import 'package:apx_task_management/features/tasks/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/views/widgets/task_list_widgets.dart';

/// The dashboard: a gradient header (greeting, search and the task filters),
/// then one tab per status the server returns.
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // The header is a gradient, so the status bar icons go light over it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: controller.openCreateTask,
          icon: Icon(Icons.add_rounded, size: 22.sp),
          label: const Text('New task'),
        ),
        body: Column(
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
        SizedBox(height: 16.h),
        _StatusTabBar(tabController: tabController, board: board),
        SizedBox(height: 4.h),
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

/// Gradient header: avatar, greeting, business picker, the collapsible search
/// field and the filter tiles.
class _DashboardHeader extends GetView<HomeController> {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return GetBuilder<HomeController>(
      builder: (controller) {
        final firstName = controller.userName.trim().split(' ').first;

        return Container(
          padding: EdgeInsets.fromLTRB(20.w, topInset + 14.h, 20.w, 20.h),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: controller.openProfile,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: UserAvatar(
                        name: controller.userName,
                        imageUrl: controller.userAvatar,
                        size: 42.w,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName.isEmpty
                              ? controller.greeting
                              : '${controller.greeting}, $firstName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        const _BusinessSelector(),
                      ],
                    ),
                  ),
                  _HeaderIconButton(
                    onPressed: controller.toggleSearch,
                    tooltip: controller.isSearching ? 'Close search' : 'Search',
                    icon: controller.isSearching
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                  ),
                ],
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: controller.isSearching
                    ? Padding(
                        padding: EdgeInsets.only(top: 16.h),
                        child: _SearchField(controller: controller),
                      )
                    : const SizedBox(width: double.infinity),
              ),

              SizedBox(height: 18.h),
              const _TaskFilterBar(),
            ],
          ),
        );
      },
    );
  }
}

/// Round translucent button that sits on the gradient.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 42.w,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 22.sp,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: controller.searchController,
      onChanged: controller.onSearchChanged,
      autofocus: true,
      textInputAction: TextInputAction.search,
      cursorColor: Colors.white,
      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search by notes, customer or #id…',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.7),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20.sp,
          color: Colors.white.withValues(alpha: 0.85),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.16),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

/// The current business; tapping it lists the others to switch to.
class _BusinessSelector extends StatelessWidget {
  const _BusinessSelector();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaskListController>(
      builder: (board) {
        final current = board.currentBusiness;
        if (current == null) return const SizedBox.shrink();

        final canSwitch = board.businesses.length > 1;
        final label = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                current.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (canSwitch)
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22.sp,
                color: Colors.white.withValues(alpha: 0.85),
              ),
          ],
        );

        if (!canSwitch) return label;

        return PopupMenuButton<BusinessModel>(
          tooltip: 'Switch business',
          initialValue: current,
          onSelected: board.selectBusiness,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
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

/// All / My / Today tiles that narrow every status tab at once; each shows
/// how many tasks it would leave.
class _TaskFilterBar extends StatelessWidget {
  const _TaskFilterBar();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaskListController>(
      builder: (board) => Row(
        children: [
          for (final filter in TaskFilter.values) ...[
            if (filter != TaskFilter.values.first) SizedBox(width: 10.w),
            Expanded(
              child: _FilterTile(
                filter: filter,
                count: board.countMatching(filter),
                selected: board.filter == filter,
                onTap: () => board.applyFilter(filter),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.filter,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final TaskFilter filter;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (filter) {
    TaskFilter.all => Icons.dashboard_outlined,
    TaskFilter.mine => Icons.person_outline_rounded,
    TaskFilter.today => Icons.mark_chat_unread_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primary : Colors.white;
    final muted = selected
        ? AppColors.lightTextSecondary
        : Colors.white.withValues(alpha: 0.8);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0 : 0.2),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_icon, size: 16.sp, color: foreground),
                  const Spacer(),
                  Text(
                    '$count',
                    style: AppTextStyles.titleLarge.copyWith(
                      // Unread comments from others stand out, chat style.
                      color: filter == TaskFilter.today && count > 0
                          ? Colors.red
                          : foreground,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                filter.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scrollable pill tab bar, one tab per status from the server, each with a
/// badge counting the tasks it holds under the current filter.
class _StatusTabBar extends GetView<HomeController> {
  const _StatusTabBar({required this.tabController, required this.board});

  final TabController tabController;
  final TaskListController board;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
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
          labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: [
            for (final status in controller.statuses)
              Tab(
                height: 36.h,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(status.label),
                    SizedBox(width: 6.w),
                    _CountBadge(count: board.countFor(status)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small pill that takes its colour from the tab label, so it follows the
/// selected / unselected animation for free.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color =
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;

    return GetBuilder<TaskListController>(
      builder: (controller) => 
       Container(
        constraints: BoxConstraints(minWidth: 20.w),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: (count > 0 && controller.filter == TaskFilter.today) ? Colors.red : color,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: GetBuilder<TaskListController>(
          builder: (controller) => Text(
            '$count',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
