/// @docImport 'package:typed_cache/src/errors.dart';
library;

/// Defines how to encode and decode cache entries.
///
/// A codec is the contract between the domain type (D) and the encoded
/// type (E). A backend receives only `E`; this permits storage formats such as:
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
  /// Examples: 'user:v1', 'product:v2', 'List:v1'
  ///
  /// Never reuse a [typeId] after changing an incompatible schema. Increment
  /// the version instead, for example from `user:v1` to `user:v2`.
  String get typeId;

  /// Decodes from the backend's encoded format to the domain type.
  ///
  /// The cache treats a thrown exception as corruption and either deletes the
  /// entry or surfaces a [CacheDecodeException], according to configuration.
  D decode(E data);

  /// Encodes the domain type to the backend's format.
  ///
  /// The result must be a type supported by the configured backend.
  E encode(D value);
}
