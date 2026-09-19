import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/features/auth/models/business_model.dart';

// --------------------------------------------------------------------------
// User model
// --------------------------------------------------------------------------

/// A person in the workspace. Also used by profile and tasks.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    this.email = '',
    this.avatarUrl,
    this.jobTitle,
    this.role,
    this.businessId,
    this.serviceId,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  /// Free-text position, e.g. `QA Engineer`.
  final String? jobTitle;

  /// Authorisation role, e.g. `admin` / `member`.
  final String? role;

  /// The business whose tasks this user works on.
  final int? businessId;

  /// The service the task board is scoped to.
  final int? serviceId;

  bool get isAdmin => role?.toLowerCase() == 'admin';

  /// Never empty: falls back to the email when the name is blank.
  String get displayName => name.trim().isEmpty ? email : name;

  /// Accepts the key aliases different backends use.
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    name: (json['name'] ?? json['fullName'] ?? json['displayName'] ?? '')
        .toString(),
    email: json['email']?.toString() ?? '',
    avatarUrl: _nonEmpty(
      json['avatarUrl'] ?? json['avatar'] ?? json['photoUrl'],
    ),
    jobTitle: _nonEmpty(json['jobTitle'] ?? json['title'] ?? json['position']),
    role: _nonEmpty(json['role']),
    businessId: _int(
      json['businessId'] ?? json['business_id'] ?? json['BusinessId'],
    ),
    serviceId: _int(
      json['serviceId'] ??
          json['selectedServiceId'] ??
          json['service_id'] ??
          json['ServiceId'],
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'jobTitle': jobTitle,
    'role': role,
    'businessId': businessId,
    'serviceId': serviceId,
  };

  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static String? _nonEmpty(Object? value) {
    final text = value?.toString();
    return (text == null || text.isEmpty) ? null : text;
  }
}

// --------------------------------------------------------------------------
// Login response model
// --------------------------------------------------------------------------

/// What the login endpoint returns: a token, the signed-in user and the
/// businesses they belong to.
class LoginResponseModel {
  const LoginResponseModel({
    required this.token,
    required this.user,
    this.businesses = const [],
  });

  final String token;
  final UserModel user;
  final List<BusinessModel> businesses;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final token = (json['token'] ?? json['accessToken'] ?? json['access_token'])
        ?.toString();
    if (token == null || token.isEmpty) {
      throw const ServerFailure('Login response did not include a token.');
    }

    final user = json['user'] ?? json['data'] ?? json['profile'];
    if (user is! Map<String, dynamic>) {
      throw const ServerFailure('Login response did not include a user.');
    }

    return LoginResponseModel(
      token: token,
      user: UserModel.fromJson(user),
      businesses: BusinessModel.listFrom(
        json['businesses'] ?? user['businesses'],
      ),
    );
  }
}
