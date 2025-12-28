import 'entry.dart';

/// Abstract interface for pluggable cache backends.
///
/// Implement this to support different storage mechanisms:
/// - **In-memory**: Fast, non-persistent (good for sessions)
/// - **File-based**: Persistent, moderate speed
/// - **SQLite**: Powerful queries, good for complex scenarios
/// - **Network**: Distributed caching
///
/// Backends must handle serialization/deserialization of [CacheEntry]
/// objects and support optional TTL-based queries.
abstract interface class CacheBackend {
  /// Removes all entries from the backend.
  Future<void> clear();

  /// Deletes a single entry by key.
  Future<void> delete(String key);

  /// Removes the tag index for [tag] (optional optimization).
  ///
  /// Some backends keep a separate index of keys by tag. This method
  /// allows clearing that index. If your backend doesn't support this,
  /// it's safe to throw [CacheUnsupportedOperation].
  Future<void> deleteTag(String tag);

  /// Retrieves all keys associated with a [tag].
  ///
  /// Used by [TypedCache.invalidateByTag] to find all entries to delete.
  /// If your backend doesn't support tags, return an empty set.
  Future<Set<String>> keysByTag(String tag);

  /// Removes all entries where expiresAt <= [nowEpochMs].
  ///
  /// This is a maintenance operation. The backend can implement this
  /// efficiently using queries (e.g., `WHERE expires_at <= ?`).
  ///
  /// Returns the count of removed entries. If not supported, return 0.
  Future<int> purgeExpired(int nowEpochMs);

  /// Reads and decodes a cache entry by key.
  ///
  /// Returns null if not found. Throws [CacheBackendException] if
  /// reading fails (I/O errors, corruption, etc.).
  Future<CacheEntry<E>?> read<E>(String key);

  Future<List<CacheEntry<E>>> readAll<E>();

  /// Writes an encoded cache entry to the backend.
  ///
  /// The entry is already encoded (payload is E, not D). The backend
  /// must persist it as-is, including metadata (createdAt, expiresAt, tags).
  ///
  /// Throws [CacheBackendException] if writing fails.
  Future<void> write<E>(CacheEntry<E> entry);
}
