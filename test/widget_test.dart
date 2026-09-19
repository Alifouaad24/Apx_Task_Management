import 'package:apx_task_management/features/tasks/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the task models — the parts worth pinning down because the
/// rest of the app trusts them to survive whatever the API sends.
void main() {
  group('OrderStatusModel', () {
    final statuses = OrderStatusModel.listFrom([
      {
        'orderStatusId': 11,
        'business': null,
        'business_id': null,
        'service': null,
        'service_id': 20,
        'statusAr': 'جديد',
        'statusEn': 'New',
      },
      {'orderStatusId': 12, 'service_id': 20, 'statusEn': 'On progress'},
      {'orderStatusId': 13, 'service_id': 20, 'statusEn': 'Completed'},
      {'orderStatusId': 14, 'service_id': 20, 'statusEn': 'Closed'},
      {'orderStatusId': 15, 'service_id': 20, 'statusEn': 'Waiting response'},
      {'orderStatusId': 16, 'service_id': 20, 'statusEn': 'Testing'},
      {'statusEn': 'no id — skipped'},
    ]);

    test('parses the service response in order, skipping bad rows', () {
      expect(statuses.map((s) => s.id), [11, 12, 13, 14, 15, 16]);
      expect(statuses.first.nameAr, 'جديد');
      expect(statuses.first.serviceId, 20);
    });

    test('flags the statuses the app treats specially', () {
      expect(statuses[0].isNew, isTrue);
      expect(statuses[2].isCompleted, isTrue);
      expect(statuses[3].isClosed, isTrue);
    });

    test('maps known statuses onto theme colours', () {
      expect(
        statuses.map((s) => s.colorKey),
        [
          'new',
          'in_progress',
          'done',
          'rejected',
          'ready_for_testing',
          'testing',
        ],
      );
    });

    test('compares by id', () {
      expect(
        const OrderStatusModel(id: 11, nameEn: 'New'),
        const OrderStatusModel(id: 11, nameEn: 'renamed'),
      );
    });
  });

  group('TaskModel', () {
    test('parses a GlobalOrder', () {
      final task = TaskModel.fromJson({
        'globalOrderId': 7,
        'notes': 'Fix login',
        'orderStatus': {'orderStatusId': 12, 'statusEn': 'On progress'},
        'business_id': 3,
        'service_id': 20,
        'schedule_dt': '2026-09-20T00:00:00',
        'comments': [
          {'commentContent': 'hi', 'addedBy': 'sara', 'isRead': false},
          {'commentContent': 'ok', 'addedBy': 'ali', 'isRead': true},
        ],
      });

      expect(task.displayKey, '#7');
      expect(task.notes, 'Fix login');
      expect(task.status?.id, 12);
      expect(task.businessId, 3);
      expect(task.scheduleDate, DateTime(2026, 9, 20));
      expect(task.commentsCount, 2);
      expect(task.unreadCommentsCount, 1);
    });

    test('tolerates missing optional fields', () {
      final task = TaskModel.fromJson({'globalOrderId': 1});
      expect(task.notes, isEmpty);
      expect(task.status, isNull);
      expect(task.createdAt, isNull);
      expect(task.comments, isEmpty);
    });

    test('skips malformed tasks instead of failing the list', () {
      final tasks = TaskModel.listFrom([
        {'globalOrderId': 1},
        {'notes': 'no id'},
        'not a map',
      ]);
      expect(tasks.map((t) => t.id), [1]);
    });
  });

  test('NewTaskData uses the AddGlobalOrder keys', () {
    final json = const NewTaskData(
      notes: 'n',
      businessId: 3,
      serviceId: 20,
      statusId: 11,
      customerId: '9',
      assigneeId: 'guid',
    ).toJson();

    expect(json['Business_id'], 3);
    expect(json['Service_id'], 20);
    expect(json['OrderStatusId'], 11);
    expect(json['GlobalCustomerId'], 9);
    expect(json['AssigneeId'], 'guid');
    expect(json['Notes'], 'n');
  });
}
