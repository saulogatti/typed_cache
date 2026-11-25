import 'package:typed_cache/src/backend.dart';
import 'package:typed_cache/src/codec.dart';
import 'package:typed_cache/src/entry.dart';
import 'package:typed_cache/src/errors.dart';
import 'package:typed_cache/src/policy/clock.dart';
import 'package:typed_cache/src/policy/ttl_policy.dart';
import 'package:typed_cache/src/typed_cache.dart';
import 'package:typed_cache/src/utils/typed_result.dart';

/// Signature for cache logging functions.
///
/// The cache invokes it for selected backend, cleanup, and refresh failures.
/// Successful operations are not logged.
typedef CacheLogger = void Function(String message, Object? error, StackTrace? st);

/// Production [TypedCache] implementation.
///
/// Storage is delegated to [CacheBackend], expiration is computed through
/// [TtlPolicy], and time is obtained from [Clock]. Expiration is checked
/// lazily during reads unless the caller explicitly purges entries.
final class CacheStore<E, D extends Object> implements TypedCache<E, D> {
  /// Creates a new cache instance.
  ///
  /// [defaultCodec] applies to every value handled by this store.
  ///
  /// [_clock] and [_ttlPolicy] default to [SystemClock] and
  /// [DefaultTtlPolicy]. They can be replaced when constructing the store
  /// directly, primarily to make time-dependent behavior deterministic in
  /// tests.
  CacheStore({
    required this._backend,
    required this.defaultCodec,
    this._clock = const SystemClock(),
    this._ttlPolicy = const DefaultTtlPolicy(),
    CacheLogger? logger,
    this.deleteCorruptedEntries = true,
  }) : _log = logger;

  final CacheBackend _backend;
  final Clock _clock;
  final TtlPolicy _ttlPolicy;
  final CacheLogger? _log;
  @override
  final CacheCodec<E, D> defaultCodec;

  /// Whether mismatched or undecodable entries are deleted and treated as
  /// misses.
  final bool deleteCorruptedEntries;

  @override
  Future<void> clear() => _backend.clear();
  @override
  Future<bool> contains(String key) async {
    _validKey(key, false);
    final entry = await _backend.read<dynamic>(key);
    if (entry == null) {
      return false;
    }

    final now = _clock.nowEpochMs();
    if (entry.isExpired(now)) {
      return false;
    }

    return true;
  }

  @override
  Future<D?> get(String key, {bool allowExpired = false}) async {
    _validKey(key, false);
    final now = _clock.nowEpochMs();
    CacheEntry<E>? entry;
    try {
      entry = await _backend.read<E>(key);
    } catch (e, st) {
      _log?.call('Backend read failed for key="$key"', e, st);
      throw CacheBackendException('Backend read failed for key="$key": $e', stackTrace: st);
    }
    return await _makeData(entry, allowExpired, now, key);
  }

  @override
  Future<List<D>> getAll() async {
    final listAll = await _backend.readAll<E>();
    if (listAll.isEmpty) {
      return [];
    }

    final now = _clock.nowEpochMs();
    final dataFutures = listAll.map((entry) => _makeData(entry, false, now, entry.key));

    final data = await Future.wait(dataFutures);
    return data.whereType<D>().toList();
  }

  @override
  Future<D> getOrFetch(
    String key, {
    required Future<D> Function() fetch,
    Duration? ttl,
    Set<String> tags = const {},
    bool allowExpiredWhileRevalidating = false,
  }) async {
    final cached = await get(key, allowExpired: allowExpiredWhileRevalidating);

    if (cached != null && !allowExpiredWhileRevalidating) {
      return cached;
    }

    if (cached != null && allowExpiredWhileRevalidating) {
      // Refresh synchronously before returning stale data.
      // Backend refresh errors are logged; other fetch errors propagate.
      try {
        final fresh = await fetch();
        await put(key, fresh, ttl: ttl, tags: tags);
      } catch (e, st) {
        _log?.call('SWR refresh failed for key="$key"', e, st);
      }
      return cached;
    }

    final fresh = await fetch();
    await put(key, fresh, ttl: ttl, tags: tags);
    return fresh;
  }

  @override
  Future<Result<D, CacheBackendException>> getOrFetchWithResult(
    String key, {
    required Future<D> Function() fetch,
    Duration? ttl,
    Set<String> tags = const {},
  }) async {
    final cached = await get(key);

    if (cached != null) {
      return Result.success(cached);
    }

    try {
      final fresh = await fetch();
      await put(key, fresh, ttl: ttl, tags: tags);
      return Result.success(fresh);
    } on CacheBackendException catch (e) {
      return Result.failure(e);
    } on Exception catch (e, st) {
      return Result.failure(
        CacheBackendException('Cache miss for key="$key" failed: $e', stackTrace: st),
      );
    }
  }

  @override
  Future<void> invalidateByTag(String tag) async {
    final keys = (await _backend.keysByTag(tag)).toList();
    // Best-effort delete all keys with this tag.
    for (final k in keys) {
      try {
        await _backend.delete(k);
      } catch (e, st) {
        _log?.call('Failed to delete key="$k" from tag="$tag"', e, st);
      }
    }
    // Also remove the tag index if the backend supports it.
    try {
      await _backend.deleteTag(tag);
    } on CacheBackendException catch (_) {
      // Silently ignore: backend may not support tag deletion.
    }
  }

  @override
  Future<int> purgeExpired() async {
    final now = _clock.nowEpochMs();
    try {
      return await _backend.purgeExpired(now);
    } catch (e, st) {
      _log?.call('Backend purgeExpired failed', e, st);
      return 0;
    }
  }

  @override
  Future<void> put(String key, D value, {Duration? ttl, Set<String> tags = const {}}) async {
    _validKey(key, true);
    final now = _clock.nowEpochMs();
    final expiresAt = _ttlPolicy.computeExpiresAtEpochMs(ttl: ttl, clock: _clock);
    final codec = defaultCodec;
    final entry = CacheEntry<E>(
      key: key,
      typeId: codec.typeId,
      payload: codec.encode(value),
      createdAtEpochMs: now,
      expiresAtEpochMs: expiresAt,
      tags: tags,
    );

    try {
      await _backend.write<E>(entry);
    } catch (e, st) {
      throw CacheBackendException('Backend write failed for key="$key": $e\n$st', stackTrace: st);
    }
  }

  @override
  Future<void> remove(String key) async {
    _validKey(key, false);
    await _backend.delete(key);
  }

  Future<D?> _makeData(CacheEntry<E>? entry, bool allowExpired, int now, String key) async {
    final codec = defaultCodec;
    if (entry == null) {
      return null;
    }

    if (!allowExpired && entry.isExpired(now)) {
      // Lazy expiration cleanup.
      try {
        await _backend.delete(key);
      } catch (e, st) {
        _log?.call('Failed to delete expired key="$key"', e, st);
      }
      return null;
    }

    if (entry.typeId != codec.typeId) {
      final msg =
          'Type mismatch for key="$key": '
          'stored="${entry.typeId}" requested="${codec.typeId}"';
      if (deleteCorruptedEntries) {
        _log?.call(msg, null, null);
        try {
          await _backend.delete(key);
        } catch (e, st) {
          _log?.call('Failed to delete mismatched key="$key"', e, st);
        }
        return null;
      }
      throw CacheTypeMismatchException(msg, stackTrace: StackTrace.current);
    }

    try {
      return codec.decode(entry.payload);
    } catch (e, st) {
      final msg = 'Decode failed for key="$key" typeId="${codec.typeId}"';
      if (deleteCorruptedEntries) {
        _log?.call(msg, e, st);
        try {
          await _backend.delete(key);
        } catch (e2, st2) {
          _log?.call('Failed to delete corrupted key="$key"', e2, st2);
        }
        return null;
      }
      throw CacheDecodeException(msg, cause: e, stackTrace: st);
    }
  }

  /// Validates [key], throwing or logging according to [errorOnEmpty].
  ///
  /// Write operations throw for an empty key. Read and removal operations log
  /// the problem for compatibility, then continue with the original key.
  void _validKey(String key, bool errorOnEmpty) {
    if (key.isEmpty) {
      if (errorOnEmpty) {
        throw CacheKeyEmptyException(stackTrace: StackTrace.current);
      } else {
        _log?.call('Cache key cannot be empty.', null, null);
      }
    }
  }
}
