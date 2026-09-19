import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/mock_interceptor.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/storage.dart';

// --------------------------------------------------------------------------
// Api client
// --------------------------------------------------------------------------

/// Thin wrapper over Dio. Every method returns the decoded response body and
/// throws on failure; repositories turn that into `Either` with `safeCall`.
class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Accept-Language': PlatformDispatcher.instance.locale.languageCode,
        },
      ),
    );

    // The API host serves a certificate the platform does not trust.
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>
        HttpClient()..badCertificateCallback = (_, __, ___) => true;

    _dio.interceptors.addAll([
      InterceptorsWrapper(onRequest: _addToken, onError: _onError),
      if (AppConfig.enableNetworkLogs && !kReleaseMode)
        LogInterceptor(
          requestHeader: false, // keeps the bearer token out of the logs
          requestBody: true,
          responseBody: true,
          logPrint: (line) => AppLogger.d(line),
        ),
      if (AppConfig.useMockApi) MockInterceptor(),
    ]);
  }

  final AppStorage _storage;
  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      (await _dio.get<dynamic>(path, queryParameters: query)).data;

  Future<dynamic> post(String path, {Object? data}) async =>
      (await _dio.post<dynamic>(path, data: data)).data;

  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async =>
      (await _dio.put<dynamic>(path, data: data, queryParameters: query)).data;

  Future<dynamic> patch(String path, {Object? data}) async =>
      (await _dio.patch<dynamic>(path, data: data)).data;

  Future<dynamic> delete(String path) async =>
      (await _dio.delete<dynamic>(path)).data;

  void _addToken(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// A 401 while signed in means the token is no longer accepted: clear the
  /// session and send the user back to login.
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401 && _storage.isLoggedIn) {
      AppLogger.w('401 on ${error.requestOptions.path} — signing out');
      await _storage.clearSession();
      Get.offAllNamed(AppRoutes.login);
    }
    handler.next(error);
  }
}

// --------------------------------------------------------------------------
// Response helpers
// --------------------------------------------------------------------------

/// Unwraps the `{data: ...}` envelope some endpoints use.
class ApiResponse {
  const ApiResponse._();

  static Map<String, dynamic> object(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      return data is Map<String, dynamic> ? data : body;
    }
    throw const ServerFailure('Expected a JSON object from the server.');
  }

  static List<dynamic> list(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'results']) {
        final value = body[key];
        if (value is List) return value;
      }
    }
    throw const ServerFailure('Expected a JSON list from the server.');
  }
}
