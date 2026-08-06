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

