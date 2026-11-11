/// A type-safe, pluggable cache library for Dart with TTL policies and
/// flexible encoding support.
///
/// This library provides a clean, modular cache implementation that supports:
/// - Type-safe generic caching with compile-time type checking
/// - Time-to-live (TTL) policies for automatic expiration
/// - Pluggable backends for different storage mechanisms
/// - Flexible codecs for custom serialization/deserialization
/// - Tag-based invalidation for grouped cache entries
///
/// ## Quick Start
///
/// ```dart
/// import 'package:typed_cache/typed_cache.dart';
///
/// // Create a cache with an in-memory backend
/// final cache = createTypedCache(
///   backend: MyBackend(),
/// );
///
/// // Store a value with optional TTL
/// await cache.put(
///   'user:123',
///   user,
///   codec: UserCodec(),
///   ttl: Duration(hours: 1),
/// );
///
/// // Retrieve it back
/// final cached = await cache.get(
///   'user:123',
///   codec: UserCodec(),
/// );
/// ```
///
/// ## Architecture
///
/// The library follows Clean Architecture principles:
/// - **Backend**: Abstract storage layer (in-memory, SQLite, etc.)
/// - **Codec**: Type-safe serialization/deserialization
/// - **TTL Policy**: Configurable expiration logic
/// - **CacheStore**: Main cache implementation
///
library;

export 'src/backend.dart';
export 'src/codec.dart';
export 'src/entry.dart';
export 'src/errors.dart';
export 'src/policy/clock.dart';
export 'src/policy/ttl_policy.dart';
export 'src/typed_cache.dart';
export 'src/utils/typed_result.dart';
