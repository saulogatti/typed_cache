class CacheEntry<E> {
  final String key;
  final String typeId;

  /// Backend stores this as JSON string/blob/etc.
  final E payload;

  /// Epoch milliseconds.
  final int createdAtEpochMs;

  /// Epoch milliseconds (nullable => no expiry).
  final int? expiresAtEpochMs;

  /// Optional for tag-based invalidation.
  final Set<String> tags;

  const CacheEntry({
    required this.key,
    required this.typeId,
    required this.payload,
    required this.createdAtEpochMs,
    required this.expiresAtEpochMs,
    required this.tags,
  });

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

  bool isExpired(int nowEpochMs) {
    final exp = expiresAtEpochMs;
    return exp != null && nowEpochMs >= exp;
    // >= means it expires exactly at exp (not after).
  }
}
