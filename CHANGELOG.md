## 0.3.0
- add result classes for cache operations
- add bulk operations for get, set, remove, and contains
- Improved performance of cache retrieval by optimizing internal data structures.
- Updated dependencies to the latest versions for better security and performance.


## 0.2.1
- Fixed a bug where an empty string could be used as a cache key.
- For compatibility, get, contains, and remove will log a warning instead of throwing an error when given an empty key.

## 0.2.0
- Added `readAll` method to the backend for retrieving all cache entries.

## 0.1.0

- Initial version..