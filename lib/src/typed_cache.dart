import 'package:typed_cache/src/cache_store.dart';
import 'package:typed_cache/typed_cache.dart';

export 'package:typed_cache/src/cache_store.dart' show CacheLogger;

/// Creates a [TypedCache] instance with the given [backend].
///
/// Parameters:
/// - [backend]: The storage backend (required)
/// - [log]: Optional logger for debugging cache operations
/// - [deleteCorruptedEntries]: If true, silently removes corrupted entries
///   instead of throwing exceptions (default: true)
///
/// Returns a fully configured [TypedCache] ready to use.
TypedCache<E, D> createTypedCache<E, D extends Object>({
  required CacheBackend backend,
  required CacheCodec<E, D> defaultCodec,
  CacheLogger? log,
  bool deleteCorruptedEntries = true,
}) {
  return CacheStore(
    backend: backend,
    defaultCodec: defaultCodec,
    logger: log,
    deleteCorruptedEntries: deleteCorruptedEntries,
  );
}

/// Type-safe cache interface for storing and retrieving generic data.
///
/// This interface provides a clean API for cache operations with support for
/// TTL policies, tag-based invalidation, and type-safe generic operations.
///
/// All operations are async to support various backend implementations
/// (file I/O, database, network, etc.).
abstract interface class TypedCache<E, D extends Object> {
  CacheCodec<E, D> get defaultCodec;

  /// Removes all entries from the cache.
  Future<void> clear();

  /// Checks if a non-expired entry exists for the given [key].
  ///
  /// Returns true only if the entry exists and hasn't expired.
  Future<bool> contains(String key);

  /// Retrieves a value from cache with type-safe decoding.
  ///
  /// Parameters:
  /// - [key]: The cache key
  /// - [allowExpired]: If true, returns expired entries (useful for
  ///   stale-while-revalidate patterns)
  ///
  /// Returns null if not found or if it's expired (unless [allowExpired]
  /// is true). Throws [CacheTypeMismatchException] or
  /// [CacheDecodeException] if the stored type doesn't match.
  Future<D?> get(String key, {bool allowExpired = false});

  Future<List<D>?> getAll();

  /// Gets a value from cache or fetches it if missing/expired.
  ///
  /// This is the primary method for cache-aside pattern:
  /// 1. Try to get from cache
  /// 2. If missing/expired, call [fetch] to get fresh data
  /// 3. Store the result with optional [ttl] and [tags]
  ///
  /// Parameters:
  /// - [key]: The cache key
  /// - [fetch]: Function that returns fresh data
  /// - [ttl]: Optional time-to-live for cached value
  /// - [tags]: Optional tags for grouped invalidation
  /// - [allowExpiredWhileRevalidating]: If true, returns expired cache while
  ///   fetching fresh data in the background (stale-while-revalidate)
  ///
  /// Always returns a non-null value (either from cache or freshly fetched).
  Future<D> getOrFetch(
    String key, {
    required Future<D> Function() fetch,
    Duration? ttl,
    Set<String> tags,
    bool allowExpiredWhileRevalidating = false,
  });

  /// Removes a single entry by key.
  ///
  /// This is an alias for [remove] but more explicit about invalidation intent.
  Future<void> invalidate(String key);

  /// Removes all entries with the given [tag].
  ///
  /// Useful for grouped invalidation (e.g., invalidate all user-related
  /// entries when user logs out).
  Future<void> invalidateByTag(String tag);

  /// Removes all expired entries from the cache.
  ///
  /// This is a maintenance operation that should be called periodically
  /// to free up storage space. The backend determines if this is efficient
  /// (e.g., a database can use a single DELETE query).
  ///
  /// Returns the number of entries removed.
  Future<int> purgeExpired();

  /// Stores a value in cache with optional TTL and tags.
  ///
  /// Parameters:
  /// - [key]: The cache key
  /// - [value]: The value to cache
  /// - [ttl]: Optional time-to-live (null = no expiration)
  /// - [tags]: Optional tags for grouped invalidation
  ///
  /// Throws [CacheBackendException] if the backend fails.
  Future<void> put(String key, D value, {Duration? ttl, Set<String> tags});

  /// Removes a single entry by key (see [invalidate] for clarity).
  Future<void> remove(String key);
}
