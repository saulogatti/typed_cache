// coverage:ignore-file
import 'package:typed_cache/src/cache_store.dart';
import 'package:typed_cache/typed_cache.dart';

export 'package:typed_cache/src/cache_store.dart' show CacheLogger;

/// Creates a [TypedCache] instance with the given [backend].
///
/// [defaultCodec] defines the encoded payload type `E` and domain type `D`.
/// The system clock and default TTL policy are used.
///
/// By default, expired, mismatched, or undecodable entries are treated as
/// cache misses and are lazily deleted. Set [deleteCorruptedEntries] to
/// `false` to surface type and decoding failures instead. [log] receives
/// best-effort cleanup and invalidation failures.
TypedCache<E, D> createTypedCache<E, D extends Object>({
  required CacheBackend backend,
  required CacheCodec<E, D> defaultCodec,
  CacheLogger? log,
  bool deleteCorruptedEntries = true,
}) => CacheStore(
  backend: backend,
  defaultCodec: defaultCodec,
  logger: log,
  deleteCorruptedEntries: deleteCorruptedEntries,
);

/// Type-safe cache interface for storing and retrieving generic data.
///
/// Each store has one [defaultCodec]. The backend therefore owns encoded
/// [CacheEntry] values of type `E`; this interface stores and returns values
/// of domain type `D`.
///
/// All operations are asynchronous so implementations can use file, database,
/// or remote storage.
abstract interface class TypedCache<E, D extends Object> {
  /// The default codec used for encoding and decoding values.
  CacheCodec<E, D> get defaultCodec;

  /// Removes all entries from the cache.
  Future<void> clear();

  /// Checks if a non-expired entry exists for the given [key].
  ///
  /// Returns true only if the entry exists and hasn't expired.
  Future<bool> contains(String key);

  /// Retrieves a value from cache with type-safe decoding.
  ///
  /// Returns null if not found or if it's expired (unless [allowExpired]
  /// is true). If cleanup is enabled, mismatched and undecodable entries also
  /// produce a cache miss.
  ///
  /// Throws [CacheTypeMismatchException] or [CacheDecodeException] for
  /// mismatched or undecodable entries when cleanup is disabled.
  Future<D?> get(String key, {bool allowExpired = false});

  /// Retrieves all valid, non-expired values from the cache that match the
  /// store's default codec.
  ///
  /// Expired or corrupted entries are ignored and may be lazily deleted.
  ///
  /// Returns a list of decoded values. The list will be empty if no valid
  /// entries are found.
  Future<List<D>> getAll();

  /// Gets a value from the cache or fetches it when missing or expired.
  ///
  /// This is the primary method for cache-aside pattern:
  /// 1. Try to get from cache
  /// 2. If missing/expired, call [fetch] to get fresh data
  /// 3. Store the result with optional [ttl] and [tags]
  ///
  /// When [allowExpiredWhileRevalidating] is `true` and a stale value exists,
  /// the refresh is attempted before that stale value is returned. A
  /// [CacheBackendException] is logged; other errors from [fetch] propagate.
  ///
  /// The returned value is either cached or freshly fetched.
  Future<D> getOrFetch(
    String key, {
    required Future<D> Function() fetch,
    Duration? ttl,
    Set<String> tags,
    bool allowExpiredWhileRevalidating = false,
  });

  /// Gets a value from the cache or fetches and stores it on a miss.
  ///
  /// Fetch and write failures are converted to [CacheBackendException] and
  /// returned in a [Result]. Exceptions while reading an existing value are
  /// not converted by this method.
  Future<Result<D, CacheBackendException>> getOrFetchWithResult(
    String key, {
    required Future<D> Function() fetch,
    Duration? ttl,
    Set<String> tags,
  });

  /// Removes a single entry by key.
  ///
  /// Use [remove] in new code.
  @Deprecated('invalidate is deprecated, use remove instead')
  Future<void> invalidate(String key);

  /// Removes all entries with the given [tag].
  ///
  /// Useful for grouped invalidation (e.g., invalidate all user-related
  /// entries when user logs out).
  ///
  /// A failure while listing keys is propagated. Once keys are known, delete
  /// failures are handled as best-effort cleanup.
  Future<void> invalidateByTag(String tag);

  /// Removes all expired entries from the cache.
  ///
  /// This is a maintenance operation that should be called periodically
  /// to free up storage space. The backend determines if this is efficient
  /// (e.g., a database can use a single DELETE query).
  ///
  /// Returns the number of entries removed. Backend failures are logged and
  /// produce `0`.
  Future<int> purgeExpired();

  /// Stores a value in cache with optional TTL and tags.
  ///
  /// A null [ttl] means no expiration. Zero or negative durations expire
  /// immediately. Throws [CacheKeyEmptyException] for an empty [key] or
  /// [CacheBackendException] if the backend fails.
  Future<void> put(String key, D value, {Duration? ttl, Set<String> tags});

  /// Removes a single entry by key.
  ///
  /// An empty key is reported through the configured logger when available.
  Future<void> remove(String key);
}
