import 'codec.dart';

abstract interface class TypedCache {
  Future<void> clear();

  Future<bool> contains(String key);

  Future<T?> get<T>(
    String key, {
    required CacheCodec<T> codec,
    bool allowExpired = false,
  });

  Future<T> getOrFetch<T>(
    String key, {
    required CacheCodec<T> codec,
    required Future<T> Function() fetch,
    Duration? ttl,
    Set<String> tags,
    bool allowExpiredWhileRevalidating = false,
  });

  Future<void> invalidate(String key);

  Future<void> invalidateByTag(String tag);

  /// Optional maintenance hook (e.g. remove expired entries).
  Future<int> purgeExpired();

  Future<void> put<T>(
    String key,
    T value, {
    required CacheCodec<T> codec,
    Duration? ttl,
    Set<String> tags,
  });
}
