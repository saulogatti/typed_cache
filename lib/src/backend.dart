/// @docImport 'package:typed_cache/src/errors.dart';
/// @docImport 'package:typed_cache/src/typed_cache.dart';
library;

import 'package:typed_cache/src/entry.dart';

/// Abstract interface for pluggable cache backends.
///
/// A backend persists complete [CacheEntry] values and metadata. Encoding the
/// domain value is the codec's responsibility; the backend must not decode the
/// payload or change entry metadata.
abstract interface class CacheBackend {
  /// Removes all entries from the backend.
  Future<void> clear();

  /// Deletes a single entry by key.
  Future<void> delete(String key);

  /// Removes the tag index for [tag].
  ///
  /// Some backends keep a separate index of keys by tag. This method
  /// allows clearing that index. A backend without indexes can make this a
  /// no-op. [TypedCache.invalidateByTag] treats backend failures as
  /// best-effort cleanup.
  Future<void> deleteTag(String tag);

  /// Retrieves all keys associated with [tag].
  ///
  /// Used by [TypedCache.invalidateByTag] to find all entries to delete.
  /// A failure to retrieve this set aborts invalidation.
  /// A backend without tag indexing can return an empty set, but then
  /// [TypedCache.invalidateByTag] cannot locate its entries.
  Future<Set<String>> keysByTag(String tag);

  /// Removes all entries where expiresAt <= [nowEpochMs].
  ///
  /// This is a maintenance operation. The backend can implement this
  /// efficiently using a storage-specific query.
  ///
  /// Returns the count of removed entries. Unsupported backends may return 0.
  Future<int> purgeExpired(int nowEpochMs);

  /// Reads an encoded cache entry by key.
  ///
  /// Returns `null` when the key is absent. A failed read should throw a
  /// [CacheBackendException].
  Future<CacheEntry<E>?> read<E>(String key);

  /// Reads all cache entries for the requested payload type.
  ///
  /// Ordering is backend-defined. A failed read should throw a
  /// [CacheBackendException].
  Future<List<CacheEntry<E>>> readAll<E>();

  /// Writes an encoded cache entry to the backend.
  ///
  /// The entry is already encoded (payload is E, not D). The backend
  /// must persist it as-is, including metadata (createdAt, expiresAt, tags).
  ///
  /// Throws [CacheBackendException] if writing fails.
  Future<void> write<E>(CacheEntry<E> entry);
}
