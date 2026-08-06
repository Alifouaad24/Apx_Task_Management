import '../constants/app_constants.dart';
import '../constants/storage_keys.dart';
import '../utils/jwt_decoder.dart';
import 'storage_service.dart';


class TokenStorage {
  const TokenStorage(this._storage);

  final StorageService _storage;

  // Read
  String? get accessToken {
    final token = _storage.getString(StorageKeys.accessToken);
    return (token == null || token.isEmpty) ? null : token;
  }

  String? get refreshToken {
    final token = _storage.getString(StorageKeys.refreshToken);
    return (token == null || token.isEmpty) ? null : token;
  }

  DateTime? get expiry {
    final millis = _storage.getInt(StorageKeys.tokenExpiry);
    if (millis != null && millis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return JwtDecoder.expiryOf(accessToken);
  }

  bool get hasToken => accessToken != null;

  bool get isExpired {
    if (!hasToken) return false;
    final expiresAt = expiry;
    if (expiresAt == null) return false;
    return DateTime.now().add(AppConfig.tokenExpiryLeeway).isAfter(expiresAt);
  }

  bool get isValid => hasToken && !isExpired;

  Future<void> save({
    required String accessToken,
    String? refreshToken,
    int? expiresInSeconds,
    DateTime? expiresAt,
  }) async {
    await _storage.setString(StorageKeys.accessToken, accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.setString(StorageKeys.refreshToken, refreshToken);
    }

    final resolvedExpiry = expiresAt ??
        (expiresInSeconds != null && expiresInSeconds > 0
            ? DateTime.now().add(Duration(seconds: expiresInSeconds))
            : JwtDecoder.expiryOf(accessToken));

    if (resolvedExpiry != null) {
      await _storage.setInt(
        StorageKeys.tokenExpiry,
        resolvedExpiry.millisecondsSinceEpoch,
      );
    } else {
      await _storage.remove(StorageKeys.tokenExpiry);
    }
  }

  Future<void> updateAccessToken(
    String token, {
    int? expiresInSeconds,
  }) =>
      save(accessToken: token, expiresInSeconds: expiresInSeconds);

  Future<void> clear() => _storage.removeAll(const [
        StorageKeys.accessToken,
        StorageKeys.refreshToken,
        StorageKeys.tokenExpiry,
      ]);
}
