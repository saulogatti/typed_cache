# Typed Cache

A type-safe, backend-agnostic cache coordinator for Dart. It separates domain
values from encoded payloads while handling TTL metadata, codec version checks,
corruption cleanup, tags, and cache-aside operations.

## Requirements

```yaml
environment:
  sdk: ^3.14.0
```

## Installation

```bash
dart pub add typed_cache
```

## Usage

`typed_cache` does not ship a production backend. Implement `CacheBackend` for
the required persistence, then provide a codec between its payload and domain
type.

```dart
import 'package:typed_cache/typed_cache.dart';

final cache = createTypedCache<String, User>(
  backend: MyBackend(),
  defaultCodec: const UserCodec(),
);

await cache.put(
  'user:42',
  user,
  ttl: const Duration(minutes: 10),
  tags: const {'users'},
);

final cachedUser = await cache.get('user:42');

final freshUser = await cache.getOrFetch(
  'user:42',
  fetch: () => userRepository.find('42'),
  ttl: const Duration(minutes: 10),
  tags: const {'users'},
);
```

`MyBackend`, `User`, `UserCodec`, and `userRepository` are application
definitions. See [`example/example.dart`](example/example.dart) for the complete
package flow and an illustrative in-memory backend.

### Codecs

Every store uses one default codec:

```dart
final class UserCodec implements CacheCodec<String, User> {
  const UserCodec();

  @override
  String get typeId => 'user:v1';

  @override
  User decode(String data) => User.fromJson(data);

  @override
  String encode(User value) => value.toJson();
}
```

Increment `typeId` after an incompatible encoded schema change. Entries with
another identifier are cache misses and are lazily deleted by default. Disable
`deleteCorruptedEntries` only when type or decode failures must surface.

### Backends

A `CacheBackend` persists `CacheEntry<E>` values, including payload and
metadata. It implements:

- `read` and `readAll` for retrieval.
- `write`, `delete`, and `clear` for mutation.
- `keysByTag` and `deleteTag` for tag invalidation.
- `purgeExpired` for maintenance.

Expiration is checked lazily during reads. Call `purgeExpired` periodically to
reclaim backend storage.

### Cache behavior

- `get` returns `null` for absent or expired values unless `allowExpired` is
  enabled.
- `contains` reports only non-expired entries.
- `getAll` decodes valid, non-expired entries and applies the same cleanup
  behavior as `get`.
- The stale mode of `getOrFetch` attempts a refresh before returning stale
  data; it does not start a detached background task.
- `getOrFetchWithResult` converts fetch and write failures into a `Result`;
  read failures are not converted.
- `invalidateByTag` propagates failures while discovering tagged keys. After the
  key list is available, individual delete failures are logged and index
  cleanup failures are ignored.
- Empty keys throw on `put`. For compatibility, read and removal operations log
  an empty-key warning and continue.

## Architecture

```text
lib/
├── typed_cache.dart
└── src/
    ├── backend.dart
    ├── cache_store.dart
    ├── codec.dart
    ├── entry.dart
    ├── errors.dart
    ├── typed_cache.dart
    ├── policy/
    │   ├── clock.dart
    │   └── ttl_policy.dart
    └── utils/
        └── typed_result.dart
```

## Development

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart doc --dry-run
```

## Contributing

1. Add focused tests for behavior changes.
2. Document public APIs with `///` comments.
3. Preserve backend and codec boundaries.
4. Run formatting, analysis, tests, and documentation checks before opening a
   pull request.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
