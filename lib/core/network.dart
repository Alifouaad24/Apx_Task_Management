import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/mock_interceptor.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/utils.dart';

// --------------------------------------------------------------------------
// Api client
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Network info
// --------------------------------------------------------------------------

/// Abstraction over "does this device actually have internet".
///
/// Repositories depend on the interface, which keeps them testable — the
/// concrete implementation reaches out to real hosts through
/// `internet_connection_checker`.
abstract class NetworkInfo {
  /// Performs a live check (DNS/host reachability, not just a radio flag).
  Future<bool> get isConnected;

  /// Broadcasts connectivity transitions for the offline banner.
  Stream<bool> get onStatusChange;
}

class NetworkInfoImpl extends GetxService implements NetworkInfo {
  NetworkInfoImpl({InternetConnectionChecker? checker})
      : _checker = checker ?? InternetConnectionChecker.instance;

  final InternetConnectionChecker _checker;

  /// Reactive mirror of the last known status, handy for `Obx` widgets.
  final RxBool connected = true.obs;

  StreamSubscription<InternetConnectionStatus>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = _checker.onStatusChange.listen((status) {
      final isOnline = status == InternetConnectionStatus.connected;
      if (connected.value != isOnline) {
        AppLogger.i('Connectivity changed → ${isOnline ? 'online' : 'offline'}');
      }
      connected.value = isOnline;
    });
  }

  @override
  Future<bool> get isConnected async {
    // In mock mode there is no server to reach, so connectivity is irrelevant
    // and a real DNS probe would wrongly block every request on an emulator
    // without internet.
    if (AppConfig.useMockApi) return true;

    try {
      final result = await _checker.hasConnection;
      connected.value = result;
      return result;
    } catch (e) {
      AppLogger.w('Connectivity probe failed, assuming online', e);
      return true;
    }
  }

  @override
  Stream<bool> get onStatusChange => _checker.onStatusChange
      .map((status) => status == InternetConnectionStatus.connected);

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

// --------------------------------------------------------------------------
// Base repository
// --------------------------------------------------------------------------

/// Shared plumbing for every repository implementation.
///
/// Wraps a remote call so that each repository method reduces to a one-liner
/// while still guaranteeing the three rules of this layer:
///   1. connectivity is checked before touching the network;
///   2. no exception escapes — everything becomes a [Failure];
///   3. the return type is always `Future<Either<Failure, T>>`.
mixin RepositoryMixin {
  NetworkInfo get networkInfo;

  /// Executes a remote [call], mapping the outcome onto `Either`.
  ///
  /// Pass [onCacheFallback] to serve stale local data when the device is
  /// offline instead of surfacing a [NetworkFailure].
  Future<Either<Failure, T>> guard<T>(
    Future<T> Function() call, {
    Future<T?> Function()? onCacheFallback,
  }) async {
    if (!await networkInfo.isConnected) {
      if (onCacheFallback != null) {
        try {
          final cached = await onCacheFallback();
          if (cached != null) return Right(cached);
        } catch (e, s) {
          AppLogger.w('Cache fallback failed', e, s);
        }
      }
      return const Left(NetworkFailure());
    }

    try {
      return Right(await call());
    } catch (e, s) {
      final failure = ErrorHandler.toFailure(e);
      AppLogger.e('Repository call failed → $failure', e, s);
      return Left(failure);
    }
  }

  /// Same as [guard] but for purely local work (no connectivity check).
  Future<Either<Failure, T>> guardLocal<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } catch (e, s) {
      final failure = ErrorHandler.toFailure(e);
      AppLogger.e('Local call failed → $failure', e, s);
      return Left(failure);
    }
  }
}

// --------------------------------------------------------------------------
// Pagination parser
// --------------------------------------------------------------------------

/// Builds a [Paginated] from a `{data: [...], meta: {...}}` response.
///
/// Shared by every paginated data source so the (surprisingly fiddly) metadata
/// normalisation exists once: key aliases differ between APIs, and `totalPages`
/// is frequently missing and must be derived.
class PaginationParser {
  const PaginationParser._();

  static Paginated<T> parse<T>(
    dynamic body, {
    required T Function(Map<String, dynamic> json) itemBuilder,
    required int requestedPage,
    required int requestedLimit,
  }) {
    final rawItems = ApiResponseParser.list(body);
    final meta = ApiResponseParser.meta(body);

    final items = <T>[];
    for (final entry in rawItems) {
      if (entry is Map<String, dynamic>) {
        try {
          items.add(itemBuilder(entry));
        } catch (_) {
          // Skip malformed records rather than failing the whole page.
          continue;
        }
      }
    }

    int? readInt(List<String> keys) {
      for (final key in keys) {
        final value = meta[key];
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    final page = readInt(['page', 'currentPage', 'current_page']) ?? requestedPage;
    final limit =
        readInt(['limit', 'perPage', 'per_page', 'pageSize']) ?? requestedLimit;
    final total = readInt(['total', 'totalItems', 'total_count', 'count']) ??
        items.length;

    var totalPages = readInt(['totalPages', 'total_pages', 'lastPage', 'last_page']);
    totalPages ??= limit > 0 ? (total / limit).ceil() : 1;

    return Paginated<T>(
      items: items,
      page: page,
      limit: limit,
      total: total,
      // Guard against a server reporting fewer pages than we are already on.
      totalPages: max(totalPages, items.isEmpty ? 0 : page),
    );
  }
}

// --------------------------------------------------------------------------
// Api interceptor
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Auth interceptor
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// Logger interceptor
// --------------------------------------------------------------------------

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
