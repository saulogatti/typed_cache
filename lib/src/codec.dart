abstract interface class CacheCodec<E, D> {
  /// Stable identifier for the encoded type/schema.
  /// Examples: 'user:v1', 'profile:v2', 'List:v1'
  String get typeId;

  /// Must decode from what `encode` produced.
  D decode(E data);

  /// Should return JSON-serializable object or bytes-friendly format.
  E encode(D value);
}
