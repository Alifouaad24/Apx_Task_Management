import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

// --------------------------------------------------------------------------
// Exceptions
// --------------------------------------------------------------------------

/// Transport/infrastructure level errors.
///
/// Exceptions are thrown by **data sources** only. Repositories catch them and
/// translate them into a [Failure] so the domain layer never sees an exception.
abstract class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;

  /// Raw payload returned by the server, useful for field-level validation.
  final Object? data;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// 5xx, or any response the server could not fulfil.
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode, super.data});
}

/// 401 — token missing, invalid or expired.
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.statusCode = 401, super.data});
}

/// 403 — authenticated but not allowed.
class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.statusCode = 403, super.data});
}

/// 404 — resource does not exist.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.statusCode = 404, super.data});
}

/// 422 / 400 — field level validation errors.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.statusCode = 422, super.data});

  /// `{"email": ["already taken"]}` style map when the server provides one.
  Map<String, List<String>> get fieldErrors {
    final raw = data;
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        value is List
            ? value.map((e) => e.toString()).toList()
            : <String>[value.toString()],
      ),
    );
  }
}

/// The device has no usable internet connection.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// Connect/send/receive timeout.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.message = 'The request timed out']);
}

/// The request was cancelled (e.g. the controller was disposed).
class RequestCancelledException extends AppException {
  const RequestCancelledException([super.message = 'Request cancelled']);
}

/// Reading from / writing to local storage failed.
class CacheException extends AppException {
  const CacheException([super.message = 'Local storage error']);
}

// --------------------------------------------------------------------------
// Failures
// --------------------------------------------------------------------------

/// Domain level error type. Everything that can go wrong is expressed as a
/// [Failure] on the left side of `Either<Failure, T>`.
///
/// Failures never carry exceptions or Dio types — that would leak the data
/// layer into the domain.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.statusCode});

  /// Message that is safe to render directly in the UI.
  final String message;

  /// HTTP status when the failure originated from a response.
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// The server responded with an error (5xx or an unhandled 4xx).
class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    super.statusCode,
  });
}

/// The device is offline or the host is unreachable.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

/// Local storage read/write error.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not read local data.']);
}

/// 401 — the session is no longer valid. The [AuthInterceptor] reacts to this
/// by clearing the session and bouncing the user to the login screen.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]) : super(statusCode: 401);
}

/// 403 — the user is authenticated but lacks permission.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message = 'You do not have permission to perform this action.',
  ]) : super(statusCode: 403);
}

/// 404 — resource not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested item was not found.'])
      : super(statusCode: 404);
}

/// 422/400 — validation errors, optionally per field.
class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    this.fieldErrors = const {},
  }) : super(statusCode: 422);

  final Map<String, List<String>> fieldErrors;

  @override
  List<Object?> get props => [message, statusCode, fieldErrors];
}

/// Connect / receive / send timeout.
class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'The request took too long. Please try again.',
  ]);
}

/// Anything we could not classify.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}

// --------------------------------------------------------------------------
// Error handler
// --------------------------------------------------------------------------

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
