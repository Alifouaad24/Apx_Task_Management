import 'package:equatable/equatable.dart';

/// A person in the workspace.
///
/// Lives in the auth feature because identity is owned by auth, and is reused
/// by tasks (assignee/reporter) and comments (author) as a shared kernel — a
/// deliberate, documented exception to strict feature isolation, since
/// duplicating the type would mean converting between identical shapes at
/// every boundary.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.name,
    this.email = '',
    this.avatarUrl,
    this.jobTitle,
    this.role,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  /// Free-text position, e.g. `QA Engineer`.
  final String? jobTitle;

  /// Authorisation role, e.g. `admin` / `member`.
  final String? role;

  bool get isAdmin => role?.toLowerCase() == 'admin';

  /// Safe display name for UI that must never render an empty string.
  String get displayName => name.trim().isEmpty ? email : name;

  UserEntity copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? jobTitle,
    String? role,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      jobTitle: jobTitle ?? this.jobTitle,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, name, email, avatarUrl, jobTitle, role];
}
