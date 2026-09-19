import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:apx_task_management/features/auth/usecases/auth_usecases.dart';
import 'package:apx_task_management/features/tasks/controllers/home_controller.dart';
import 'package:apx_task_management/features/tasks/controllers/task_list_controller.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';
import 'package:apx_task_management/features/tasks/repositories/task_repository.dart';
import 'package:apx_task_management/features/tasks/usecases/task_usecases.dart';

/// The create / edit task form.
///
/// Opened with a [TaskModel] as the route argument it edits that task (notes
/// and status only, as the API allows); opened without one it creates a task.
class TaskFormController extends GetxController {
  TaskFormController({
    required TaskListController board,
    required CreateTaskUseCase createTask,
    required UpdateTaskUseCase updateTask,
    required GetAssignTypesUseCase getAssignTypes,
    required GetAssignOptionsUseCase getAssignOptions,
    required GetBusinessesUseCase getBusinesses,
    required GetCustomersUseCase getCustomers,
    required GetCurrentUserUseCase getCurrentUser,
    this.editingTask,
  }) : _board = board,
       _createTask = createTask,
       _updateTask = updateTask,
       _getAssignTypes = getAssignTypes,
       _getAssignOptions = getAssignOptions,
       _getBusinesses = getBusinesses,
       _getCustomers = getCustomers,
       _getCurrentUser = getCurrentUser;

  final TaskListController _board;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final GetAssignTypesUseCase _getAssignTypes;
  final GetAssignOptionsUseCase _getAssignOptions;
  final GetBusinessesUseCase _getBusinesses;
  final GetCustomersUseCase _getCustomers;
  final GetCurrentUserUseCase _getCurrentUser;

  final TaskModel? editingTask;
  bool get isEditing => editingTask != null;

  final notesController = TextEditingController();
  OrderStatusModel? selectedStatus;
  bool isSaving = false;
  String? errorMessage;

  List<OrderStatusModel> get statuses => _board.statuses;

  // ---- Create-only fields ---------------------------------------------------
  List<LookupOption> businesses = [];
  LookupOption? selectedBusiness;
  List<LookupOption> customers = [];
  LookupOption? selectedCustomer;
  DateTime? scheduleDate;
  TimeOfDay? scheduleTime;

  List<AssignTypeModel> assignTypes = [];
  final assigner = AssignSelection();
  final assignee = AssignSelection();

  bool isLoadingLookups = false;

  @override
  void onInit() {
    super.onInit();
    final task = editingTask;
    if (task != null) {
      notesController.text = task.notes;
      selectedStatus = task.status;
    } else {
      selectedStatus = _board.defaultStatus;
      _loadLookups();
    }
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------------
  Future<void> _loadLookups() async {
    final scope = _board.scope;
    if (scope == null) return;

    isLoadingLookups = true;
    update();

    await Future.wait([
      _getBusinesses(scope.businessId).then(
        (result) => result.fold(_showError, (list) {
          businesses = list;
          selectedBusiness = list.firstWhereOrNull(
            (b) => b.id == '${scope.businessId}',
          );
        }),
      ),
      _getCustomers(
        scope.businessId,
      ).then((result) => result.fold(_showError, (list) => customers = list)),
      _getAssignTypes().then(
        (result) => result.fold(_showError, (list) => assignTypes = list),
      ),
    ]);

    isLoadingLookups = false;
    update();

    // Both sides default to "User", with the signed-in user as the assigner.
    final userType =
        assignTypes.firstWhereOrNull((t) => t.type == 'User') ??
        assignTypes.firstOrNull;
    if (userType != null) {
      await Future.wait([
        selectAssignType(
          assigner,
          userType,
          preselectId: _getCurrentUser()?.id,
        ),
        selectAssignType(assignee, userType),
      ]);
    }
  }

  /// Picks the type for one side and loads the options behind it.
  Future<void> selectAssignType(
    AssignSelection side,
    AssignTypeModel? type, {
    String? preselectId,
  }) async {
    side
      ..type = type
      ..options = []
      ..selected = null
      ..isLoading = type != null;
    update();

    final scope = _board.scope;
    if (type == null || scope == null) return;

    final result = await _getAssignOptions(type.type, scope.businessId);
    // The user may have switched type while this was loading.
    if (side.type != type) return;

    result.fold(_showError, (options) {
      side.options = options;
      side.selected = options.firstWhereOrNull((o) => o.id == preselectId);
    });
    side.isLoading = false;
    update();
  }

  void selectAssignOption(AssignSelection side, LookupOption? option) {
    side.selected = option;
    update();
  }

  void _showError(Object error) => errorMessage = error.toString();

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------
  void selectStatus(OrderStatusModel? value) {
    selectedStatus = value;
    update();
  }

  void selectBusiness(LookupOption? value) {
    selectedBusiness = value;
    update();
  }

  void selectCustomer(LookupOption? value) {
    selectedCustomer = value;
    update();
  }

  void setScheduleDate(DateTime? value) {
    scheduleDate = value;
    update();
  }

  void setScheduleTime(TimeOfDay? value) {
    scheduleTime = value;
    update();
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------
  Future<bool> submit() async {
    final notes = notesController.text.trim();
    if (notes.isEmpty) {
      errorMessage = 'Please enter the task notes';
      update();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    update();

    final success = isEditing ? await _saveEdit(notes) : await _saveNew(notes);

    isSaving = false;
    update();
    return success;
  }

  Future<bool> _saveEdit(String notes) async {
    final task = editingTask!;
    final result = await _updateTask(
      task.id,
      notes: notes,
      statusId: selectedStatus?.id,
    );
    return result.fold(
      (error) {
        errorMessage = error.message;
        return false;
      },
      (_) {
        _board.replaceTask(task.copyWith(notes: notes, status: selectedStatus));
        return true;
      },
    );
  }

  Future<bool> _saveNew(String notes) async {
    final scope = _board.scope;
    final businessId =
        int.tryParse(selectedBusiness?.id ?? '') ?? scope?.businessId;
    if (scope == null || businessId == null) {
      errorMessage = 'Please select a business';
      return false;
    }

    final time = scheduleTime;
    final result = await _createTask(
      NewTaskData(
        notes: notes,
        businessId: businessId,
        serviceId: scope.serviceId,
        statusId: selectedStatus?.id,
        customerId: selectedCustomer?.id,
        scheduleDate: scheduleDate == null
            ? null
            : DateFormat('yyyy-MM-dd').format(scheduleDate!),
        scheduleTime: time == null
            ? null
            : '${time.hour.toString().padLeft(2, '0')}:'
                  '${time.minute.toString().padLeft(2, '0')}',
        assignerTypeId: assigner.type?.id,
        assignerId: assigner.selected?.id,
        assigneeTypeId: assignee.type?.id,
        assigneeId: assignee.selected?.id,
      ),
    );

    return result.fold(
      (error) {
        errorMessage = error.message;
        return false;
      },
      (_) {
        // The endpoint returns nothing, so fetch the board to get the new task.
        _board.reload();
        final status = selectedStatus;
        if (status != null && Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().goToStatusTab(status);
        }
        return true;
      },
    );
  }
}

/// One side of the assignment (assigner or assignee): which kind of entity,
/// the entities of that kind, and the chosen one.
class AssignSelection {
  AssignTypeModel? type;
  List<LookupOption> options = [];
  LookupOption? selected;
  bool isLoading = false;
}

/// Registered on the form route, so the form starts fresh on every visit.
class TaskFormBinding extends Bindings {
  @override
  void dependencies() {
    final repository = Get.find<TaskRepository>();
    final arguments = Get.arguments;

    Get.lazyPut(
      () => TaskFormController(
        board: Get.find<TaskListController>(),
        createTask: CreateTaskUseCase(repository),
        updateTask: UpdateTaskUseCase(repository),
        getAssignTypes: GetAssignTypesUseCase(repository),
        getAssignOptions: GetAssignOptionsUseCase(repository),
        getBusinesses: GetBusinessesUseCase(repository),
        getCustomers: GetCustomersUseCase(repository),
        getCurrentUser: Get.find<GetCurrentUserUseCase>(),
        editingTask: arguments is TaskModel ? arguments : null,
      ),
    );
  }
}
