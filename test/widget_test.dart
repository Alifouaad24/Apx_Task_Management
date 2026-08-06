import 'package:apx_task_management/core/utils/paginated.dart';
import 'package:apx_task_management/features/tasks/domain/entities/task_priority.dart';
import 'package:apx_task_management/features/tasks/domain/entities/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the pure domain rules — the parts worth pinning down because
/// the rest of the app trusts them (the workflow table in particular).
void main() {
  group('TaskStatus', () {
    test('parses API values and falls back safely', () {
      expect(TaskStatus.fromApi('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromApi('READY_FOR_TESTING'), TaskStatus.readyfortesting);
      expect(TaskStatus.fromApi('ready-for-testing'), TaskStatus.readyfortesting);
      expect(TaskStatus.fromApi('nonsense'), TaskStatus.newTask);
      expect(TaskStatus.fromApi(null), TaskStatus.newTask);
    });

    test('allows exactly one step forward along the pipeline', () {
      expect(TaskStatus.newTask.nextInPipeline, TaskStatus.inProgress);
      expect(TaskStatus.inProgress.nextInPipeline, TaskStatus.readyfortesting);
      expect(TaskStatus.readyfortesting.nextInPipeline, TaskStatus.testing);
      expect(TaskStatus.testing.nextInPipeline, TaskStatus.completed);
      expect(TaskStatus.completed.nextInPipeline, isNull);
    });

    test('permits rejection from any non-rejected status', () {
      for (final status in TaskStatus.values) {
        if (status.isRejected) continue;
        expect(
          status.canTransitionTo(TaskStatus.closed),
          isTrue,
          reason: '${status.label} should be rejectable',
        );
      }
    });

    test('blocks skipping ahead and moving backwards', () {
      expect(TaskStatus.newTask.canTransitionTo(TaskStatus.completed), isFalse);
      expect(TaskStatus.testing.canTransitionTo(TaskStatus.newTask), isFalse);
      expect(
        TaskStatus.readyfortesting.canTransitionTo(TaskStatus.inProgress),
        isFalse,
      );
    });

    test('rejected is terminal', () {
      expect(TaskStatus.closed.allowedTransitions, isEmpty);
      expect(TaskStatus.closed.isTerminal, isTrue);
      expect(TaskStatus.completed.isTerminal, isFalse); // may still be rejected
    });

    test('exposes all six statuses as tabs', () {
      expect(TaskStatus.tabOrder.length, 6);
      expect(TaskStatus.tabOrder.toSet(), TaskStatus.values.toSet());
    });
  });

  group('TaskPriority', () {
    test('parses aliases and defaults to medium', () {
      expect(TaskPriority.fromApi('critical'), TaskPriority.urgent);
      expect(TaskPriority.fromApi('minor'), TaskPriority.low);
      expect(TaskPriority.fromApi('unknown'), TaskPriority.medium);
      expect(TaskPriority.fromApi(null), TaskPriority.medium);
    });

    test('orders by urgency', () {
      expect(TaskPriority.urgent.weight, greaterThan(TaskPriority.low.weight));
      expect(TaskPriority.high.needsAttention, isTrue);
      expect(TaskPriority.low.needsAttention, isFalse);
    });
  });

  group('Paginated', () {
    test('reports whether another page exists', () {
      const first = Paginated<int>(
        items: [1, 2],
        page: 1,
        limit: 2,
        total: 5,
        totalPages: 3,
      );
      expect(first.hasMore, isTrue);
      expect(first.nextPage, 2);

      const last = Paginated<int>(
        items: [5],
        page: 3,
        limit: 2,
        total: 5,
        totalPages: 3,
      );
      expect(last.hasMore, isFalse);
    });

    test('map preserves pagination metadata', () {
      const page = Paginated<int>(
        items: [1, 2],
        page: 2,
        limit: 2,
        total: 4,
        totalPages: 2,
      );

      final mapped = page.map((value) => value.toString());

      expect(mapped.items, ['1', '2']);
      expect(mapped.page, 2);
      expect(mapped.total, 4);
      expect(mapped.totalPages, 2);
    });
  });
}
