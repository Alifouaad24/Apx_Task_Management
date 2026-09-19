import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/tasks/controllers/task_form_controller.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';

/// Create a task, or edit one's notes and status (see [TaskFormController]).
class CreateTaskPage extends GetView<TaskFormController> {
  const CreateTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? 'Edit task' : 'New task'),
      ),
      body: GetBuilder<TaskFormController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Notes'),
                TextField(
                  controller: controller.notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe the task…',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.h),

                const _Label('Status'),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final status in controller.statuses)
                      ChoiceChip(
                        label: Text(status.label),
                        selected: controller.selectedStatus == status,
                        onSelected: (_) => controller.selectStatus(status),
                      ),
                  ],
                ),

                if (!controller.isEditing) ..._createFields(context),

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
                            if (await controller.submit()) Get.back();
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

  /// Everything only the create endpoint accepts.
  List<Widget> _createFields(BuildContext context) {
    if (controller.isLoadingLookups) {
      return [SizedBox(height: 24.h), const LinearProgressIndicator()];
    }

    return [
      SizedBox(height: 16.h),
      const _Label('Business'),
      _OptionDropdown(
        value: controller.selectedBusiness,
        options: controller.businesses,
        hint: 'Select a business',
        onChanged: controller.selectBusiness,
      ),
      SizedBox(height: 16.h),

      const _Label('Customer'),
      _OptionDropdown(
        value: controller.selectedCustomer,
        options: controller.customers,
        hint: 'Select a customer (optional)',
        onChanged: controller.selectCustomer,
      ),
      SizedBox(height: 16.h),

      const _Label('Schedule'),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Text(
                controller.scheduleDate == null
                    ? 'Date'
                    : DateFormatter.medium(controller.scheduleDate),
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.scheduleDate ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) controller.setScheduleDate(picked);
              },
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.schedule_outlined),
              label: Text(controller.scheduleTime?.format(context) ?? 'Time'),
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: controller.scheduleTime ?? TimeOfDay.now(),
                );
                if (picked != null) controller.setScheduleTime(picked);
              },
            ),
          ),
        ],
      ),
      SizedBox(height: 16.h),

      _AssignFields(label: 'Assigner', side: controller.assigner),
      SizedBox(height: 16.h),
      _AssignFields(label: 'Assignee', side: controller.assignee),
    ];
  }
}

/// Type picker + entity picker for one side of the assignment.
class _AssignFields extends GetView<TaskFormController> {
  const _AssignFields({required this.label, required this.side});

  final String label;
  final AssignSelection side;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<AssignTypeModel>(
                // Keyed on the value so a default picked after loading shows.
                key: ValueKey(side.type?.id),
                initialValue: side.type,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Type'),
                items: [
                  for (final type in controller.assignTypes)
                    DropdownMenuItem(value: type, child: Text(type.type)),
                ],
                onChanged: (type) => controller.selectAssignType(side, type),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 3,
              child: side.isLoading
                  ? const LinearProgressIndicator()
                  : _OptionDropdown(
                      value: side.selected,
                      options: side.options,
                      hint: side.type == null ? 'Pick a type first' : 'Select',
                      onChanged: side.type == null
                          ? null
                          : (option) =>
                                controller.selectAssignOption(side, option),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionDropdown extends StatelessWidget {
  const _OptionDropdown({
    required this.value,
    required this.options,
    required this.hint,
    required this.onChanged,
  });

  final LookupOption? value;
  final List<LookupOption> options;
  final String hint;
  final ValueChanged<LookupOption?>? onChanged;

  @override
  Widget build(BuildContext context) {
    // A value missing from the list would trip Flutter's assertion.
    final selected = options.contains(value) ? value : null;
    return DropdownButtonFormField<LookupOption>(
      // Keyed on the value so a default picked after loading shows.
      key: ValueKey(selected?.id),
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      hint: Text(hint),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text, style: AppTextStyles.labelMedium),
    );
  }
}
