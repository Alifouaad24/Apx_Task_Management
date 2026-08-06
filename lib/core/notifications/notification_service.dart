import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import '../network/api_client.dart';
import '../routes/app_routes.dart';
import '../services/logger_service.dart';
import '../services/session_manager.dart';
import '../storage/storage_service.dart';
import 'notification_channels.dart';
import 'push_payload.dart';

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
      final token = await _messaging!.getToken();
      if (token == null) return null;
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
