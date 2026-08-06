import 'package:apx_task_management/features/tasks/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/task_status.dart';
import '../controllers/task_list_controller.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  late final String tag =
      (Get.arguments as String?) ?? TaskStatus.newTask.apiValue;
  late final TaskListController controller = Get.find<TaskListController>(
    tag: tag,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLookups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New task')),
      body: GetBuilder<TaskListController>(
        tag: tag,
        builder: (controller) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Body ----
                Text('Body', style: AppTextStyles.labelMedium),
                SizedBox(height: 8.h),
                TextField(
                  controller: controller.bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'type here ...',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.h),

                // ---- Status ----
                Text('Status', style: AppTextStyles.labelMedium),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  children: [
                    for (final status in TaskStatus.tabOrder)
                      ChoiceChip(
                        label: Text(status.label),
                        selected: controller.selectedStatus.apiValue == status.apiValue,
                        onSelected: (_) => controller.selectStatus(status),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),

                // ---- Business ----
                Text('Business', style: AppTextStyles.labelMedium),
                SizedBox(height: 8.h),
                controller.isLoadingBusinesses
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<BusinessEntity>(
                        value: controller.selectedBusiness,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('اختر البزنس'),
                        items: [
                          for (final b in controller.businesses)
                            DropdownMenuItem(value: b, child: Text(b.name)),
                        ],
                        onChanged: controller.selectBusiness,
                      ),
                SizedBox(height: 16.h),

                // ---- Service ----
                Text('Service', style: AppTextStyles.labelMedium),
                SizedBox(height: 8.h),
                controller.isLoadingServices
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<ServiceEntity>(
                        value: controller.selectedService,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: Text(
                          controller.selectedBusiness == null
                              ? 'اختر البزنس الأول'
                              : 'اختر السيرفس',
                        ),
                        items: [
                          for (final s in controller.services)
                            DropdownMenuItem(value: s, child: Text(s.name)),
                        ],
                        onChanged: controller.selectedBusiness == null
                            ? null
                            : controller.selectService,
                      ),
                SizedBox(height: 16.h),

                // ---- Global System ----
                Text('Global System', style: AppTextStyles.labelMedium),
                SizedBox(height: 8.h),
                controller.isLoadingGlobalSystems
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<GlobalSystemEntity>(
                        value: controller.selectedGlobalSystem,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('اختر السيستم (اختياري)'),
                        items: [
                          for (final g in controller.globalSystems)
                            DropdownMenuItem(value: g, child: Text(g.name)),
                        ],
                        onChanged: controller.selectGlobalSystem,
                      ),
                SizedBox(height: 16.h),

                // ---- Comment ----
                Text('Comment', style: AppTextStyles.labelMedium),
                SizedBox(height: 8.h),
                TextField(
                  controller: controller.commentController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'type here...',
                    border: OutlineInputBorder(),
                  ),
                ),

                if (controller.errorMessage != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    controller.errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],

                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.isSaving
                        ? null
                        : () async {
                            final success = await controller.submit();
                            if (success) Get.back();
                          },
                    child: controller.isSaving
                        ? SizedBox(
                            height: 18.w,
                            width: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
