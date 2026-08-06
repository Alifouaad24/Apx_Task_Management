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
