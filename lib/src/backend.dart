import 'entry.dart';

abstract interface class CacheBackend {
  Future<void> clear();

  Future<void> delete(String key);

  /// Remove a tag association from all entries (if supported).
  /// Backend may implement via scan; if not supported, throw.
  Future<void> deleteTag(String tag);

  /// Returns keys for a tag. Backend decides how to store tags.
  Future<Set<String>> keysByTag(String tag);

  /// Optional: efficient expired purge, if backend can query by expiresAt.
  /// Return count removed.
  Future<int> purgeExpired(int nowEpochMs);

  Future<CacheEntry<E>?> read<E>(String key);

  Future<void> write<E>(CacheEntry<E> entry);
}
