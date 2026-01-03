import 'package:typed_cache/src/cache_store.dart';

/// Thrown when the backend fails (I/O, database, network errors).
///
/// This indicates a serious issue with the storage layer that the
/// application cannot recover from (e.g., disk full, connection lost).
final class CacheBackendException extends TypedCacheException {
  const CacheBackendException(super.message, {required super.stackTrace});
}

/// Thrown when decoding a cache entry fails.
///
/// Includes the original exception and stack trace for debugging.
/// If the cache is configured with [CacheStore.deleteCorruptedEntries], this
/// exception is caught internally and the entry is deleted.
final class CacheDecodeException extends TypedCacheException {
  /// The original exception that caused the decode failure.
  final Object cause;

  const CacheDecodeException(
    super.message, {
    required this.cause,
    required super.stackTrace,
  });
}

/// Thrown when retrieving an entry with a mismatched type.
///
/// This happens when the codec's typeId doesn't match the stored type,
/// indicating a schema change or wrong codec usage. If the cache is
/// configured with [CacheStore.deleteCorruptedEntries], this exception is caught
/// internally and the entry is deleted.
final class CacheTypeMismatchException extends TypedCacheException {
  const CacheTypeMismatchException(super.message, {required super.stackTrace});
}

/// Thrown when an operation is not supported by the backend.
///
/// For example, some backends may not support tag-based queries.
final class CacheUnsupportedOperation extends TypedCacheException {
  const CacheUnsupportedOperation(super.message, {required super.stackTrace});
}

/// Base exception for all cache-related errors.
///
/// Subclass this for specific error scenarios. All exceptions include
/// a descriptive message for debugging.
sealed class TypedCacheException implements Exception {
  final String message;
  final StackTrace stackTrace;
  const TypedCacheException(this.message, {required this.stackTrace});

  @override
  String toString() => '$runtimeType: $message \n$stackTrace';
}
