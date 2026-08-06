import 'dart:math';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../services/logger_service.dart';

/// Answers every request from an in-memory dataset so the app is fully
/// explorable without a backend.
///
/// Enabled by [AppConfig.useMockApi]; build with
/// `--dart-define=USE_MOCK_API=false` to talk to the real API instead.
/// The store is static, so status changes and comment edits persist for the
/// lifetime of the process exactly like a real server would.
class MockInterceptor extends Interceptor {
  MockInterceptor({this.latency = const Duration(milliseconds: 450)});

  /// Simulated round-trip time, so loaders and shimmers are actually visible.
  final Duration latency;

  static final _MockDatabase _db = _MockDatabase.seed();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(latency);

    final method = options.method.toUpperCase();
    final path = _relativePath(options.uri.path);
    final query = options.queryParameters;
    final body = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : <String, dynamic>{};

    try {
      final result = _route(method, path, query, body);
      if (result == null) {
        return handler.reject(
          _error(options, 404, 'Mock route not found: $method $path'),
          true,
        );
      }
      return handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: result.status,
          data: result.body,
        ),
        true,
      );
    } on _MockHttpError catch (e) {
      return handler.reject(_error(options, e.status, e.message), true);
    } catch (e, s) {
      AppLogger.e('Mock interceptor blew up', e, s);
      return handler.reject(_error(options, 500, 'Mock server error'), true);
    }
  }

  /// Strips the base URL's path prefix so routes can be matched against the
  /// endpoint constants.
  ///
  /// Handles a base URL that is just a host (`https://api.host.com/`, whose
  /// path is `/` or empty) as well as one mounted under a prefix
  /// (`https://api.host.com/api/v1`). Always returns a leading slash.
  static String _relativePath(String fullPath) {
    final basePath = Uri.parse(ApiConstants.baseUrl).path;
    final prefix = basePath.replaceAll(RegExp(r'/+$'), '');

    var path = fullPath;
    if (prefix.isNotEmpty && path.startsWith(prefix)) {
      path = path.substring(prefix.length);
    }

    if (!path.startsWith('/')) path = '/$path';
    return path.length > 1 ? path.replaceAll(RegExp(r'/+$'), '') : path;
  }

  DioException _error(RequestOptions options, int status, String message) {
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: status,
        data: {'message': message},
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------
  _MockResult? _route(
    String method,
    String path,
    Map<String, dynamic> query,
    Map<String, dynamic> body,
  ) {
    // ---- Auth ---------------------------------------------------------------
    if (method == 'POST' && path == ApiConstants.login) {
      return _db.login(body);
    }
    if (method == 'POST' && path == ApiConstants.refreshToken) {
      return _db.refresh(body);
    }
    if (method == 'POST' && path == ApiConstants.logout) {
      return _MockResult(200, {'message': 'Signed out'});
    }
    if (method == 'GET' &&
        (path == ApiConstants.currentUser || path == ApiConstants.profile)) {
      return _MockResult(200, {'data': _db.currentUser});
    }
    if (method == 'PATCH' && path == ApiConstants.profile) {
      return _db.updateProfile(body);
    }
    if (method == 'PATCH' && path == ApiConstants.notificationSettings) {
      return _MockResult(200, {'data': body});
    }
    if (method == 'POST' && path == ApiConstants.registerDevice) {
      return _MockResult(200, {'message': 'Device registered'});
    }

    // ---- Tasks --------------------------------------------------------------
    if (method == 'GET' && path == ApiConstants.tasks) {
      return _db.listTasks(query);
    }

    final taskComments = RegExp(r'^/tasks/([^/]+)/comments$').firstMatch(path);
    if (taskComments != null) {
      final taskId = taskComments.group(1)!;
      if (method == 'GET') return _db.listComments(taskId, query);
      if (method == 'POST') return _db.addComment(taskId, body);
    }

    final taskStatus = RegExp(r'^/tasks/([^/]+)/status$').firstMatch(path);
    if (taskStatus != null && (method == 'PATCH' || method == 'PUT')) {
      return _db.updateStatus(taskStatus.group(1)!, body);
    }

    final taskDetails = RegExp(r'^/tasks/([^/]+)$').firstMatch(path);
    if (taskDetails != null && method == 'GET') {
      return _db.taskById(taskDetails.group(1)!);
    }

    // ---- Comments -----------------------------------------------------------
    final comment = RegExp(r'^/comments/([^/]+)$').firstMatch(path);
    if (comment != null) {
      final id = comment.group(1)!;
      if (method == 'PATCH' || method == 'PUT') return _db.editComment(id, body);
      if (method == 'DELETE') return _db.deleteComment(id);
    }

    return null;
  }
}

/// A resolved mock response.
class _MockResult {
  const _MockResult(this.status, this.body);

  final int status;
  final Object? body;
}

/// Thrown inside the mock database to produce a specific HTTP error.
class _MockHttpError implements Exception {
  const _MockHttpError(this.status, this.message);

  final int status;
  final String message;
}

// -----------------------------------------------------------------------------
// In-memory dataset
// -----------------------------------------------------------------------------
class _MockDatabase {
  _MockDatabase._();

  factory _MockDatabase.seed() => _MockDatabase._().._generate();

  final List<Map<String, dynamic>> users = [];
  final List<Map<String, dynamic>> tasks = [];
  final List<Map<String, dynamic>> comments = [];

  late Map<String, dynamic> currentUser;

  int _commentSeq = 1000;
  final Random _random = Random(42); // fixed seed → reproducible dataset

  static const List<String> _statuses = [
    'new',
    'in_progress',
    'ready_for_testing',
    'testing',
    'done',
    'rejected',
  ];

  static const List<String> _priorities = ['low', 'medium', 'high', 'urgent'];

  static const List<String> _titles = [
    'Implement biometric login on Android',
    'Fix crash when opening task from notification',
    'Add pagination to the comments timeline',
    'Migrate token storage to encrypted preferences',
    'Design empty states for every tab',
    'Reduce cold start time below 1.5s',
    'Support offline reading of cached tasks',
    'Add pull-to-refresh on the dashboard',
    'Handle 401 refresh race condition',
    'Localise the app into Arabic',
    'Upgrade Firebase Messaging to v15',
    'Attachment preview for PDF files',
    'Dark theme contrast audit',
    'Track status changes in Analytics',
    'Restore scroll position between tabs',
    'Debounce the task search field',
    'Add unit tests for the task repository',
    'Fix overflow on small screens',
    'Batch mark notifications as read',
    'Improve error copy for network failures',
    'Cache avatars across sessions',
    'Add haptic feedback to status changes',
    'Prevent duplicate comment submissions',
    'Refresh the dashboard after a push arrives',
  ];

  static const List<String> _descriptions = [
    'The current implementation blocks the main thread while decoding the response. '
        'We should move parsing to an isolate and add a regression test that asserts '
        'the frame budget is respected on a mid-tier device.',
    'Reproduced on Android 14 and iOS 17. The stack trace points at a null status '
        'value coming back from the API. Guard the parser and fall back to "new" so '
        'a malformed payload cannot take the screen down.',
    'Product wants the timeline to load in pages of twenty with a "load more" control '
        'at the top of the list. Preserve scroll position when older comments are '
        'prepended.',
    'Acceptance criteria are in the linked spec. Please keep the public API of the '
        'repository unchanged so the other feature teams are not blocked while this '
        'lands behind a flag.',
  ];

  void _generate() {
    // ---- Users --------------------------------------------------------------
    const people = [
      ['u1', 'Yasser Omran', 'yasser.omran@ramaaz.com', 'Mobile Lead'],
      ['u2', 'Lina Haddad', 'lina.haddad@ramaaz.com', 'QA Engineer'],
      ['u3', 'Omar Sallam', 'omar.sallam@ramaaz.com', 'Backend Engineer'],
      ['u4', 'Maya Rahal', 'maya.rahal@ramaaz.com', 'Product Designer'],
      ['u5', 'Tarek Nabil', 'tarek.nabil@ramaaz.com', 'Product Manager'],
    ];

    for (final person in people) {
      users.add({
        'id': person[0],
        'name': person[1],
        'email': person[2],
        'jobTitle': person[3],
        'role': person[0] == 'u1' ? 'admin' : 'member',
        'avatarUrl': null,
      });
    }
    currentUser = users.first;

    // ---- Tasks --------------------------------------------------------------
    final now = DateTime.now();
    for (var i = 0; i < _titles.length; i++) {
      final status = _statuses[i % _statuses.length];
      final createdAt = now.subtract(Duration(days: 30 - i, hours: i * 3 % 24));
      final updatedAt = createdAt.add(Duration(hours: 6 + _random.nextInt(72)));
      final assignee = users[i % users.length];
      final reporter = users[(i + 2) % users.length];

      tasks.add({
        'id': '${100 + i}',
        'key': 'APX-${100 + i}',
        'title': _titles[i],
        'description': _descriptions[i % _descriptions.length],
        'status': status,
        'priority': _priorities[(i * 3) % _priorities.length],
        'assignee': i % 7 == 0 ? null : assignee,
        'reporter': reporter,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'dueDate': now
            .add(Duration(days: (i % 9) - 2))
            .toUtc()
            .toIso8601String(),
        'commentsCount': 0,
        'attachments': i % 4 == 0
            ? [
                {
                  'id': 'a$i',
                  'fileName': 'spec-${100 + i}.pdf',
                  'url': 'https://example.com/files/spec-${100 + i}.pdf',
                  'mimeType': 'application/pdf',
                  'size': 248000 + i * 1024,
                  'uploadedAt': createdAt.toUtc().toIso8601String(),
                },
                {
                  'id': 'b$i',
                  'fileName': 'screenshot-${100 + i}.png',
                  'url':
                      'https://picsum.photos/seed/${100 + i}/800/600',
                  'mimeType': 'image/png',
                  'size': 91000 + i * 512,
                  'uploadedAt': updatedAt.toUtc().toIso8601String(),
                },
              ]
            : <Map<String, dynamic>>[],
      });
    }

    // ---- Comments -----------------------------------------------------------
    const bodies = [
      'Picked this up — should have a PR by end of day.',
      'I can reproduce it on a Pixel 7. Attaching the logs shortly.',
      'Moved to testing, the fix is on the staging build.',
      'Nice catch. Can we also add a regression test for the null case?',
      'Blocked on the API change, I pinged the backend channel.',
      'Verified on both platforms. Looks good to me. ✅',
    ];

    for (final task in tasks) {
      final count = _random.nextInt(4);
      for (var c = 0; c < count; c++) {
        final author = users[(c + task['id'].hashCode.abs()) % users.length];
        final createdAt = DateTime.parse(task['createdAt'] as String)
            .add(Duration(hours: 5 * (c + 1)));
        comments.add({
          'id': '${_commentSeq++}',
          'taskId': task['id'],
          'body': bodies[(c + task['id'].hashCode.abs()) % bodies.length],
          'author': author,
          'createdAt': createdAt.toUtc().toIso8601String(),
          'updatedAt': createdAt.toUtc().toIso8601String(),
          'isEdited': false,
        });
      }
      task['commentsCount'] = count;
    }
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  _MockResult login(Map<String, dynamic> body) {
    final email = (body['email'] ?? '').toString().trim().toLowerCase();
    final password = (body['password'] ?? '').toString();

    if (email.isEmpty || password.isEmpty) {
      throw const _MockHttpError(422, 'Email and password are required.');
    }
    if (password.length < 6) {
      throw const _MockHttpError(401, 'Invalid email or password.');
    }

    // Any known email signs in; anything else becomes a generic demo account.
    currentUser = users.firstWhere(
      (u) => u['email'].toString().toLowerCase() == email,
      orElse: () => users.first,
    );

    return _MockResult(200, {
      'data': {
        'token': _fakeJwt(currentUser['id'].toString()),
        'refreshToken': 'mock-refresh-${currentUser['id']}',
        'expiresIn': 60 * 60 * 8, // 8 hours
        'user': currentUser,
      },
    });
  }

  _MockResult refresh(Map<String, dynamic> body) {
    if ((body['refreshToken'] ?? '').toString().isEmpty) {
      throw const _MockHttpError(401, 'Missing refresh token.');
    }
    return _MockResult(200, {
      'data': {
        'token': _fakeJwt(currentUser['id'].toString()),
        'refreshToken': 'mock-refresh-${currentUser['id']}',
        'expiresIn': 60 * 60 * 8,
      },
    });
  }

  _MockResult updateProfile(Map<String, dynamic> body) {
    currentUser = {...currentUser, ...body};
    final index = users.indexWhere((u) => u['id'] == currentUser['id']);
    if (index != -1) users[index] = currentUser;
    return _MockResult(200, {'data': currentUser});
  }

  /// Builds a structurally valid (unsigned) JWT so [JwtDecoder] has something
  /// realistic to read an `exp` claim from.
  String _fakeJwt(String subject) {
    String encode(Map<String, dynamic> map) {
      final json = map.entries
          .map((e) => '"${e.key}":${e.value is num ? e.value : '"${e.value}"'}')
          .join(',');
      return base64UrlNoPadding('{$json}');
    }

    final header = encode({'alg': 'none', 'typ': 'JWT'});
    final payload = encode({
      'sub': subject,
      'exp': DateTime.now()
              .add(const Duration(hours: 8))
              .millisecondsSinceEpoch ~/
          1000,
    });
    return '$header.$payload.mocksignature';
  }

  static String base64UrlNoPadding(String value) {
    final bytes = value.codeUnits;
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : null;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : null;

      buffer.write(chars[b0 >> 2]);
      buffer.write(chars[((b0 & 0x03) << 4) | ((b1 ?? 0) >> 4)]);
      if (b1 != null) {
        buffer.write(chars[((b1 & 0x0F) << 2) | ((b2 ?? 0) >> 6)]);
      }
      if (b2 != null) buffer.write(chars[b2 & 0x3F]);
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------
  _MockResult listTasks(Map<String, dynamic> query) {
    final status = query[ApiConstants.statusParam]?.toString();
    final search = query[ApiConstants.searchParam]?.toString().toLowerCase();
    final page = int.tryParse('${query[ApiConstants.pageParam] ?? 1}') ?? 1;
    final limit = int.tryParse('${query[ApiConstants.limitParam] ?? 20}') ?? 20;

    var filtered = tasks.where((task) {
      if (status != null && status.isNotEmpty && task['status'] != status) {
        return false;
      }
      if (search != null && search.isNotEmpty) {
        final haystack =
            '${task['title']} ${task['key']} ${task['description']}'
                .toLowerCase();
        if (!haystack.contains(search)) return false;
      }
      return true;
    }).toList();

    // Newest activity first, matching what the dashboard expects.
    filtered.sort((a, b) => (b['updatedAt'] as String)
        .compareTo(a['updatedAt'] as String));

    final total = filtered.length;
    final start = (page - 1) * limit;
    final items = start >= total
        ? <Map<String, dynamic>>[]
        : filtered.sublist(start, min(start + limit, total));

    return _MockResult(200, {
      'data': items,
      'meta': {
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': total == 0 ? 0 : (total / limit).ceil(),
      },
    });
  }

  _MockResult taskById(String id) {
    final task = tasks.firstWhere(
      (t) => t['id'] == id,
      orElse: () => throw const _MockHttpError(404, 'Task not found.'),
    );
    return _MockResult(200, {'data': task});
  }

  _MockResult updateStatus(String id, Map<String, dynamic> body) {
    final status = body['status']?.toString();
    if (status == null || !_statuses.contains(status)) {
      throw const _MockHttpError(422, 'Unknown task status.');
    }

    final index = tasks.indexWhere((t) => t['id'] == id);
    if (index == -1) throw const _MockHttpError(404, 'Task not found.');

    tasks[index] = {
      ...tasks[index],
      'status': status,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    return _MockResult(200, {'data': tasks[index]});
  }

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------
  _MockResult listComments(String taskId, Map<String, dynamic> query) {
    final page = int.tryParse('${query[ApiConstants.pageParam] ?? 1}') ?? 1;
    final limit = int.tryParse('${query[ApiConstants.limitParam] ?? 50}') ?? 50;

    final all = comments.where((c) => c['taskId'] == taskId).toList()
      ..sort((a, b) =>
          (a['createdAt'] as String).compareTo(b['createdAt'] as String));

    final total = all.length;
    final start = (page - 1) * limit;
    final items =
        start >= total ? <Map<String, dynamic>>[] : all.sublist(start, min(start + limit, total));

    return _MockResult(200, {
      'data': items,
      'meta': {
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': total == 0 ? 0 : (total / limit).ceil(),
      },
    });
  }

  _MockResult addComment(String taskId, Map<String, dynamic> body) {
    final text = (body['body'] ?? body['comment'] ?? '').toString().trim();
    if (text.isEmpty) {
      throw const _MockHttpError(422, 'Comment cannot be empty.');
    }
    if (!tasks.any((t) => t['id'] == taskId)) {
      throw const _MockHttpError(404, 'Task not found.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final comment = <String, dynamic>{
      'id': '${_commentSeq++}',
      'taskId': taskId,
      'body': text,
      'author': currentUser,
      'createdAt': now,
      'updatedAt': now,
      'isEdited': false,
    };
    comments.add(comment);

    final index = tasks.indexWhere((t) => t['id'] == taskId);
    tasks[index]['commentsCount'] =
        (tasks[index]['commentsCount'] as int? ?? 0) + 1;

    return _MockResult(201, {'data': comment});
  }

  _MockResult editComment(String id, Map<String, dynamic> body) {
    final text = (body['body'] ?? '').toString().trim();
    if (text.isEmpty) {
      throw const _MockHttpError(422, 'Comment cannot be empty.');
    }

    final index = comments.indexWhere((c) => c['id'] == id);
    if (index == -1) throw const _MockHttpError(404, 'Comment not found.');
    if (comments[index]['author']['id'] != currentUser['id']) {
      throw const _MockHttpError(403, 'You can only edit your own comments.');
    }

    comments[index] = {
      ...comments[index],
      'body': text,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'isEdited': true,
    };
    return _MockResult(200, {'data': comments[index]});
  }

  _MockResult deleteComment(String id) {
    final index = comments.indexWhere((c) => c['id'] == id);
    if (index == -1) throw const _MockHttpError(404, 'Comment not found.');
    if (comments[index]['author']['id'] != currentUser['id']) {
      throw const _MockHttpError(403, 'You can only delete your own comments.');
    }

    final taskId = comments[index]['taskId'];
    comments.removeAt(index);

    final taskIndex = tasks.indexWhere((t) => t['id'] == taskId);
    if (taskIndex != -1) {
      final count = (tasks[taskIndex]['commentsCount'] as int? ?? 1) - 1;
      tasks[taskIndex]['commentsCount'] = count < 0 ? 0 : count;
    }

    return const _MockResult(200, {'message': 'Comment deleted'});
  }
}
