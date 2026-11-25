/// @docImport 'package:typed_cache/typed_cache.dart';
///
/// A type-safe, backend-agnostic cache library for Dart.
///
/// The package coordinates codecs, expiration metadata, corruption cleanup,
/// and tag invalidation. Storage is supplied by a [CacheBackend]
/// implementation; no built-in backend is provided.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:typed_cache/typed_cache.dart';
///
/// final cache = createTypedCache<String, User>(
///   backend: MyBackend(),
///   defaultCodec: UserCodec(),
/// );
///
/// await cache.put(
///   'user:123',
///   user,
///   ttl: const Duration(hours: 1),
///   tags: const {'users'},
/// );
///
/// final cached = await cache.get('user:123');
/// ```
///
/// `User` and `UserCodec` are application types in this example. A codec's
/// stable [CacheCodec.typeId] distinguishes schema versions.
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
