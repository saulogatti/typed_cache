# Changelog

## Unreleased

- Corrected public API documentation and contributor guidance to match the
  current package behavior.

## 0.3.1

- Added an analyzer configuration file.
- Updated the Dart SDK constraint to 3.14.0.

## 0.3.0

- Added `Result` utilities for cache operations.
- Added `getAll` for retrieving valid entries.
- Improved cache retrieval and cleanup paths.
- Updated development dependencies.

## 0.2.1
- Fixed a bug where an empty string could be used as a cache key.
- For compatibility, get, contains, and remove will log a warning instead of throwing an error when given an empty key.

## 0.2.0

- Added `readAll` method to the backend for retrieving all cache entries.

## 0.1.0

- Initial version.
