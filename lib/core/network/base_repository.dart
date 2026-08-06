import 'package:dartz/dartz.dart';

import '../errors/error_handler.dart';
import '../errors/failures.dart';
import '../services/logger_service.dart';
import 'network_info.dart';

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
