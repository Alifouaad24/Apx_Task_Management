import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:apx_task_management/core/services.dart';

// --------------------------------------------------------------------------
// Failures
// --------------------------------------------------------------------------

/// Everything that can go wrong, as the left side of `Either<Failure, T>`.
///
/// It is also an [Exception], so a data source or a model can `throw` one
/// directly and [safeCall] passes it through unchanged.
class Failure implements Exception {
  const Failure(this.message, {this.statusCode});

  /// Safe to show in the UI as-is.
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// The server answered with an error, or with data we could not read.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

/// The device is offline or the host is unreachable.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'The request took too long. Please try again.',
  ]);
}

/// 401. `ApiClient` has already cleared the session by the time this arrives.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]) : super(statusCode: 401);
}

/// 400 / 409 / 422, optionally with per-field messages.
class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    super.statusCode,
    this.fieldErrors = const {},
  });

  /// `{"email": ["already taken"]}`.
  final Map<String, List<String>> fieldErrors;
}

// --------------------------------------------------------------------------
// Safe call
// --------------------------------------------------------------------------

/// Runs [call] and turns any error into a [Failure].
///
/// Every repository method is a one-liner around this.
Future<Either<Failure, T>> safeCall<T>(Future<T> Function() call) async {
  try {
    return Right(await call());
  } catch (e, s) {
    final failure = toFailure(e);
    AppLogger.e('Request failed → $failure', e, s);
    return Left(failure);
  }
}

/// Maps any thrown error onto a [Failure].
Failure toFailure(Object error) {
  if (error is Failure) return error;
  if (error is DioException) return _fromDio(error);
  if (error is SocketException) return const NetworkFailure();
  if (error is FormatException || error is TypeError) {
    return const ServerFailure('The server returned unexpected data.');
  }
  return ServerFailure(error.toString());
}

Failure _fromDio(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.unknown:
      if (error.error is SocketException) return const NetworkFailure();
      if (error.error is Failure) return error.error! as Failure;
      return ServerFailure(error.message ?? 'Unexpected network error.');
    case DioExceptionType.badResponse:
      return _fromResponse(error.response);
    default:
      return ServerFailure(error.message ?? 'Unexpected network error.');
  }
}

Failure _fromResponse(Response<dynamic>? response) {
  final status = response?.statusCode ?? 0;
  final body = response?.data;

  switch (status) {
    case 401:
      return UnauthorizedFailure(
        _messageFrom(body, 'Your session has expired. Please sign in again.'),
      );
    case 400:
    case 409:
    case 422:
      return ValidationFailure(
        _messageFrom(body, 'Please check the highlighted fields.'),
        statusCode: status,
        fieldErrors: _fieldErrorsFrom(body),
      );
    case 403:
      return ServerFailure(
        _messageFrom(body, 'You do not have permission to do that.'),
        statusCode: status,
      );
    case 404:
      return ServerFailure(
        _messageFrom(body, 'The requested item was not found.'),
        statusCode: status,
      );
    default:
      return ServerFailure(
        _messageFrom(body, 'The server is having trouble. Try again later.'),
        statusCode: status,
      );
  }
}

/// Reads `{"message": "..."}`, `{"error": "..."}` or the first of `{"errors"}`.
String _messageFrom(Object? body, String fallback) {
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

Map<String, List<String>> _fieldErrorsFrom(Object? body) {
  final errors = body is Map ? body['errors'] : null;
  if (errors is! Map) return const {};
  return errors.map(
    (key, value) => MapEntry(
      key.toString(),
      value is List
          ? value.map((e) => e.toString()).toList()
          : <String>[value.toString()],
    ),
  );
}
