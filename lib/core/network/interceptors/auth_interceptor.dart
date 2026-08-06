import 'dart:async';

import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../services/logger_service.dart';
import '../../services/session_manager.dart';

/// Injects the bearer token, performs a **single-flight** silent refresh on
/// `401`, and force-logs-out when the session cannot be recovered.
///
/// Concurrency notes:
///  * If ten requests fail with 401 at the same time, only one refresh call is
///    made — the rest await the same [Completer] and are then replayed.
///  * The refresh call itself goes through a bare Dio instance so it can never
///    re-enter this interceptor and loop forever.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required SessionManager session,
    required Dio refreshClient,
  })  : _session = session,
        _refreshClient = refreshClient;

  final SessionManager _session;
  final Dio _refreshClient;

  /// Set on a request's `extra` to opt out of the bearer header.
  static const String skipAuthKey = 'skip_auth';

  /// Marks a request that has already been replayed once after a refresh.
  static const String _retriedKey = '_auth_retried';

  /// In-flight refresh, shared by every queued 401.
  Completer<String?>? _refreshCompleter;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final skipAuth = options.extra[skipAuthKey] == true;
    final token = _session.accessToken;

    if (!skipAuth && token != null) {
      options.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix} $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;

    // Anything that is not a recoverable 401 passes straight through.
    if (!isUnauthorized ||
        options.extra[skipAuthKey] == true ||
        options.extra[_retriedKey] == true ||
        options.path.contains(ApiConstants.refreshToken)) {
      if (isUnauthorized) {
        await _session.forceLogout(reason: 'unauthorized (${options.path})');
      }
      return handler.next(err);
    }

    // No refresh token → nothing to recover with.
    if (_session.tokens.refreshToken == null) {
      await _session.forceLogout(reason: 'no refresh token');
      return handler.next(err);
    }

    final newToken = await _refreshAccessToken();

    if (newToken == null) {
      await _session.forceLogout(reason: 'refresh failed');
      return handler.next(err);
    }

    // Replay the original request once, with the fresh credential.
    try {
      options
        ..extra[_retriedKey] = true
        ..headers[ApiConstants.authorizationHeader] =
            '${ApiConstants.bearerPrefix} $newToken';

      final response = await _refreshClient.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    } catch (_) {
      return handler.next(err);
    }
  }

  /// Returns the new access token, or `null` when the refresh failed.
  /// Guarantees only one network call regardless of how many callers await it.
  Future<String?> _refreshAccessToken() {
    final pending = _refreshCompleter;
    if (pending != null) return pending.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    _performRefresh().then((token) {
      completer.complete(token);
    }).catchError((Object error) {
      AppLogger.w('Token refresh threw', error);
      completer.complete(null);
    }).whenComplete(() {
      _refreshCompleter = null;
    });

    return completer.future;
  }

  Future<String?> _performRefresh() async {
    AppLogger.i('Access token rejected — attempting silent refresh');

    final response = await _refreshClient.post<dynamic>(
      ApiConstants.refreshToken,
      data: {'refreshToken': _session.tokens.refreshToken},
      options: Options(extra: {skipAuthKey: true}),
    );

    final body = response.data;
    if (body is! Map) return null;

    // Accept both a flat body and a `{data: {...}}` envelope.
    final payload = (body['data'] is Map ? body['data'] as Map : body);

    final token = (payload['token'] ?? payload['accessToken'])?.toString();
    if (token == null || token.isEmpty) return null;

    final refreshToken = payload['refreshToken']?.toString();
    final expiresIn = payload['expiresIn'];

    await _session.tokens.save(
      accessToken: token,
      refreshToken: refreshToken,
      expiresInSeconds: expiresIn is num ? expiresIn.toInt() : null,
    );

    AppLogger.i('Silent refresh succeeded');
    return token;
  }
}
