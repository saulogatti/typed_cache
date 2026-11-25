import 'package:typed_cache/src/cache_store.dart';

/// Thrown when a backend operation or a cache-aside fetch fails.
///
/// The original operation's [StackTrace] is retained in [stackTrace].
final class CacheBackendException extends TypedCacheException {
  /// Creates a new cache backend exception.
  const CacheBackendException(super.message, {required super.stackTrace});
}

/// Thrown when decoding a cache entry fails.
///
/// Includes the original exception and stack trace for debugging.
/// With [CacheStore.deleteCorruptedEntries] enabled, the cache deletes the
/// entry and returns a cache miss instead of exposing this exception.
final class CacheDecodeException extends TypedCacheException {
  /// Creates a new cache decode exception.
  const CacheDecodeException(super.message, {required this.cause, required super.stackTrace});

  /// The original exception that caused the decode failure.
  final Object cause;
}

/// Thrown when writing an entry with an empty key.
///
/// Read and removal compatibility behavior is documented by each operation.
final class CacheKeyEmptyException extends TypedCacheException {
  /// Creates a new cache key empty exception.
  const CacheKeyEmptyException({required super.stackTrace}) : super('Cache key cannot be empty.');
}

/// Thrown when retrieving an entry with a mismatched type.
///
/// This happens when the codec's typeId doesn't match the stored type,
/// indicating a schema change or wrong codec usage. With
/// [CacheStore.deleteCorruptedEntries] enabled, the entry is deleted and the
/// operation returns a cache miss instead.
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
/// Subclasses retain a message and stack trace for diagnosis.
sealed class TypedCacheException implements Exception {
  const TypedCacheException(this.message, {required this.stackTrace});

  /// The error message.
  final String message;

  /// The stack trace.
  final StackTrace stackTrace;

  @override
  String toString() => '$message \n$stackTrace';
}
