import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger.
///
/// Wrapped in a static facade so call sites stay short and the underlying
/// implementation (or a crash-reporting sink) can be swapped in one place.
/// Logging is muted in release builds to avoid leaking data through logcat.
class AppLogger {
  const AppLogger._();

  static final Logger _logger = Logger(
    filter: _ReleaseSafeFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Verbose tracing.
  static void t(dynamic message) => _logger.t(message);

  /// Debug detail.
  static void d(dynamic message) => _logger.d(message);

  /// Notable, expected events (navigation, session changes).
  static void i(dynamic message) => _logger.i(message);

  /// Recoverable problems.
  static void w(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  /// Failures the user is likely to notice.
  static void e(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// Unrecoverable failures.
  static void f(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}

/// Emits everything in debug/profile, nothing in release.
class _ReleaseSafeFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => !kReleaseMode;
}
