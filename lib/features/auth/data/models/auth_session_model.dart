import 'dart:convert';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/auth_session_entity.dart';
import 'user_model.dart';

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
