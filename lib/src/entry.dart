/// A cache entry with metadata and type information.
///
/// Backends persist this value without decoding [payload]. [typeId] identifies
/// the codec schema, while [expiresAtEpochMs] and [tags] support expiration and
/// grouped invalidation.
class CacheEntry<E> {
  /// Creates an entry around an already encoded payload.
  const CacheEntry({
    required this.key,
    required this.typeId,
    required this.payload,
    required this.createdAtEpochMs,
    required this.expiresAtEpochMs,
    required this.tags,
  });

  /// The key used to identify the entry within the backend.
  final String key;

  /// The stable schema identifier reported by the codec.
  final String typeId;

  /// The encoded payload ready for storage.
  final E payload;

  /// When this entry was created (epoch milliseconds).
  final int createdAtEpochMs;

  /// The expiration timestamp in epoch milliseconds, or `null` if permanent.
  final int? expiresAtEpochMs;

  /// Tags used for grouped invalidation.
  final Set<String> tags;

  /// Creates a copy, retaining fields whose replacement is `null`.
  CacheEntry copyWith({
    E? payload,
    int? createdAtEpochMs,
    int? expiresAtEpochMs,
    Set<String>? tags,
    String? typeId,
  }) => CacheEntry(
    key: key,
    typeId: typeId ?? this.typeId,
    payload: payload ?? this.payload,
    createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
    expiresAtEpochMs: expiresAtEpochMs ?? this.expiresAtEpochMs,
    tags: tags ?? this.tags,
  );

  /// Checks if this entry has expired relative to [nowEpochMs].
  ///
  /// An entry is expired when an expiration is present and
  /// `nowEpochMs >= expiresAtEpochMs`.
  bool isExpired(int nowEpochMs) {
    final exp = expiresAtEpochMs;
    return exp != null && nowEpochMs >= exp;
  }
}
