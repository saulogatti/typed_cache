# Copilot instructions for typed_cache

This repository is a Dart package, not a Flutter application. Do not introduce
Flutter UI, state-management, routing, or mobile-app dependencies unless a task
explicitly requires them.

## Package contract

- Keep `lib/typed_cache.dart` as the public export surface.
- Preserve the separation between `CacheBackend`, `CacheCodec`, and
  `CacheStore`.
- A backend persists encoded `CacheEntry<E>` values; a codec owns conversion
  between encoded payloads and domain values.
- One `TypedCache` instance uses one default codec and stable `typeId`.
- Cover TTL, lazy cleanup, type mismatches, tag invalidation, and backend
  failures with focused tests.

## Changes

- Prefer small, backward-compatible changes.
- Add dependencies only for demonstrated package needs, through `dart pub add`
  or `dart pub remove`.
- Keep public types immutable where practical and use constructor injection for
  clocks, policies, codecs, and backends.
- Do not add `setState`, Flutter BLoCs, routers, or application layers.
- Do not silently change public behavior to make documentation simpler.

## Dart style

- Follow `pubspec.yaml` and `analysis_options.yaml`.
- Use sound null safety, descriptive names, package imports, and concise
  functions.
- Document every public API with `///`, explaining contracts and edge cases
  instead of restating names.
- Avoid `print` in library and example code.
- Respect the configured 100-column formatter width.

## Validation

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart doc --dry-run
```

Behavior changes require focused tests. Keep documentation examples synchronized
with the public API.
