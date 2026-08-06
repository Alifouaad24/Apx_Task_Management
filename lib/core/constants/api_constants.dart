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
  // Headers
  // ---------------------------------------------------------------------------
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
  static const String acceptHeader = 'Accept';
  static const String contentTypeHeader = 'Content-Type';
  static const String languageHeader = 'Accept-Language';
  static const String jsonContentType = 'application/json';

  // ---------------------------------------------------------------------------
  // Auth — POST /auth/login {email, password}
  //        -> {token, refreshToken, expiresIn, user}
  // ---------------------------------------------------------------------------
  static const String login = '/Account/Login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String currentUser = '/auth/me';

  // ---------------------------------------------------------------------------
  // Tasks — GET /tasks?status=&page=&limit= -> {data: [], meta: {}}
  // ---------------------------------------------------------------------------
  static const String tasks = '/Feature';

  /// GET /tasks/{id}
  static String taskDetails(String id) => '/tasks/$id';

  /// PATCH /tasks/{id}/status {status}
  static String taskStatus(String id) => '/tasks/$id/status';

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
