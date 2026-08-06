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
