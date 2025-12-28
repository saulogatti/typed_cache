/// Defines how to encode and decode cache entries.
///
/// A codec is the contract between the domain type (D) and the encoded
/// type (E). This separation allows flexible serialization strategies:
/// - JSON strings, maps, or lists
/// - Binary formats (protobuf, msgpack)
/// - Custom formats optimized for your use case
///
/// Example:
/// ```dart
/// class UserCodec implements CacheCodec<Map<String, dynamic>, User> {
///   @override
///   String get typeId => 'user:v1';
///
///   @override
///   User decode(Map<String, dynamic> data) => User.fromJson(data);
///
///   @override
///   Map<String, dynamic> encode(User user) => user.toJson();
/// }
/// ```
abstract interface class CacheCodec<E, D> {
  /// Stable identifier for this codec's type and schema version.
  ///
  /// This is stored with the cache entry to detect type mismatches.
  /// Examples: 'user:v1', 'product:v2', 'List<int>:v1'
  ///
  /// **Important:** Never change a typeId for existing entries; instead,
  /// increment the version (e.g., 'user:v2'). This prevents silent
  /// corruption when the codec logic changes.
  String get typeId;

  /// Decodes from the backend's encoded format to the domain type.
  ///
  /// Called when retrieving from cache. If decoding fails, throw an
  /// exception; the cache will handle cleanup based on configuration.
  D decode(E data);

  /// Encodes the domain type to the backend's format.
  ///
  /// Called when storing to cache. The result must be serializable by
  /// the backend (JSON, bytes, etc.).
  E encode(D value);
}
