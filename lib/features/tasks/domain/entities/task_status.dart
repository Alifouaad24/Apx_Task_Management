/// The six task statuses, and the rules for moving between them.
///
/// The transition table lives here — in the domain — so the UI cannot invent an
/// illegal move and the server is not the only thing enforcing the workflow.
enum TaskStatus {
  newTask('New', 'New'),
  inProgress('On progress', 'On progress'),
  readyfortesting('Waiting response', 'Waiting response'),
  testing('Testing', 'Testing'),
  completed('Completed', 'Completed'),
  closed('Closed', 'Closed');

  const TaskStatus(this.apiValue, this.label);

  /// Value exchanged with the backend.
  final String apiValue;

  /// Human readable label shown in tabs, chips and the status selector.
  final String label;

  /// Tab order on the dashboard.
  static const List<TaskStatus> tabOrder = [
    TaskStatus.newTask,
    TaskStatus.inProgress,
    TaskStatus.readyfortesting,
    TaskStatus.testing,
    TaskStatus.completed,
    TaskStatus.closed,
  ];

  /// Parses an API value, defaulting to [newTask] so one malformed record can
  /// never crash a list.
  static TaskStatus fromApi(String? value) {
    if (value == null) return TaskStatus.newTask;
    final normalized = value.trim().toLowerCase();
    return TaskStatus.values.firstWhere(
      (status) => status.apiValue.toLowerCase() == normalized,
      orElse: () => TaskStatus.newTask,
    );
  }

  /// The happy-path pipeline: New → In Progress → Ready For Testing →
  /// Testing → Done.
  static const List<TaskStatus> _pipeline = [
    TaskStatus.newTask,
    TaskStatus.inProgress,
    TaskStatus.readyfortesting,
    TaskStatus.testing,
    TaskStatus.completed,
    TaskStatus.closed,
  ];

  /// The next step in the pipeline, or `null` at the end of it.
  TaskStatus? get nextInPipeline {
    final index = _pipeline.indexOf(this);
    if (index == -1 || index == _pipeline.length - 1) return null;
    return _pipeline[index + 1];
  }

  /// Statuses this task may legally move to.
  ///
  /// Per the workflow spec: one step forward along the pipeline, or straight to
  /// [rejected] from anywhere. [rejected] is terminal — relax this list if the
  /// product later needs a "reopen" action.
List<TaskStatus> get allowedTransitions {
  final index = _pipeline.indexOf(this);
  if (index == -1 || index == _pipeline.length - 1) return const [];
  return _pipeline.sublist(index + 1);
}

  bool canTransitionTo(TaskStatus target) =>
      allowedTransitions.contains(target);

  /// `true` when no further movement is possible.
  bool get isTerminal => allowedTransitions.isEmpty;

  bool get isDone => this == TaskStatus.completed;

  bool get isRejected => this == TaskStatus.closed;

  /// How far along the pipeline this status is, as 0.0–1.0. Rejected reports 1
  /// because the task has left the pipeline entirely.
  double get progress {
    if (this == TaskStatus.closed) return 1;
    final index = _pipeline.indexOf(this);
    if (index <= 0) return 0;
    return index / (_pipeline.length - 1);
  }
}
