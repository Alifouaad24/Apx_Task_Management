import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/error_handler.dart';
import '../errors/exceptions.dart';
import '../services/session_manager.dart';
import 'interceptors/api_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logger_interceptor.dart';
import 'mock_interceptor.dart';

class ApiClient extends GetxService {
  ApiClient({required SessionManager session}) : _session = session {
    _dio = _buildDio();
  }

  final SessionManager _session;
  late final Dio _dio;

  Dio get dio => _dio;

  Dio _buildDio() {
    final options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      responseType: ResponseType.json,
      headers: const {ApiConstants.acceptHeader: ApiConstants.jsonContentType},

      validateStatus: (status) => status != null && status < 400,
    );

    final dio = Dio(options);

    final refreshClient = Dio(options);
    if (AppConfig.useMockApi) {
      refreshClient.interceptors.add(MockInterceptor());
    }

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
            print("⚠️ SSL certificate bypass for: $host");
            return true;
          };

      return client;
    };

    dio.interceptors.addAll([
      AuthInterceptor(session: _session, refreshClient: refreshClient),
      ApiInterceptor(),
      LoggerInterceptor(),
      if (AppConfig.useMockApi) MockInterceptor(),
    ]);

    return dio;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request(
    () => _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request(
    () => _dio.post<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request(
    () => _dio.put<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<dynamic> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request(
    () => _dio.patch<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request(
    () => _dio.delete<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  /// Runs a Dio call and normalises its failure mode.
  Future<dynamic> _request(Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.fromDio(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

class ApiResponseParser {
  const ApiResponseParser._();

  static Map<String, dynamic> object(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    throw const ServerException('Expected a JSON object from the server.');
  }

  static List<dynamic> list(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'results']) {
        final value = body[key];
        if (value is List) return value;
      }
    }
    throw const ServerException('Expected a JSON array from the server.');
  }

  static Map<String, dynamic> meta(dynamic body) {
    if (body is Map<String, dynamic>) {
      for (final key in const ['meta', 'pagination']) {
        final value = body[key];
        if (value is Map<String, dynamic>) return value;
      }
      return body;
    }
    return const {};
  }
}
