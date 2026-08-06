import 'dart:convert';

/// Minimal, dependency-free JWT reader.
///
/// Only the payload is inspected — signature verification is the server's job.
/// Used by the [SessionManager] to decide whether a stored token is still
/// usable before the app ever hits the network.
class JwtDecoder {
  const JwtDecoder._();

  /// Decodes the payload segment, or returns `null` when the token is not a
  /// well-formed JWT (opaque tokens are perfectly valid, they just cannot be
  /// introspected locally).
  static Map<String, dynamic>? decode(String? token) {
    if (token == null || token.isEmpty) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      return payload is Map<String, dynamic> ? payload : null;
    } catch (_) {
      return null;
    }
  }

  /// Reads the `exp` claim (seconds since epoch) as a [DateTime].
  static DateTime? expiryOf(String? token) {
    final exp = decode(token)?['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true)
        .toLocal();
  }

  /// `true` only when the token is a JWT **and** its `exp` has passed.
  /// Unknown/opaque tokens return `false` — the server stays the authority.
  static bool isExpired(String? token, {Duration leeway = Duration.zero}) {
    final expiry = expiryOf(token);
    if (expiry == null) return false;
    return DateTime.now().add(leeway).isAfter(expiry);
  }

  /// Reads the subject (user id) claim when present.
  static String? subjectOf(String? token) {
    final sub = decode(token)?['sub'];
    return sub?.toString();
  }
}
