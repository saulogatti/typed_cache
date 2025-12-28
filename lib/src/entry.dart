/// A cache entry with metadata and type information.
///
/// This is the internal representation stored by the backend. It includes:
/// - The encoded payload (E)
/// - Type identifier for runtime type checking
/// - Timestamps for expiration logic
/// - Optional tags for grouped invalidation
class CacheEntry<E> {
  /// The cache key (unique identifier within the backend).
  final String key;

  /// The codec's typeId (for type mismatch detection).
  final String typeId;

  /// The encoded payload ready for storage.
  final E payload;

  /// When this entry was created (epoch milliseconds).
  final int createdAtEpochMs;

  /// When this entry expires, or null for no expiration (epoch ms).
  final int? expiresAtEpochMs;

  /// Optional tags for grouped invalidation (e.g., 'user:123', 'category:books').
  final Set<String> tags;

  const CacheEntry({
    required this.key,
    required this.typeId,
    required this.payload,
    required this.createdAtEpochMs,
    required this.expiresAtEpochMs,
    required this.tags,
  });

  /// Creates a copy with optionally updated fields (immutable builder).
  CacheEntry copyWith({
    E? payload,
    int? createdAtEpochMs,
    int? expiresAtEpochMs,
    Set<String>? tags,
    String? typeId,
  }) {
    return CacheEntry(
      key: key,
      typeId: typeId ?? this.typeId,
      payload: payload ?? this.payload,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      expiresAtEpochMs: expiresAtEpochMs ?? this.expiresAtEpochMs,
      tags: tags ?? this.tags,
    );
  }

  /// Checks if this entry has expired relative to [nowEpochMs].
  ///
  /// An entry is expired if `expiresAtEpochMs` is set and
  /// `nowEpochMs >= expiresAtEpochMs`.
  bool isExpired(int nowEpochMs) {
    final exp = expiresAtEpochMs;
    return exp != null && nowEpochMs >= exp;
  }
}
