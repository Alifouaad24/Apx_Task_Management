import 'dart:io';

import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Translates low level errors into the app's own error vocabulary.
///
/// Two hops, on purpose:
///   `DioException` → [AppException]  (data source boundary)
///   [AppException] → [Failure]       (repository boundary)
class ErrorHandler {
  const ErrorHandler._();

  /// Pulls the human readable message out of a standard error envelope:
  /// `{"message": "..."}` or `{"error": "..."}` or `{"errors": {...}}`.
  static String _messageFrom(Object? body, String fallback) {
    if (body is Map) {
      for (final key in const ['message', 'error', 'detail', 'title']) {
        final value = body[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String) return first;
      }
    }
    if (body is String && body.trim().isNotEmpty && body.length < 200) {
      return body;
    }
    return fallback;
  }

  /// Extracts the `errors` map for field level validation feedback.
  static Object? _errorsPayload(Object? body) {
    if (body is Map && body['errors'] != null) return body['errors'];
    return body;
  }

  /// `DioException` → [AppException].
  static AppException fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      // Raised when Dio's request/response transformer exceeds its budget —
      // to the user this is indistinguishable from any other timeout.
      case DioExceptionType.transformTimeout:
        return const RequestTimeoutException();

      case DioExceptionType.cancel:
        return const RequestCancelledException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badCertificate:
        return const ServerException('Insecure server certificate.');

      case DioExceptionType.unknown:
        if (error.error is SocketException) return const NetworkException();
        return ServerException(
          error.message ?? 'Unexpected network error.',
        );

      case DioExceptionType.badResponse:
        return _fromStatusCode(error.response);
    }
  }

  static AppException _fromStatusCode(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final body = response?.data;

    switch (status) {
      case 400:
        return ValidationException(
          _messageFrom(body, 'The request was rejected.'),
          statusCode: 400,
          data: _errorsPayload(body),
        );
      case 401:
        return UnauthorizedException(
          _messageFrom(body, 'Your session has expired. Please sign in again.'),
        );
      case 403:
        return ForbiddenException(
          _messageFrom(body, 'You do not have permission to do that.'),
        );
      case 404:
        return NotFoundException(
          _messageFrom(body, 'The requested item was not found.'),
        );
      case 409:
        return ValidationException(
          _messageFrom(body, 'This action conflicts with the current state.'),
          statusCode: 409,
          data: _errorsPayload(body),
        );
      case 422:
        return ValidationException(
          _messageFrom(body, 'Please check the highlighted fields.'),
          data: _errorsPayload(body),
        );
      case 429:
        return ServerException(
          _messageFrom(body, 'Too many requests. Please slow down.'),
          statusCode: 429,
        );
      case 500:
      case 501:
      case 502:
      case 503:
      case 504:
        return ServerException(
          _messageFrom(body, 'The server is having trouble. Try again later.'),
          statusCode: status,
        );
      default:
        return ServerException(
          _messageFrom(body, 'Unexpected server response ($status).'),
          statusCode: status,
        );
    }
  }

  /// [AppException] (or any stray error) → [Failure].
  static Failure toFailure(Object error) {
    if (error is DioException) return toFailure(fromDio(error));

    if (error is UnauthorizedException) return UnauthorizedFailure(error.message);
    if (error is ForbiddenException) return ForbiddenFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is ValidationException) {
      return ValidationFailure(error.message, fieldErrors: error.fieldErrors);
    }
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is RequestTimeoutException) return TimeoutFailure(error.message);
    if (error is RequestCancelledException) return UnknownFailure(error.message);
    if (error is CacheException) return CacheFailure(error.message);
    if (error is ServerException) {
      return ServerFailure(error.message, statusCode: error.statusCode);
    }
    if (error is SocketException) return const NetworkFailure();
    if (error is FormatException) {
      return const ServerFailure('The server returned malformed data.');
    }
    return UnknownFailure(error.toString());
  }
}
