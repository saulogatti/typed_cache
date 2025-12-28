import 'package:typed_cache/src/cache_store.dart';
import 'package:typed_cache/typed_cache.dart';

export 'package:typed_cache/src/cache_store.dart' show CacheLogger;

TypedCache createTypedCache({
  required CacheBackend backend,
  CacheLogger? log,
  bool deleteCorruptedEntries = true,
}) {
  return CacheStore(backend: backend, logger: log, deleteCorruptedEntries: deleteCorruptedEntries);
}

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

  Future<void> remove(String key);
}
