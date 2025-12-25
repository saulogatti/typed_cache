abstract interface class CacheCodec<T> {
  /// Stable identifier for the encoded type/schema.
  /// Examples: 'user:v1', 'profile:v2', 'List<User>:v1'
  String get typeId;

  /// Must decode from what `encode` produced.
  T decode(Object data);

  /// Should return JSON-serializable object or bytes-friendly format.
  Object encode(T value);
}
