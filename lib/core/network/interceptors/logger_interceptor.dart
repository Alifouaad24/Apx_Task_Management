import 'dart:convert';

import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../constants/app_constants.dart';
import '../../services/logger_service.dart';

/// Pretty-prints requests, responses and errors.
///
/// Sensitive headers are redacted and bodies are truncated so logcat stays
/// readable; the whole interceptor is a no-op in release builds because
/// [AppLogger] filters those out.
class LoggerInterceptor extends Interceptor {
  LoggerInterceptor({this.maxBodyLength = 1500});

  /// Bodies longer than this are cut off with an ellipsis.
  final int maxBodyLength;

  static const _redactedHeaders = {
    ApiConstants.authorizationHeader,
    'cookie',
    'set-cookie',
  };

  /// Request timestamps are stashed on the options so we can report duration.
  static const _startKey = '_started_at';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!AppConfig.enableNetworkLogs) return handler.next(options);

    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;

    final buffer = StringBuffer()
      ..writeln('→ ${options.method} ${options.uri}')
      ..writeln('  headers: ${_sanitize(options.headers)}');

    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('  query: ${options.queryParameters}');
    }
    if (options.data != null) {
      buffer.writeln('  body: ${_truncate(_stringify(options.data))}');
    }

    AppLogger.d(buffer.toString().trimRight());
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!AppConfig.enableNetworkLogs) return handler.next(response);

    AppLogger.d(
      '← ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}${_elapsed(response.requestOptions)}\n'
      '  body: ${_truncate(_stringify(response.data))}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!AppConfig.enableNetworkLogs) return handler.next(err);

    AppLogger.e(
      '✖ ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.method} ${err.requestOptions.uri}'
      '${_elapsed(err.requestOptions)}\n'
      '  message: ${err.message}\n'
      '  body: ${_truncate(_stringify(err.response?.data))}',
    );
    handler.next(err);
  }

  String _elapsed(RequestOptions options) {
    final started = options.extra[_startKey];
    if (started is! int) return '';
    return ' (${DateTime.now().millisecondsSinceEpoch - started}ms)';
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      final isSensitive = _redactedHeaders
          .any((header) => header.toLowerCase() == key.toLowerCase());
      return MapEntry(key, isSensitive ? '••• redacted •••' : value);
    });
  }

  String _stringify(Object? data) {
    if (data == null) return 'null';
    if (data is FormData) {
      final fields = data.fields.map((e) => '${e.key}=${e.value}').join(', ');
      final files = data.files.map((e) => e.key).join(', ');
      return 'FormData(fields: [$fields], files: [$files])';
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  String _truncate(String value) => value.length <= maxBodyLength
      ? value
      : '${value.substring(0, maxBodyLength)}… (${value.length} chars)';
}
