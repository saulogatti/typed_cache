final class CacheBackendException extends TypedCacheException {
  const CacheBackendException(super.message);
}

final class CacheDecodeException extends TypedCacheException {
  final Object cause;
  final StackTrace stackTrace;

  const CacheDecodeException(
    super.message, {
    required this.cause,
    required this.stackTrace,
  });
}

final class CacheTypeMismatchException extends TypedCacheException {
  const CacheTypeMismatchException(super.message);
}

final class CacheUnsupportedOperation extends TypedCacheException {
  const CacheUnsupportedOperation(super.message);
}

sealed class TypedCacheException implements Exception {
  final String message;
  const TypedCacheException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}
