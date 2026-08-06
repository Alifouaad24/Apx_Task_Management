import 'package:apx_task_management/core/services/session_manager.dart';
import 'package:apx_task_management/features/tasks/data/models/task_model.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/AddCommentUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/ChangeStatusUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/CreateTaskUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/DeleteTaskUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/GetBusinessesUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/GetGlobalSystemsUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/GetServicesUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/SetStatusClosedUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/SetStatusCompletedUseCase.dart';
import 'package:apx_task_management/features/tasks/domain/usecases/UpdateTaskUseCase.dart';
import 'package:apx_task_management/features/tasks/presentation/controllers/home_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/usecases/get_tasks_usecase.dart';

class TaskListController extends GetxController {
  TaskListController({
    required this.status,
    required GetTasksUseCase getTasks,
    required CreateTaskUseCase createTask,
    required GetBusinessesUseCase getBusinesses,
    required UpdateTaskUseCase updateTask,
    required AddCommentUseCase addComment,
    required DeleteTaskUseCase deleteTask,
    required GetServicesUseCase getServices,
    required GetGlobalSystemsUseCase getGlobalSystems,
    required SessionManager session,
    required SetStatusClosedUseCase setStatusClosed,
    required SetStatusCompletedUseCase setStatusCompleted,
    required ChangeStatusUseCase changeStatusUseCase,
  }) : _getTasks = getTasks,
       _createTask = createTask,
       _updateTask = updateTask,
       _addComment = addComment,
       _deleteTask = deleteTask,
       _getBusinesses = getBusinesses,
       _getServices = getServices,
       _getGlobalSystems = getGlobalSystems,
       _setStatusClosed = setStatusClosed,
       _setStatusCompleted = setStatusCompleted,
       _session = session,
       _changeStatusUseCase = changeStatusUseCase;

  final ChangeStatusUseCase _changeStatusUseCase;
  final SetStatusClosedUseCase _setStatusClosed;
  final SetStatusCompletedUseCase _setStatusCompleted;
  final SessionManager _session;
  final AddCommentUseCase _addComment;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final DeleteTaskUseCase _deleteTask;
  final GetBusinessesUseCase _getBusinesses;
  final GetServicesUseCase _getServices;
  final GetGlobalSystemsUseCase _getGlobalSystems;
  BusinessEntity? selectedBusiness;
  ServiceEntity? selectedService;
  GlobalSystemEntity? selectedGlobalSystem;

  bool isLoadingBusinesses = false;
  bool isLoadingServices = false;
  bool isLoadingGlobalSystems = false;
  List<BusinessEntity> businesses = [];
  List<ServiceEntity> services = [];
  List<GlobalSystemEntity> globalSystems = [];
  final bodyController = TextEditingController();
  final commentController = TextEditingController();

  TaskStatus selectedStatus = TaskStatus.newTask;
  bool isSaving = false;
  String? errorMessage;

  void selectStatus(TaskStatus status) {
    selectedStatus = status;
    update();
  }

  Future<void> loadLookups() async {
    await Future.wait([_loadBusinesses(), _loadGlobalSystems()]);
  }

  final List<CommentEntity> comments = [];

  // Future<void> sendComment(int taskId) async {
  //   final text = inputController.text.trim();
  //   if (text.isEmpty) return;

  //   isSending = true;
  //   update();

  //   final result = await _addComment(
  //     AddCommentParams(taskId: taskId, comment: text),
  //   );

  //   isSending = false;

  //   result.fold(
  //     (failure) {
  //       errorMessage = failure.toString();
  //       update();
  //     },
  //     (_) {
  //       final index = tasks.indexWhere((t) => t.id == taskId);
  //       if (index != -1) {
  //         final oldTask = tasks[index];
  //         final updatedComments = List<CommentEntity>.from(oldTask.comments)
  //           ..add(
  //             CommentEntity(
  //               content: text,
  //               addedBy: _session.currentUserName,
  //               addedOn: DateTime.now(),
  //               id: DateTime.now().millisecond,
  //               featureId: taskId,
  //               isRead: true,
  //             ),
  //           );

  //         tasks[index] = oldTask.copyWith(comments: updatedComments);
          

  //         update();
  //       }

  //       inputController.clear();
  //       inputFocus.unfocus();
  //       update();
  //     },
  //   );
  // }
  Future<void> sendComment(int taskId) async {
  final text = inputController.text.trim();
  if (text.isEmpty) return;

  isSending = true;
  update();

  final result = await _addComment(
    AddCommentParams(taskId: taskId, comment: text),
  );

  isSending = false;

  result.fold(
    (failure) {
      errorMessage = failure.toString();
      update();
    },
    (_) {
      final index = tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final oldTask = tasks[index];
        final updatedComments = List<CommentEntity>.from(oldTask.comments)
          ..add(
            CommentEntity(
              content: text,
              addedBy: _session.currentUserName,
              addedOn: DateTime.now(),
              id: DateTime.now().millisecondsSinceEpoch, // ← كان .millisecond (0-999 فقط، قابل للتصادم)
              featureId: taskId,
              isRead: true,
            ),
          );

        tasks[index] = oldTask.copyWith(
          comments: updatedComments,
        );

        update();
      }

      inputController.clear();
      inputFocus.unfocus();
      update();
    },
  );
}

  Future<void> _loadBusinesses() async {
    if (businesses.isNotEmpty) return; // كاش بسيط
    isLoadingBusinesses = true;
    update();

    final result = await _getBusinesses();
    result.fold(
      (failure) => errorMessage = failure.toString(),
      (list) => businesses = list,
    );

    isLoadingBusinesses = false;
    update();
  }

  Future<void> _loadGlobalSystems() async {
    if (globalSystems.isNotEmpty) return;
    isLoadingGlobalSystems = true;
    update();

    final result = await _getGlobalSystems();
    result.fold(
      (failure) => errorMessage = failure.toString(),
      (list) => globalSystems = list,
    );

    isLoadingGlobalSystems = false;
    update();
  }

  /// بيتنادى لما المستخدم يختار Business — بيحمّل الـ Services المرتبطة بيه.
  Future<void> selectBusiness(BusinessEntity? business) async {
    selectedBusiness = business;
    selectedService = null; // إعادة ضبط الاختيار التابع
    services = [];
    update();

    if (business == null) return;

    isLoadingServices = true;
    update();

    final result = await _getServices(businessId: business.id);
    result.fold(
      (failure) => errorMessage = failure.toString(),
      (list) => services = list,
    );

    isLoadingServices = false;
    update();
  }

  void selectService(ServiceEntity? service) {
    selectedService = service;
    update();
  }

  void selectGlobalSystem(GlobalSystemEntity? system) {
    selectedGlobalSystem = system;
    update();
  }

  final TaskStatus status;
  final GetTasksUseCase _getTasks;
  final List<TaskEntity> tasks = [];
  TaskEntity? task;
  bool isLoading = false;
  bool isSending = false;
  bool isLoadingMore = false;
  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocus = FocusNode();
  bool isCommentsLoading = false;
  Failure? commentsFailure;
  Failure? failure;
  final ScrollController scrollController = ScrollController();
  int _page = 0;
  bool _hasMore = true;
  String? _search;

  bool get hasMore => _hasMore;
  bool get isEmpty => tasks.isEmpty && !isLoading && failure == null;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadFirstPage();
    loadLookups();
  }

  @override
  void onClose() {
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    bodyController.dispose();
    commentController.dispose();
    super.onClose();
  }

  Future<void> loadFirstPage() async {
    _page = 0;
    _hasMore = true;
    failure = null;
    isLoading = tasks.isEmpty;

    await _fetchNextPage(replace: true);

    isLoading = false;
  }

  Future<void> reload() async {
    _page = 0;
    _hasMore = true;
    failure = null;
    await _fetchNextPage(replace: true);
  }

  /// Loads the next page if there is one and nothing else is in flight.
  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore || isLoading) return;

    isLoadingMore = true;
    await _fetchNextPage(replace: false);
    isLoadingMore = false;
  }

  Future<void> _fetchNextPage({required bool replace}) async {
    final nextPage = _page + 1;

    final result = await _getTasks(
      GetTasksParams(
        status: status,
        page: nextPage,
        limit: AppConfig.defaultPageSize,
        search: _search,
      ),
    );

    result.fold(
      (error) {
        AppLogger.w('Loading ${status.apiValue} page $nextPage failed: $error');
        if (replace || tasks.isEmpty) {
          failure = error;
          if (replace) tasks.clear();
        } else {
          _paginationError = error;
        }
      },
      (page) {
        _page = page.page;
        _hasMore = page.hasMore;
        failure = null;
        update();

        if (replace) {
          tasks.assignAll(page.items);
        } else {
          final known = tasks.map((task) => task.id).toSet();
          tasks.addAll(page.items.where((task) => !known.contains(task.id)));
        }
      },
    );
  }

  bool isChangingStatus = false;

  // Future<bool> changeStatusFor(int taskId, TaskStatus newStatus) async {
  //   final previousStatus = status; // حالة التاب الحالي (اللي فاتح منه التفاصيل)

  //   isChangingStatus = true;
  //   errorMessage = null;
  //   update();

  //   final result = switch (newStatus) {
  //     TaskStatus.closed => await _setStatusClosed(taskId),
  //     TaskStatus.completed => await _setStatusCompleted(taskId),
  //     _ => await _updateTaskStatusGeneric(taskId, newStatus),
  //   };

  //   isChangingStatus = false;

  //   return result.fold(
  //     (failure) {
  //       errorMessage = failure.toString();
  //       update();
  //       return false;
  //     },
  //     (updatedTask) {
  //       // التاسك اتغيرت حالته — لو الحالة الجديدة مختلفة عن تاب الليستة الحالي،
  //       // لازم يتشال من هنا ويتحط في التاب الصح.
  //       if (updatedTask.status != previousStatus) {
  //         removeTask(taskId); // موجودة عندك بالفعل
  //       } else {
  //         upsertTask(updatedTask);
  //       }
  //       update();

  //       // إعلام باقي التابات عشان تتزامن (زي ما بيحصل في onTaskStatusChanged)
  //       if (Get.isRegistered<HomeController>()) {
  //         Get.find<HomeController>().onTaskStatusChanged(
  //           task: updatedTask,
  //           previousStatus: previousStatus,
  //         );
  //       }

  //       return true;
  //     },
  //   );
  // }

  Future<bool> changeStatusFor(int taskId, TaskStatus newStatus) async {
  final previousStatus = status;

  isChangingStatus = true;
  errorMessage = null;
  update();

  final result = switch (newStatus) {
    TaskStatus.closed => await _setStatusClosed(taskId),
    TaskStatus.completed => await _setStatusCompleted(taskId),
    _ => await _updateTaskStatusGeneric(taskId, newStatus),
  };

  bool success = false;

  await result.fold(
    (failure) async {
      errorMessage = failure.toString();
    },
    (updatedTask) async {
      if (updatedTask.status != previousStatus) {
        await loadFirstPage();
        Get.back();
      } else {
        upsertTask(updatedTask);
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().onTaskStatusChanged(
          task: updatedTask,
          previousStatus: previousStatus,
        );
      }

      success = true;
    },
  );

  isChangingStatus = false;
  update();

  return success;
}

  Future<Either<Failure, TaskEntity>> _updateTaskStatusGeneric(
    int taskId,
    TaskStatus newStatus,
  ) {
    return _changeStatusUseCase(taskId, newStatus);
  }

  Failure? _paginationError;

  Failure? get paginationError => _paginationError;

  void clearPaginationError() => _paginationError = null;

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;
    if (position.pixels >=
        position.maxScrollExtent - position.viewportDimension) {
      loadMore();
    }
  }

  Future<void> applySearch(String? query) async {
    final normalized = (query?.trim().isEmpty ?? true) ? null : query!.trim();
    if (normalized == _search) return;

    _search = normalized;
    tasks.clear();
    await loadFirstPage();
  }

  // ---------------------------------------------------------------------------
  // Cross-screen synchronisation
  // ---------------------------------------------------------------------------

  /// Removes a task that no longer belongs in this tab.
  void removeTask(int taskId) => tasks.removeWhere((task) => task.id == taskId);

  /// Replaces a task in place (e.g. its comment count changed).
  void upsertTask(TaskEntity task) {
    final index = tasks.indexWhere((existing) => existing.id == task.id);
    if (index == -1) {
      if (task.status == status) tasks.insert(0, task);
    } else {
      tasks[index] = task;
    }
    update();
  }

  int? editingTaskId;

  bool get isEditing => editingTaskId != null;

  Future<void> prepareEdit(TaskEntity task) async {
    editingTaskId = task.id;
    bodyController.text = task.body;
    selectedStatus = task.status;
    commentController.clear();

    selectedBusiness = businesses.isNotEmpty
        ? businesses.firstWhereOrNull((b) => b.id == task.business?.id)
        : null;

    // إعادة ضبط الخدمة لحد ما نجيب القايمة الصحيحة
    selectedService = null;
    services = [];
    update(); // يبين الفورم فورًا وspinner للـ Service لو حابب

    if (selectedBusiness != null) {
      isLoadingServices = true;
      update();

      final result = await _getServices(businessId: selectedBusiness!.id);

      result.fold((failure) => errorMessage = failure.toString(), (list) {
        services = list;
        // ✅ هنا بنسند الـ selectedService بعد ما القايمة جاهزة
        selectedService = services.firstWhereOrNull(
          (s) => s.id == task.Service?.id,
        );
      });

      isLoadingServices = false;
    }

    selectedGlobalSystem = globalSystems.isNotEmpty
        ? globalSystems.firstWhereOrNull((g) => g.id == task.globalSystem?.id)
        : null;

    update();
  }

  /// يُستدعى عند فتح الفورم لإنشاء تاسك جديد — يمسح أي بيانات سابقة.
  void prepareCreate() {
    editingTaskId = null;
    bodyController.clear();
    commentController.clear();
    selectedStatus = status;
    selectedBusiness = null;
    selectedService = null;
    selectedGlobalSystem = null;
    errorMessage = null;
    update();
  }

  Future<bool> submit() async {
    if (bodyController.text.trim().isEmpty) {
      errorMessage = 'من فضلك اكتب عنوان/وصف التاسك';
      update();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    update();

    final result = isEditing
        ? await _updateTask(
            UpdateTaskParams(
              taskId: editingTaskId!,
              body: bodyController.text.trim(),
              status: selectedStatus,
              comment: commentController.text.trim().isEmpty
                  ? null
                  : commentController.text.trim(),
              globalSystemId: selectedGlobalSystem?.id,
              businessId: selectedBusiness?.id,
              serviceId: selectedService?.id,
            ),
          )
        : await _createTask(
            CreateTaskParams(
              body: bodyController.text.trim(),
              status: selectedStatus,
              comment: commentController.text.trim().isEmpty
                  ? null
                  : commentController.text.trim(),
              globalSystemId: selectedGlobalSystem?.id,
              businessId: selectedBusiness?.id,
              serviceId: selectedService?.id,
            ),
          );

    isSaving = false;
    update();

    return result.fold(
      (failure) {
        errorMessage = failure.toString();
        update();
        return false;
      },
      (task) {
        upsertTask(task);
        return true;
      },
    );
  }

  /// يُستدعى من زرار تأكيد الحذف.
  Future<bool> deleteTaskById(int taskId) async {
    final result = await _deleteTask(taskId);
    return result.fold(
      (failure) {
        errorMessage = failure.toString();
        update();
        return false;
      },
      (_) {
        removeTask(taskId); // موجودة عندك بالفعل
        update();
        return true;
      },
    );
  }

  /// Marks the list stale so the next time this tab becomes visible it reloads.
  bool _isStale = false;

  void markStale() => _isStale = true;

  Future<void> reloadIfStale() async {
    if (!_isStale) return;
    _isStale = false;
    await reload();
  }
}
