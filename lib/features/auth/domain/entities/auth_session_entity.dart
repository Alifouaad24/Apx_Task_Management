import 'package:equatable/equatable.dart';

import 'user_entity.dart';

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
