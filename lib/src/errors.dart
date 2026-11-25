import 'package:typed_cache/src/cache_store.dart';

/// Thrown when the backend fails (I/O, database, network errors).
///
/// This indicates a serious issue with the storage layer that the
/// application cannot recover from (e.g., disk full, connection lost).
final class CacheBackendException extends TypedCacheException {
  /// Creates a new cache backend exception.
  const CacheBackendException(super.message, {required super.stackTrace});
}

/// Thrown when decoding a cache entry fails.
///
/// Includes the original exception and stack trace for debugging.
/// If the cache is configured with [CacheStore.deleteCorruptedEntries], this
/// exception is caught internally and the entry is deleted.
final class CacheDecodeException extends TypedCacheException {
  /// Creates a new cache decode exception.
  const CacheDecodeException(super.message, {required this.cause, required super.stackTrace});

  /// The original exception that caused the decode failure.
  final Object cause;
}

/// Thrown when a cache operation is attempted with an empty key.
/// Keys must be non-empty strings.
final class CacheKeyEmptyException extends TypedCacheException {
  /// Creates a new cache key empty exception.
  const CacheKeyEmptyException({required super.stackTrace}) : super('Cache key cannot be empty.');
}

/// Thrown when retrieving an entry with a mismatched type.
///
/// This happens when the codec's typeId doesn't match the stored type,
/// indicating a schema change or wrong codec usage. If the cache is
/// configured with [CacheStore.deleteCorruptedEntries], this exception is caught
/// internally and the entry is deleted.
final class CacheTypeMismatchException extends TypedCacheException {
  /// Creates a new cache type mismatch exception.
  const CacheTypeMismatchException(super.message, {required super.stackTrace});
}

/// Thrown when an operation is not supported by the backend.
///
/// For example, some backends may not support tag-based queries.
final class CacheUnsupportedOperation extends TypedCacheException {
  /// Creates a new cache unsupported operation exception.
  const CacheUnsupportedOperation(super.message, {required super.stackTrace});
}

/// Base exception for all cache-related errors.
///
/// Subclass this for specific error scenarios. All exceptions include
/// a descriptive message for debugging.
sealed class TypedCacheException implements Exception {
  const TypedCacheException(this.message, {required this.stackTrace});

  /// The error message.
  final String message;

  /// The stack trace.
  final StackTrace stackTrace;

  @override
  String toString() => '$message \n$stackTrace';
}
