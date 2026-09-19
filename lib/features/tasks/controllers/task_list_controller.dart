import 'package:dartz/dartz.dart' show Either, Left;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/features/auth/models/business_model.dart';
import 'package:apx_task_management/features/auth/usecases/auth_usecases.dart';
import 'package:apx_task_management/features/tasks/models/task_model.dart';
import 'package:apx_task_management/features/tasks/usecases/task_usecases.dart';

/// The task board: the service's statuses and every task in it.
///
/// One instance for the whole dashboard. The API returns all tasks in one
/// call, so each tab is just [tasksFor] a status, and moving a task between
/// tabs is a local update rather than a refetch.
class TaskListController extends GetxController {
  TaskListController({
    required GetTaskScopeUseCase getScope,
    required LoadTaskBoardUseCase loadBoard,
    required DeleteTaskUseCase deleteTask,
    required AddCommentUseCase addComment,
    required MarkCommentsReadUseCase markCommentsRead,
    required ChangeStatusUseCase changeStatus,
    required GetCurrentUserUseCase getCurrentUser,
    required LoadBusinessesUseCase loadBusinesses,
    required GetCurrentBusinessUseCase getCurrentBusiness,
    required SelectBusinessUseCase selectBusiness,
  }) : _getScope = getScope,
       _loadBoard = loadBoard,
       _deleteTask = deleteTask,
       _addComment = addComment,
       _markCommentsRead = markCommentsRead,
       _changeStatus = changeStatus,
       _getCurrentUser = getCurrentUser,
       _loadBusinesses = loadBusinesses,
       _getCurrentBusiness = getCurrentBusiness,
       _selectBusiness = selectBusiness;

  final GetTaskScopeUseCase _getScope;
  final LoadTaskBoardUseCase _loadBoard;
  final DeleteTaskUseCase _deleteTask;
  final AddCommentUseCase _addComment;
  final MarkCommentsReadUseCase _markCommentsRead;
  final ChangeStatusUseCase _changeStatus;
  final GetCurrentUserUseCase _getCurrentUser;
  final LoadBusinessesUseCase _loadBusinesses;
  final GetCurrentBusinessUseCase _getCurrentBusiness;
  final SelectBusinessUseCase _selectBusiness;

  // ---- Business -------------------------------------------------------------
  List<BusinessModel> businesses = [];
  BusinessModel? currentBusiness;

  // ---- Board ----------------------------------------------------------------
  List<OrderStatusModel> statuses = [];
  final List<TaskModel> _tasks = [];
  bool isLoading = false;
  Failure? failure;
  String _query = '';

  /// Set once the scope resolves; the create form needs it too.
  TaskScope? scope;

  // ---- Status change --------------------------------------------------------
  bool isChangingStatus = false;
  String? errorMessage;

  // ---- Comment input --------------------------------------------------------
  final inputController = TextEditingController();
  final inputFocus = FocusNode();
  bool isSending = false;

  /// Where new tasks start: "New" when the service has it, else the first tab.
  OrderStatusModel? get defaultStatus =>
      statuses.firstWhereOrNull((s) => s.isNew) ?? statuses.firstOrNull;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  @override
  void onClose() {
    inputController.dispose();
    inputFocus.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Board
  // ---------------------------------------------------------------------------

  /// Fetches statuses, then tasks. The skeleton only shows on the first load.
  Future<void> reload() async {
    isLoading = statuses.isEmpty;
    failure = null;
    update();

    if (businesses.isEmpty) {
      (await _loadBusinesses()).fold(
        (error) => AppLogger.w('Loading businesses failed: $error'),
        (list) => businesses = list,
      );
    }
    currentBusiness = _getCurrentBusiness();

    final result = await _getScope().fold<Future<Either<Failure, TaskBoard>>>(
      (error) async => Left(error),
      (scope) {
        this.scope = scope;
        return _loadBoard(scope);
      },
    );

    result.fold(
      (error) {
        AppLogger.w('Loading the task board failed: $error');
        failure = error;
      },
      (board) {
        statuses = board.statuses;
        _tasks.assignAll(board.tasks);
      },
    );

    isLoading = false;
    update();
  }

  /// Switches the board to [business] and fetches its tasks.
  Future<void> selectBusiness(BusinessModel business) async {
    if (business == currentBusiness) return;

    await _selectBusiness(business);
    statuses = [];
    _tasks.clear();
    await reload();
  }

  /// Tasks in [status] matching the current search.
  List<TaskModel> tasksFor(OrderStatusModel status) => _tasks
      .where((task) => task.status?.id == status.id && _matches(task))
      .toList();

  TaskModel? taskById(int id) => _tasks.firstWhereOrNull((t) => t.id == id);

  /// Filters locally by notes, customer or `#id`.
  void applySearch(String query) {
    _query = query.trim().toLowerCase();
    update();
  }

  bool _matches(TaskModel task) {
    if (_query.isEmpty) return true;
    return task.notes.toLowerCase().contains(_query) ||
        task.displayKey.contains(_query) ||
        '${task.id}' == _query ||
        (task.customerName?.toLowerCase().contains(_query) ?? false);
  }

  void replaceTask(TaskModel task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) _tasks[index] = task;
    update();
  }

  Future<bool> deleteTaskById(int taskId) async {
    final result = await _deleteTask(taskId);
    return result.fold(
      (error) {
        errorMessage = error.message;
        update();
        return false;
      },
      (_) {
        _tasks.removeWhere((t) => t.id == taskId);
        update();
        return true;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Status change
  // ---------------------------------------------------------------------------
  Future<bool> changeStatusFor(TaskModel task, OrderStatusModel status) async {
    isChangingStatus = true;
    errorMessage = null;
    update();

    final result = await _changeStatus(task, status);

    isChangingStatus = false;
    return result.fold(
      (error) {
        errorMessage = error.message;
        update();
        return false;
      },
      (_) {
        replaceTask(task.copyWith(status: status));
        return true;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------
  Future<void> sendComment(int taskId) async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

    isSending = true;
    update();

    final result = await _addComment(taskId, text);

    isSending = false;

    result.fold((error) => errorMessage = error.message, (_) {
      // The endpoint returns nothing, so add the comment locally.
      final task = taskById(taskId);
      if (task != null) {
        replaceTask(
          task.copyWith(
            comments: [
              ...task.comments,
              CommentModel(
                id: DateTime.now().millisecondsSinceEpoch,
                content: text,
                addedBy: _getCurrentUser()?.name ?? '',
                addedOn: DateTime.now(),
                isRead: true,
              ),
            ],
          ),
        );
      }
      inputController.clear();
      inputFocus.unfocus();
    });

    update();
  }

  /// Opening a task marks its comments read, on the server and locally.
  Future<void> markCommentsRead(int taskId) async {
    final task = taskById(taskId);
    if (task == null || !task.hasUnreadComments) return;

    final result = await _markCommentsRead(taskId);
    result.fold(
      (error) => AppLogger.w('Marking comments read failed: $error'),
      (_) => replaceTask(
        task.copyWith(
          comments: [
            for (final c in task.comments)
              CommentModel(
                id: c.id,
                content: c.content,
                addedBy: c.addedBy,
                addedOn: c.addedOn,
                isRead: true,
              ),
          ],
        ),
      ),
    );
  }
}
