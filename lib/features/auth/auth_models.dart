import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:apx_task_management/core/errors.dart';

part 'auth_models.g.dart';

// --------------------------------------------------------------------------
// User entity
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Auth session entity
// --------------------------------------------------------------------------

/// The result of a successful sign-in: credentials plus the authenticated user.
class AuthSessionEntity extends Equatable {
  const AuthSessionEntity({
    required this.token,
    required this.user,
    this.refreshToken,
    this.expiresInSeconds,
  });

  final String token;
  final UserEntity user;
  final String? refreshToken;

  /// Lifetime of [token] as reported by the server. `null` when the server
  /// relies solely on the JWT's own `exp` claim.
  final int? expiresInSeconds;

  /// Absolute expiry derived from [expiresInSeconds], for convenience.
  DateTime? get expiresAt => expiresInSeconds == null
      ? null
      : DateTime.now().add(Duration(seconds: expiresInSeconds!));

  @override
  List<Object?> get props => [token, refreshToken, expiresInSeconds, user];
}

// --------------------------------------------------------------------------
// User model
// --------------------------------------------------------------------------

/// Data-layer representation of a user.
///
/// Models are DTOs, not entities: they own JSON concerns (key aliases, loose
/// types coming off the wire) and expose [toEntity] to hand a clean value to
/// the domain. That keeps `json_serializable` out of the domain layer entirely.
@JsonSerializable()
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    this.email = '',
    this.avatarUrl,
    this.jobTitle,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Ids arrive as `int` from some backends and `String` from others.
  @JsonKey(fromJson: _asString)
  final String id;

  /// Accepts `name`, `fullName` or `displayName`.
  @JsonKey(readValue: _readName, fromJson: _asString)
  final String name;

  @JsonKey(fromJson: _asStringOrEmpty)
  final String email;

  /// Accepts `avatarUrl`, `avatar` or `photoUrl`.
  @JsonKey(readValue: _readAvatar, fromJson: _asNullableString)
  final String? avatarUrl;

  @JsonKey(readValue: _readJobTitle, fromJson: _asNullableString)
  final String? jobTitle;

  @JsonKey(fromJson: _asNullableString)
  final String? role;

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() => UserEntity(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        jobTitle: jobTitle,
        role: role,
      );

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        name: entity.name,
        email: entity.email,
        avatarUrl: entity.avatarUrl,
        jobTitle: entity.jobTitle,
        role: entity.role,
      );

  /// Tolerant parse used when a nested user block may be missing or malformed.
  static UserModel? tryParse(Object? json) {
    if (json is Map<String, dynamic>) {
      try {
        return UserModel.fromJson(json);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Converters
  // ---------------------------------------------------------------------------
  static String _asString(Object? value) => value?.toString() ?? '';

  static String _asStringOrEmpty(Object? value) => value?.toString() ?? '';

  static String? _asNullableString(Object? value) {
    final result = value?.toString();
    return (result == null || result.isEmpty) ? null : result;
  }

  static Object? _readName(Map<dynamic, dynamic> json, String key) =>
      json['name'] ?? json['fullName'] ?? json['displayName'] ?? '';

  static Object? _readAvatar(Map<dynamic, dynamic> json, String key) =>
      json['avatarUrl'] ?? json['avatar'] ?? json['photoUrl'];

  static Object? _readJobTitle(Map<dynamic, dynamic> json, String key) =>
      json['jobTitle'] ?? json['title'] ?? json['position'];
}

// --------------------------------------------------------------------------
// Auth session model
// --------------------------------------------------------------------------

/// Login/refresh response.
///
/// Hand-written rather than generated: real-world auth endpoints disagree on
/// key names (`token` vs `accessToken`, `expiresIn` vs `expires_in`) and a
/// tolerant parser here is far cheaper than a mapping layer on the server.
class AuthSessionModel {
  const AuthSessionModel({
    required this.token,
    required this.user,
    this.refreshToken,
    this.expiresInSeconds,
    this.expiresAt,
  });

  final DateTime? expiresAt;
  final String token;
  final UserModel user;
  final String? refreshToken;
  final int? expiresInSeconds;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    Object? pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null) return value;
      }
      return null;
    }

    final token = pick(['token', 'accessToken', 'access_token'])?.toString();
    if (token == null || token.isEmpty) {
      throw const ServerException('Login response did not include a token.');
    }

    final expiresAt = _extractExpiry(token);

    final rawUser = pick(['user', 'data', 'profile']);
    final user = UserModel.tryParse(rawUser);
    if (user == null) {
      throw const ServerException('Login response did not include a user.');
    }

    return AuthSessionModel(
      token: token,
      user: user,
      refreshToken: pick(['refreshToken', 'refresh_token'])?.toString(),
      expiresInSeconds: expiresAt == null
          ? null
          : expiresAt.difference(DateTime.now()).inSeconds,
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
    'expiresIn': expiresInSeconds,
    'user': user.toJson(),
  };

  AuthSessionEntity toEntity() => AuthSessionEntity(
    token: token,
    user: user.toEntity(),
    refreshToken: refreshToken,
    expiresInSeconds: expiresInSeconds,
  );

  static  DateTime? _extractExpiry(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) return null;

      final payload = parts[1];

      final normalized = base64Url.normalize(payload);

      final decoded = utf8.decode(base64Url.decode(normalized));

      final json = jsonDecode(decoded);

      final exp = json['exp'];

      if (exp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }
}
