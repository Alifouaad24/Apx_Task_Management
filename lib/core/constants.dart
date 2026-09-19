// --------------------------------------------------------------------------
// App constants
// --------------------------------------------------------------------------

/// Global, compile-time application configuration.
///
/// Values here are intentionally kept free of any Flutter/plugin imports so the
/// file can be referenced from every layer (domain included) without breaking
/// the Clean Architecture dependency rule.
class AppConfig {
  const AppConfig._();

  /// Human readable application name (used in the AppBar / notifications).
  static const String appName = 'APX Tasks';

  /// When `true` the [MockInterceptor] short-circuits every Dio request and
  /// answers with in-memory demo data, so the whole app is explorable without a
  /// backend.
  ///
  /// Defaults to `false` because [ApiConstants.baseUrl] points at a real
  /// server. Run with `--dart-define=USE_MOCK_API=true` to browse the app
  /// against the built-in demo dataset instead (any email + a 6-character
  /// password signs in).
  static const bool useMockApi =
      bool.fromEnvironment('USE_MOCK_API', defaultValue: false);

  /// Toggles the verbose Dio request/response logger.
  static const bool enableNetworkLogs =
      bool.fromEnvironment('ENABLE_NETWORK_LOGS', defaultValue: true);

  /// Toggles Firebase Analytics event reporting.
  static const bool enableAnalytics =
      bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);

  /// Design canvas the UI was drawn against; consumed by ScreenUtil.
  static const double designWidth = 390;
  static const double designHeight = 844;

  /// Default page size used by every paginated list in the app.
  static const int defaultPageSize = 20;

  /// Debounce applied to search / rapid user input.
  static const Duration inputDebounce = Duration(milliseconds: 400);

  /// Minimum time the splash screen stays visible, so the branding does not
  /// flash for a single frame on fast devices.
  static const Duration splashMinimumDuration = Duration(milliseconds: 1200);
}

// --------------------------------------------------------------------------
// Api constants
// --------------------------------------------------------------------------

/// Every network endpoint and transport-level constant lives here.
///
/// The backend contract assumed by this app is documented next to each route
/// so the endpoints can be re-pointed at the real server without spelunking
/// through the data sources.
class ApiConstants {
  const ApiConstants._();

  /// Override at build time: `--dart-define=BASE_URL=https://api.myhost.com`.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://www.apxapi.somee.com/$_api',
  );

    static const String _api = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '/api',
  );

  // ---------------------------------------------------------------------------
  // Timeouts
  // ---------------------------------------------------------------------------
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // ---------------------------------------------------------------------------
  // Auth — POST {email, password} -> {token, user}
  // ---------------------------------------------------------------------------
  static const String login = '/Account/Login';

  /// GET -> {businesses: [...]}. Used when no businesses are stored locally.
  static const String myData = '/Account/GetMyData';
  static const String logout = '/auth/logout';

  // ---------------------------------------------------------------------------
  // Tasks — GET /tasks?status=&page=&limit= -> {data: [], meta: {}}
  // ---------------------------------------------------------------------------
  static const String tasks = '/Feature';

  /// GET /tasks/{id}
  static String taskDetails(String id) => '/tasks/$id';

  /// PATCH /tasks/{id}/status {status}
  static String taskStatus(String id) => '/tasks/$id/status';

  // ---------------------------------------------------------------------------
  // Orders (the task board)
  // ---------------------------------------------------------------------------

  /// Used when the signed-in user carries no service id.
  static const int defaultServiceId = 20;

  /// GET -> [{orderStatusId, statusEn, statusAr, service_id}]
  static String orderStatuses(int serviceId) =>
      '/UniversalOrder/GetAllOrderStatusByService/$serviceId';

  /// GET -> [GlobalOrder]
  static String orders(int businessId, int serviceId) =>
      '/Orders/$businessId/$serviceId';

  /// POST body: see `NewTaskData`.
  static const String addOrder = '/Orders/AddGlobalOrder';

  /// PUT {notes, statusId}
  static String updateOrder(int id) => '/Orders/UpdateETaskOrder/$id';
  static String deleteOrder(int id) => '/Orders/$id';
  static String closeOrder(int id) => '/Orders/SetTaskStatusClosed/$id';
  static String completeOrder(int id) => '/Orders/SetStatusCompleted/$id';

  /// PUT {comment}
  static String addOrderComment(int id) => '/Orders/AddComment/$id';
  static String markOrderCommentsRead(int id) =>
      '/Orders/makeAllCommentsRead/$id';

  // Lookups for the create form.
  static const String assignTypes = '/Orders/GetAllAssignTypes';
  static String businessesForTask(int businessId) =>
      '/Business/GetAllBusinessForTask/$businessId';
  static String customers(int businessId) => '/Customers/$businessId';
  static const String globalSystems = '/GlobalSystem';
  static String users(int businessId) => '/Account/getAllUsers/$businessId';

  // ---------------------------------------------------------------------------
  // Comments — GET/POST /tasks/{taskId}/comments
  //            PATCH/DELETE /comments/{commentId}
  // ---------------------------------------------------------------------------
  static String taskComments(String taskId) => '/tasks/$taskId/comments';
  static String comment(String commentId) => '/comments/$commentId';

  // ---------------------------------------------------------------------------
  // Profile & devices
  // ---------------------------------------------------------------------------
  static const String profile = '/profile';
  static const String notificationSettings = '/profile/notification-settings';

  /// POST /devices/fcm-token {token, platform}
  static const String registerDevice = '/Firebase';

  // ---------------------------------------------------------------------------
  // Query parameter keys
  // ---------------------------------------------------------------------------
  static const String pageParam = 'page';
  static const String limitParam = 'limit';
  static const String statusParam = 'status';
  static const String searchParam = 'search';
}

// --------------------------------------------------------------------------
// App strings
// --------------------------------------------------------------------------

/// User facing copy.
///
/// Centralised so the app can be handed to `flutter_localizations`/`intl`
/// later without hunting for hard-coded strings in widgets.
class AppStrings {
  const AppStrings._();

  // Generic
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String confirm = 'Confirm';
  static const String somethingWentWrong = 'Something went wrong';
  static const String noInternet =
      'No internet connection. Check your network and try again.';

  // Auth
  static const String welcomeBack = 'Welcome back';
  static const String signInSubtitle = 'Sign in to continue to your workspace';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String signIn = 'Sign in';
  static const String signOut = 'Sign out';
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Enter a valid email address';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String signOutConfirmation =
      'You will need to sign in again to access your tasks.';

  // Tasks
  static const String myTasks = 'My Tasks';
  static const String taskDetails = 'Task Details';
  static const String noTasks = 'No tasks here';
  static const String noTasksSubtitle =
      'Tasks with this status will show up here.';
  static const String description = 'Description';
  static const String noDescription = 'No description provided.';
  static const String attachments = 'Attachments';
  static const String assignee = 'Assignee';
  static const String reporter = 'Reporter';
  static const String created = 'Created';
  static const String dueDate = 'Due date';
  static const String updated = 'Updated';
  static const String unassigned = 'Unassigned';
  static const String changeStatus = 'Change status';
  static const String statusUpdated = 'Status updated';
  static const String noTransitions =
      'This task has reached a final status and cannot be moved.';

  // Comments
  static const String comments = 'Comments';
  static const String noComments = 'No comments yet';
  static const String noCommentsSubtitle = 'Be the first to leave a comment.';
  static const String writeComment = 'Write a comment…';
  static const String commentAdded = 'Comment added';
  static const String commentUpdated = 'Comment updated';
  static const String commentDeleted = 'Comment deleted';
  static const String deleteCommentTitle = 'Delete comment?';
  static const String deleteCommentBody =
      'This comment will be permanently removed.';
  static const String editComment = 'Edit comment';

  // Profile
  static const String profile = 'Profile';
  static const String appearance = 'Appearance';
  static const String notifications = 'Notifications';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String themeSystem = 'System';
  static const String pushNotifications = 'Push notifications';
  static const String commentNotifications = 'New comments';
  static const String statusNotifications = 'Status changes';
  static const String assignmentNotifications = 'Task assignments';
  static const String newTaskNotifications = 'New tasks';
  static const String about = 'About';
  static const String version = 'Version';
}

// --------------------------------------------------------------------------
// App routes
// --------------------------------------------------------------------------

/// Named route table. Kept as plain constants (no Flutter import) so services
/// and interceptors can navigate without depending on the widget layer.
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String taskDetails = '/task-details';
  static const String addUpdateTask = '/addUpdateTask';
  static const String profile = '/profile';
}
