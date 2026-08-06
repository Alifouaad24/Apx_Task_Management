import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

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
