import 'backend.dart';
import 'codec.dart';
import 'entry.dart';
import 'errors.dart';
import 'policy/clock.dart';
import 'policy/ttl_policy.dart';
import 'typed_cache.dart';

/// Signature for cache logging functions.
///
/// Called when cache operations succeed or fail. Useful for debugging
/// and monitoring cache health.
typedef CacheLogger =
    void Function(String message, Object? error, StackTrace? st);

/// Production [TypedCache] implementation.
///
/// This class orchestrates the cache operations, delegating to:
/// - [CacheBackend]: Persistent storage
/// - [TtlPolicy]: Expiration logic
/// - [Clock]: Time source
///
/// It handles:
/// - Type validation via codec typeId
/// - Lazy expiration (on access, not scheduled)
/// - Corrupted entry cleanup
/// - Error logging
final class CacheStore<E, D extends Object> implements TypedCache<E, D> {
  final CacheBackend _backend;
  final Clock _clock;
  final TtlPolicy _ttlPolicy;
  final CacheLogger? _log;
  @override
  final CacheCodec<E, D> defaultCodec;

  /// If true, silently delete corrupted/mismatched entries instead of throwing.
  final bool deleteCorruptedEntries;

  /// Creates a new cache instance.
  ///
  /// Parameters:
  /// - [backend]: Required storage backend
  /// - [clock]: Time source (default: [SystemClock])
  /// - [ttlPolicy]: TTL computation strategy (default: [DefaultTtlPolicy])
  /// - [logger]: Optional logging function
  /// - [deleteCorruptedEntries]: Auto-delete corrupted entries (default: true)
  CacheStore({
    required CacheBackend backend,
    required this.defaultCodec,
    Clock clock = const SystemClock(),
    TtlPolicy ttlPolicy = const DefaultTtlPolicy(),
    CacheLogger? logger,
    this.deleteCorruptedEntries = true,
  }) : _backend = backend,
       _clock = clock,
       _ttlPolicy = ttlPolicy,
       _log = logger;

  @override
  Future<void> clear() => _backend.clear();
  @override
  Future<bool> contains(String key) async {
    _validKey(key);
    final entry = await _backend.read(key);
    if (entry == null) return false;

    final now = _clock.nowEpochMs();
    if (entry.isExpired(now)) return false;

    return true;
  }

  @override
  Future<D?> get(String key, {bool allowExpired = false}) async {
    _validKey(key);
    final now = _clock.nowEpochMs();
    CacheEntry<E>? entry;
    try {
      entry = await _backend.read<E>(key);
    } catch (e, st) {
      _log?.call('Backend read failed for key="$key"', e, st);
      throw CacheBackendException(
        'Backend read failed for key="$key": $e',
        stackTrace: st,
      );
    }
    return await _makeData(entry, allowExpired, now, key);
  }

  @override
  @override
  Future<List<D>> getAll() async {
    final listAll = await _backend.readAll<E>();
    if (listAll.isEmpty) {
      return [];
    }

    final now = _clock.nowEpochMs();
    final dataFutures = listAll.map(
      (entry) => _makeData(entry, false, now, entry.key),
    );

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

    if (cached != null && !allowExpiredWhileRevalidating) return cached;

    if (cached != null && allowExpiredWhileRevalidating) {
      // Return stale but revalidate in the background.
      // Note: This is best-effort; errors are logged but not propagated.
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
  Future<void> invalidate(String key) => _delete(key);

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
    } catch (_) {
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
  Future<void> put(
    String key,
    D value, {
    Duration? ttl,
    Set<String> tags = const {},
  }) async {
    _validKey(key);
    final now = _clock.nowEpochMs();
    final expiresAt = _ttlPolicy.computeExpiresAtEpochMs(
      ttl: ttl,
      clock: _clock,
    );
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
      throw CacheBackendException(
        'Backend write failed for key="$key": $e\n${st.toString()}',
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> remove(String key) async {
    _validKey(key);
    await _backend.delete(key);
  }

  Future<void> _delete(String key) async {
    _validKey(key);
    await _backend.delete(key);
  }

  Future<D?> _makeData(
    CacheEntry<E>? entry,
    bool allowExpired,
    int now,
    String key,
  ) async {
    final codec = defaultCodec;
    if (entry == null) return null;

    _validKey(key);

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

  void _validKey(String key) {
    if (key.isEmpty) {
      throw CacheTypeMismatchException(
        'Cache key cannot be empty',
        stackTrace: StackTrace.current,
      );
    }
  }
}
