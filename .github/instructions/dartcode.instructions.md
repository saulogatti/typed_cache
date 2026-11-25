---
applyTo: "**/*.dart"
---

# Dart instructions for typed_cache

Apply these rules to this Dart package. Flutter application, widget, navigation,
and asset guidance is not applicable unless a task explicitly introduces a
Flutter integration.

## API and architecture

- Keep the public surface centered on `lib/typed_cache.dart`.
- Preserve the boundaries between backend persistence, codec conversion, TTL
  policy, clock access, and cache orchestration.
- Prefer immutable values, composition, and constructor injection.
- Keep generic payload types sound; avoid `dynamic`, broad casts, and force
  unwrapping unless a backend format requires an explicit checked conversion.
- Treat codec `typeId` values as schema versions. Change the identifier after an
  incompatible encoding change.
- A backend persists `CacheEntry` metadata unchanged and owns storage-specific
  behavior only.

## Errors and expiration

- Use the existing typed cache exceptions for public failures.
- Preserve useful stack traces and original errors.
- Do not broaden best-effort cleanup into silent handling for unrelated
  failures.
- Expiration is inclusive at the exact epoch-millisecond timestamp.
- Use an injected `Clock` for deterministic TTL tests.
- Empty-key behavior is intentionally asymmetric: writes throw, while reads and
  removals retain their compatibility behavior.

## Documentation and tests

- Document every public type and member with `///`.
- Lead with a concise summary, then document defaults, nullability,
  preconditions, failures, and cleanup behavior.
- Keep examples executable and imported through the public package entrypoint.
- Add a focused regression test for each behavior change or bug fix.
- Use Arrange-Act-Assert and deterministic fake clocks/backends.
- Update `README.md` and `CHANGELOG.md` when public behavior changes.
- Run `dart format`, `dart analyze`, `dart test`, and `dart doc --dry-run`.
