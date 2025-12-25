import 'codec.dart';

abstract interface class TypedCache {
  Future<void> clear();

  Future<bool> contains(String key);

  Future<D?> get<E, D extends Object>(
    String key, {
    required CacheCodec<E, D> codec,
    bool allowExpired = false,
  });

  Future<D> getOrFetch<E, D extends Object>(
    String key, {
    required CacheCodec<E, D> codec,
    required Future<D> Function() fetch,
    Duration? ttl,
    Set<String> tags,
    bool allowExpiredWhileRevalidating = false,
  });

  Future<void> invalidate(String key);

  Future<void> invalidateByTag(String tag);

  /// Optional maintenance hook (e.g. remove expired entries).
  Future<int> purgeExpired();

  Future<void> put<E, D extends Object>(
    String key,
    D value, {
    required CacheCodec<E, D> codec,
    Duration? ttl,
    Set<String> tags,
  });
}
