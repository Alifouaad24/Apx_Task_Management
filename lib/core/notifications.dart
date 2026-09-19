import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/network.dart';
import 'package:apx_task_management/core/services.dart';

// --------------------------------------------------------------------------
// Notification channels
// --------------------------------------------------------------------------

/// The kind of event a push notification represents.
///
/// The backend is expected to send `type` in the FCM **data** payload; the
/// value decides which Android channel is used and where a tap navigates.
enum PushType {
  commentAdded('comment_added'),
  statusChanged('status_changed'),
  taskAssigned('task_assigned'),
  taskCreated('task_created'),
  general('general');

  const PushType(this.value);

  final String value;

  static PushType fromValue(String? raw) => PushType.values.firstWhere(
        (type) => type.value == raw,
        orElse: () => PushType.general,
      );
}

/// Android notification channel definitions.
///
/// Channels must be created at startup — Android caches a channel's importance
/// the first time it is registered, so changing importance later requires a new
/// channel id (hence the explicit `_v1` suffixes).
class NotificationChannels {
  const NotificationChannels._();

  static const AndroidNotificationChannel comments = AndroidNotificationChannel(
    'task_comments_v1',
    'Task comments',
    description: 'Someone commented on a task you follow.',
    importance: Importance.high,
    enableVibration: true,
  );

  static const AndroidNotificationChannel statusChanges =
      AndroidNotificationChannel(
    'task_status_v1',
    'Status changes',
    description: 'A task you follow moved to a new status.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel assignments =
      AndroidNotificationChannel(
    'task_assignments_v1',
    'Task assignments',
    description: 'You were assigned to a task.',
    importance: Importance.max,
    enableVibration: true,
  );

  static const AndroidNotificationChannel newTasks = AndroidNotificationChannel(
    'task_created_v1',
    'New tasks',
    description: 'A new task was created in your workspace.',
    importance: Importance.defaultImportance,
  );

  static const AndroidNotificationChannel general = AndroidNotificationChannel(
    'general_v1',
    'General',
    description: 'Everything else from APX Tasks.',
    importance: Importance.defaultImportance,
  );

  /// Every channel that must exist on the device.
  static const List<AndroidNotificationChannel> all = [
    comments,
    statusChanges,
    assignments,
    newTasks,
    general,
  ];

  /// Maps a push type onto its channel.
  static AndroidNotificationChannel forType(PushType type) => switch (type) {
        PushType.commentAdded => comments,
        PushType.statusChanged => statusChanges,
        PushType.taskAssigned => assignments,
        PushType.taskCreated => newTasks,
        PushType.general => general,
      };
}

// --------------------------------------------------------------------------
// Push payload
// --------------------------------------------------------------------------

/// Typed view over an FCM message.
///
/// Expected data payload from the backend:
/// ```json
/// {
///   "type": "comment_added",
///   "taskId": "142",
///   "commentId": "1042",
///   "title": "Lina commented on APX-142",
///   "body": "I can reproduce it on a Pixel 7."
/// }
/// ```
/// `title`/`body` fall back to the FCM `notification` block when present.
class PushPayload {
  const PushPayload({
    required this.type,
    this.taskId,
    this.commentId,
    this.title,
    this.body,
    this.raw = const {},
  });

  final PushType type;
  final String? taskId;
  final String? commentId;
  final String? title;
  final String? body;
  final Map<String, dynamic> raw;

  factory PushPayload.fromData(
    Map<String, dynamic> data, {
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    String? read(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
      return null;
    }

    return PushPayload(
      type: PushType.fromValue(read(['type', 'notification_type'])),
      taskId: read(['taskId', 'task_id']),
      commentId: read(['commentId', 'comment_id']),
      title: read(['title']) ?? fallbackTitle,
      body: read(['body', 'message']) ?? fallbackBody,
      raw: data,
    );
  }

  /// Rebuilds a payload from the JSON string carried by a local notification.
  factory PushPayload.fromJsonString(String? source) {
    if (source == null || source.isEmpty) {
      return const PushPayload(type: PushType.general);
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return PushPayload.fromData(decoded);
      }
    } catch (_) {
      // Malformed payload — degrade to a plain notification tap.
    }
    return const PushPayload(type: PushType.general);
  }

  /// Serialised form attached to the local notification so the tap handler can
  /// recover the routing information.
  String toJsonString() => jsonEncode({
        ...raw,
        'type': type.value,
        if (taskId != null) 'taskId': taskId,
        if (commentId != null) 'commentId': commentId,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
      });

  /// `true` when tapping should open a task.
  bool get opensTask => taskId != null && taskId!.isNotEmpty;

  /// `true` when the details screen should jump to the comments section.
  bool get opensComments =>
      opensTask &&
      (type == PushType.commentAdded || commentId != null);

  /// Fallback copy when the server sent data only (a silent/data-only push).
  String get resolvedTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return switch (type) {
      PushType.commentAdded => 'New comment',
      PushType.statusChanged => 'Task status changed',
      PushType.taskAssigned => 'You were assigned a task',
      PushType.taskCreated => 'New task created',
      PushType.general => 'APX Tasks',
    };
  }

  String get resolvedBody => (body != null && body!.isNotEmpty)
      ? body!
      : 'Open the app to see the details.';

  /// Stable notification id so an update for the same task replaces the old
  /// notification instead of stacking a duplicate.
  int get notificationId {
    final seed = '${type.value}:${taskId ?? ''}:${commentId ?? ''}';
    return seed.hashCode & 0x7FFFFFFF;
  }
}

// --------------------------------------------------------------------------
// Notification service
// --------------------------------------------------------------------------

/// Handles messages that arrive while the app is in the **background or
/// terminated**.
///
/// Must be a top-level function annotated with `vm:entry-point` — Flutter spins
/// up a fresh isolate for it, which is why Firebase is initialised again here.
/// Android renders the `notification` block itself, so this handler only does
/// bookkeeping (and would be where you'd sync a badge count).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialised on this isolate, or no config available.
  }
  final payload = PushPayload.fromData(
    message.data,
    fallbackTitle: message.notification?.title,
    fallbackBody: message.notification?.body,
  );
  AppLogger.i('Background push received: ${payload.type.value}');
}

/// Handles a *local* notification tap that happens while the app is in the
/// background. Also required to be a top-level entry point.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  AppLogger.i('Background notification tapped: ${response.payload}');
}

/// Everything push related: permissions, channels, FCM wiring, local
/// notification rendering and tap routing.
class NotificationService extends GetxService {
  NotificationService(this._storage, this._session);

  final StorageService _storage;
  final SessionManager _session;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging? _messaging;

  /// Set when the app was launched *from* a notification while terminated.
  /// The splash controller consumes it once the user is known to be signed in.
  PushPayload? _pendingPayload;

  /// Broadcasts every received push so screens can refresh themselves
  /// (e.g. the comments list reloading when a new comment arrives).
  final _messageStream = StreamController<PushPayload>.broadcast();

  Stream<PushPayload> get onMessage => _messageStream.stream;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _firebaseAvailable = false;

  /// Bootstraps the whole notification stack.
  ///
  /// [firebaseAvailable] is `false` when `Firebase.initializeApp` failed (for
  /// example the developer has not dropped in `google-services.json` yet) — the
  /// local notification side still works so the rest of the app is unaffected.
  Future<NotificationService> init({required bool firebaseAvailable}) async {
    _firebaseAvailable = firebaseAvailable;

    await _initLocalNotifications();
    await _createChannels();

    if (!firebaseAvailable) {
      AppLogger.w('Firebase unavailable — push notifications are disabled');
      return this;
    }

    _messaging = FirebaseMessaging.instance;

    await _requestPermission();
    await _wireListeners();
    await _captureInitialMessage();

    // Clear the device registration when the user signs out.
    _session.addTeardownHook(deleteToken);

    return this;
  }

  // ---------------------------------------------------------------------------
  // Local notifications
  // ---------------------------------------------------------------------------
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // requested explicitly via FCM below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
  }

  Future<void> _createChannels() async {
    if (!Platform.isAndroid) return;

    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    for (final channel in NotificationChannels.all) {
      await android.createNotificationChannel(channel);
    }
    AppLogger.i('${NotificationChannels.all.length} notification channels ready');
  }

  // ---------------------------------------------------------------------------
  // Permissions & token
  // ---------------------------------------------------------------------------
  Future<bool> _requestPermission() async {
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      // Android 13+ needs the runtime POST_NOTIFICATIONS grant as well.
      if (Platform.isAndroid) {
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      AppLogger.i('Notification permission: ${settings.authorizationStatus}');
      return granted;
    } catch (e, s) {
      AppLogger.w('Notification permission request failed', e, s);
      return false;
    }
  }

  /// Public entry point for a "turn on notifications" toggle in settings.
  Future<bool> requestPermission() =>
      _messaging == null ? Future.value(false) : _requestPermission();

  Future<void> _wireListeners() async {
    // Foreground: Android does NOT show a system notification automatically,
    // so we render one ourselves through the local plugin.
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_onForegroundMessage),
    );

    // Background → tapped: the app was alive but not visible.
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final payload = _toPayload(message);
        AppLogger.i('Notification opened app: ${payload.type.value}');
        _routeTo(payload);
      }),
    );

    // Keep the backend's device registry in sync.
    _subscriptions.add(
      _messaging!.onTokenRefresh.listen((token) {
        AppLogger.i('FCM token refreshed');
        registerToken(token);
      }),
    );

    // iOS shows foreground notifications natively once this is enabled.
    await _messaging!.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Reads the message that launched the app from a terminated state, plus any
  /// local notification tap that did the same.
  Future<void> _captureInitialMessage() async {
    final initial = await _messaging!.getInitialMessage();
    if (initial != null) {
      _pendingPayload = _toPayload(initial);
      AppLogger.i('App launched from push: ${_pendingPayload!.type.value}');
      return;
    }

    final launchDetails = await _local.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _pendingPayload = PushPayload.fromJsonString(
        launchDetails!.notificationResponse?.payload,
      );
    }
  }

  /// Fetches the FCM token and pushes it to the backend.
  /// Call right after a successful login, once the token can be attributed.
  Future<String?> registerDevice() async {
  if (_messaging == null) return null;

  try {
    // iOS: انتظر APNs token قبل طلب FCM token
    if (Platform.isIOS) {
      String? apnsToken;

      for (int i = 0; i < 10; i++) {
        apnsToken = await _messaging!.getAPNSToken();

        if (apnsToken != null) {
          AppLogger.i('APNs token received');
          break;
        }

        AppLogger.w('Waiting for APNs token... ${i + 1}/10');
        await Future.delayed(const Duration(seconds: 1));
      }

      if (apnsToken == null) {
        AppLogger.w('APNs token is still null');
        return null;
      }
    }

    final token = await _messaging!.getToken();

    if (token == null) {
      AppLogger.w('FCM token is null');
      return null;
    }

    AppLogger.i('FCM token: $token');

    await registerToken(token);

    return token;
  } catch (e, s) {
    AppLogger.w('Could not obtain FCM token', e, s);
    return null;
  }
}

  /// Sends [token] to the backend, skipping the call when nothing changed.
  Future<void> registerToken(String token) async {
    if (_storage.getString(StorageKeys.fcmToken) == token) return;
    if (!_session.isAuthenticated.value) return;
    if (!Get.isRegistered<ApiClient>()) return;
    var userId = _storage.getString(StorageKeys.userId);
    print(' Registering FCM token for user $userId: $token');

    try {
      await Get.find<ApiClient>().post(
        ApiConstants.registerDevice,
        data: {
          'token': token,
          'userId': userId,
        },
      );
      await _storage.setString(StorageKeys.fcmToken, token);
      AppLogger.i('FCM token registered with backend');
    } catch (e) {
      // Never block the user because a device registration failed.
      AppLogger.w('FCM token registration failed', e);
    }
  }

  /// Drops the device registration (on logout).
  Future<void> deleteToken() async {
    await _storage.remove(StorageKeys.fcmToken);
    try {
      await _messaging?.deleteToken();
    } catch (e) {
      AppLogger.w('FCM token deletion failed', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Message handling
  // ---------------------------------------------------------------------------
  PushPayload _toPayload(RemoteMessage message) => PushPayload.fromData(
        message.data,
        fallbackTitle: message.notification?.title,
        fallbackBody: message.notification?.body,
      );

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final payload = _toPayload(message);
    AppLogger.i('Foreground push: ${payload.type.value}');

    _messageStream.add(payload);

    if (await _isMuted(payload.type)) return;

    // iOS already presented it (see setForegroundNotificationPresentationOptions),
    // so only Android needs a locally rendered notification.
    if (Platform.isAndroid) {
      await show(payload);
    }
  }

  /// Renders a local notification for [payload].
  Future<void> show(PushPayload payload) async {
    final channel = NotificationChannels.forType(payload.type);

    await _local.show(
      payload.notificationId,
      payload.resolvedTitle,
      payload.resolvedBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(payload.resolvedBody),
          ticker: payload.resolvedTitle,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload.toJsonString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = PushPayload.fromJsonString(response.payload);
    AppLogger.i('Notification tapped: ${payload.type.value}');
    _routeTo(payload);
  }

  /// Navigates to the screen a notification points at.
  ///
  /// Signed-out users are ignored — the splash/login flow decides where to go,
  /// and the payload stays pending until a session exists.
  void _routeTo(PushPayload payload) {
    if (!payload.opensTask) return;

    if (!_session.isAuthenticated.value) {
      _pendingPayload = payload;
      return;
    }

    Get.toNamed(
      AppRoutes.taskDetails,
      // parameters: {
      //   RouteParams.taskId: payload.taskId!,
      //   if (payload.opensComments) RouteParams.openComments: 'true',
      // },
    );
  }

  /// Returns (and clears) the notification that launched the app, if any.
  PushPayload? consumePendingPayload() {
    final payload = _pendingPayload;
    _pendingPayload = null;
    return payload;
  }

  /// Handles the pending payload, if there is one. Called by the splash
  /// controller after routing the user to Home.
  void handlePendingPayload() {
    final payload = consumePendingPayload();
    if (payload != null) _routeTo(payload);
  }

  // ---------------------------------------------------------------------------
  // User preferences
  // ---------------------------------------------------------------------------

  /// Reads the per-type toggles saved by the profile screen.
  Future<bool> _isMuted(PushType type) async {
    final settings = _storage.getJson(StorageKeys.notificationSettings);
    if (settings == null) return false;

    if (settings['pushEnabled'] == false) return true;

    final key = switch (type) {
      PushType.commentAdded => 'comments',
      PushType.statusChanged => 'statusChanges',
      PushType.taskAssigned => 'assignments',
      PushType.taskCreated => 'newTasks',
      PushType.general => 'general',
    };
    return settings[key] == false;
  }

  /// Removes every delivered notification (e.g. after opening the dashboard).
  Future<void> clearAll() => _local.cancelAll();

  bool get isAvailable => _firebaseAvailable;

  /// Debug helper: renders a notification locally without a server round trip.
  @visibleForTesting
  Future<void> debugShow(PushType type, {String? taskId}) => show(
        PushPayload(
          type: type,
          taskId: taskId,
          title: 'Test notification',
          body: 'Rendered locally for ${type.value}',
        ),
      );

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _messageStream.close();
    super.onClose();
  }
}
