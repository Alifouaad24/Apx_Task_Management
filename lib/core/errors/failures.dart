import 'package:equatable/equatable.dart';

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
