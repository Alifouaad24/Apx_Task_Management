import 'dart:ui';

import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';

/// Transport-level concerns that apply to *every* request regardless of auth:
/// default headers, locale propagation and a bounded retry for transient
/// connection failures.
class ApiInterceptor extends Interceptor {
  ApiInterceptor({this.maxRetries = 2});

  /// How many times a *safe* request may be retried after a connection error.
  final int maxRetries;

  static const _retryCountKey = '_retry_count';

  /// Methods that can be replayed without side effects.
  static const _idempotentMethods = {'GET', 'HEAD', 'OPTIONS'};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers.putIfAbsent(
      ApiConstants.acceptHeader,
      () => ApiConstants.jsonContentType,
    );

    // Only set a JSON content type when we are actually sending JSON —
    // FormData must keep its multipart boundary header.
    if (options.data != null && options.data is! FormData) {
      options.headers.putIfAbsent(
        ApiConstants.contentTypeHeader,
        () => ApiConstants.jsonContentType,
      );
    }

    options.headers.putIfAbsent(
      ApiConstants.languageHeader,
      () => PlatformDispatcher.instance.locale.languageCode,
    );

    // Strip null query params — Dio would otherwise serialise them as empty
    // values and the backend would filter on an empty string.
    options.queryParameters.removeWhere((_, value) => value == null);

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) return handler.next(err);

    final options = err.requestOptions;
    final attempt = (options.extra[_retryCountKey] as int? ?? 0) + 1;
    options.extra[_retryCountKey] = attempt;

    // Linear back-off: 400ms, 800ms.
    await Future<void>.delayed(Duration(milliseconds: 400 * attempt));

    try {
      final dio = Dio(BaseOptions(baseUrl: options.baseUrl));
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    } catch (_) {
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    final attempts = err.requestOptions.extra[_retryCountKey] as int? ?? 0;
    if (attempts >= maxRetries) return false;
    if (!_idempotentMethods.contains(err.requestOptions.method.toUpperCase())) {
      return false;
    }
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout;
  }
}
