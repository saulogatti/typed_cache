import 'package:test/test.dart';
import 'package:typed_cache/src/cache_store.dart';
import 'package:typed_cache/typed_cache.dart';

// ============================================================================
// Test Doubles
// ============================================================================

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('CacheStore', () {
    late CacheStore cache, cacheInt;
    late FakeCacheBackend backend;
    late FakeClock clock;
    final codec = StringCodec();
    final intCodec = IntCodec();

    setUp(() {
      backend = FakeCacheBackend();
      clock = FakeClock();
      cache = CacheStore(
        backend: backend,
        defaultCodec: codec,
        clock: clock,
        ttlPolicy: const DefaultTtlPolicy(),
      );
      cacheInt = CacheStore(
        backend: backend,
        defaultCodec: intCodec,
        clock: clock,
        ttlPolicy: const DefaultTtlPolicy(),
      );
    });

    group('put and get', () {
      test('stores and retrieves a value', () async {
        // Arrange

        const key = 'user:123';
        const value = 'Alice';

        // Act
        await cache.put(key, value);
        final retrieved = await cache.get(key);

        // Assert
        expect(retrieved, equals(value));
      });

      test('returns null for non-existent key', () async {
        // Arrange & Act
        final retrieved = await cache.get('nonexistent');

        // Assert
        expect(retrieved, isNull);
      });

      test('stores multiple values independently', () async {
        // Arrange

        // Act
        await cache.put('str', 'hello');
        await cacheInt.put('int', 42);

        // Assert
        expect(await cache.get('str'), equals('hello'));
        expect(await cacheInt.get('int'), equals(42));
      });
    });

    group('TTL and expiration', () {
      test('returns null for expired entries', () async {
        // Arrange

        const key = 'temp';
        const ttl = Duration(minutes: 1);

        // Act
        await cache.put(key, 'value', ttl: ttl);
        clock.advance(Duration(minutes: 2));
        final retrieved = await cache.get(key);

        // Assert
        expect(retrieved, isNull);
      });

      test('returns non-expired values', () async {
        // Arrange

        const key = 'temp';
        const ttl = Duration(minutes: 5);

        // Act
        await cache.put(key, 'value', ttl: ttl);
        clock.advance(Duration(minutes: 2));
        final retrieved = await cache.get(key);

        // Assert
        expect(retrieved, equals('value'));
      });

      test('allowExpired returns expired entries', () async {
        // Arrange

        const key = 'stale';
        const ttl = Duration(minutes: 1);

        // Act
        await cache.put(key, 'stale-value', ttl: ttl);
        clock.advance(Duration(minutes: 2));
        final retrieved = await cache.get(key, allowExpired: true);

        // Assert
        expect(retrieved, equals('stale-value'));
      });

      test('purgeExpired removes expired entries', () async {
        // Arrange

        await cache.put('key1', 'value1', ttl: Duration(seconds: 30));
        clock.advance(Duration(seconds: 60));
        await cache.put('key2', 'value2', ttl: Duration(hours: 1));

        // Act
        final purged = await cache.purgeExpired();

        // Assert
        expect(purged, equals(1));
        expect(await cache.contains('key1'), isFalse);
        expect(await cache.contains('key2'), isTrue);
      });
    });

    group('contains', () {
      test('returns true for existing non-expired entries', () async {
        // Arrange

        await cache.put('key', 'value');

        // Act & Assert
        expect(await cache.contains('key'), isTrue);
      });

      test('returns false for non-existent keys', () async {
        // Act & Assert
        expect(await cache.contains('nonexistent'), isFalse);
      });

      test('returns false for expired entries', () async {
        // Arrange

        await cache.put('key', 'value', ttl: Duration(seconds: 10));
        clock.advance(Duration(seconds: 20));

        // Act & Assert
        expect(await cache.contains('key'), isFalse);
      });
    });

    group('type validation', () {
      test('validates codec typeId and accepts matching types', () async {
        // Arrange

        await cache.put('key', 'value');

        // Act
        final retrieved = await cache.get('key');

        // Assert
        expect(retrieved, equals('value'));
      });

      test('stores and retrieves with correct codec typeId', () async {
        // Arrange

        const strKey = 'str_key';
        const intKey = 'int_key';

        // Act
        await cache.put(strKey, 'hello');
        await cacheInt.put(intKey, 42);

        // Assert
        expect(await cache.get(strKey), equals('hello'));
        expect(await cacheInt.get(intKey), equals(42));
      });
    });

    group('decode errors', () {
      test('silently deletes on decode failure with deleteCorruptedEntries=true', () async {
        // Arrange
        final codec = FailingDecodeCodec();
        final cache = CacheStore(
          backend: backend,
          clock: clock,
          deleteCorruptedEntries: true,
          defaultCodec: codec,
        );
        await cache.put('key', 'value');

        // Act
        final retrieved = await cache.get('key');

        // Assert - returns null due to decode error and deleteCorruptedEntries
        expect(retrieved, isNull);
        expect(await backend.read('key'), isNull);
      });

      test('throws on decode failure with deleteCorruptedEntries=false', () async {
        final codec = FailingDecodeCodec();
        cache = CacheStore(
          backend: backend,
          clock: clock,
          deleteCorruptedEntries: false,
          defaultCodec: codec,
        );

        await cache.put('key', 'value');

        // Act & Assert
        expect(() => cache.get('key'), throwsA(isA<CacheDecodeException>()));
      });
    });

    group('tags and invalidation', () {
      test('stores entries with tags', () async {
        // Arrange

        const tags = {'user', 'session'};

        // Act
        await cache.put('key', 'value', tags: tags);

        // Assert
        expect((await backend.read('key'))?.tags, equals(tags));
      });

      test('invalidateByTag removes all entries with tag', () async {
        // Arrange

        await cache.put('user:1', 'alice', tags: {'user'});
        await cache.put('user:2', 'bob', tags: {'user'});
        await cache.put('post:1', 'hello', tags: {'post'});

        // Act
        await cache.invalidateByTag('user');

        // Assert
        expect(await cache.contains('user:1'), isFalse);
        expect(await cache.contains('user:2'), isFalse);
        expect(await cache.contains('post:1'), isTrue);
      });

      test('invalidate removes single entry', () async {
        // Arrange

        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');

        // Act
        await cache.invalidate('key1');

        // Assert
        expect(await cache.contains('key1'), isFalse);
        expect(await cache.contains('key2'), isTrue);
      });
    });

    group('getOrFetch', () {
      test('returns cached value if exists', () async {
        // Arrange

        await cache.put('key', 'cached');
        var fetchCalled = false;

        // Act
        final result = await cache.getOrFetch(
          'key',

          fetch: () async {
            fetchCalled = true;
            return 'fresh';
          },
        );

        // Assert
        expect(result, equals('cached'));
        expect(fetchCalled, isFalse);
      });

      test('fetches and stores if not cached', () async {
        // Arrange

        const ttl = Duration(hours: 1);

        // Act
        final result = await cache.getOrFetch('key', fetch: () async => 'fresh', ttl: ttl);

        // Assert
        expect(result, equals('fresh'));
        expect(await cache.get('key'), equals('fresh'));
      });

      test('fetches and stores tags', () async {
        // Arrange

        const tags = {'tag1', 'tag2'};

        // Act
        await cache.getOrFetch('key', fetch: () async => 'value', tags: tags);

        // Assert
        expect((await backend.read('key'))?.tags, equals(tags));
      });

      test('handles fetch errors', () async {
        // Arrange

        // Act & Assert
        expect(
          () => cache.getOrFetch('key', fetch: () async => throw Exception('Network error')),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('clear', () {
      test('removes all entries', () async {
        // Arrange

        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');

        // Act
        await cache.clear();

        // Assert
        expect(await cache.contains('key1'), isFalse);
        expect(await cache.contains('key2'), isFalse);
      });
    });

    group('backend errors', () {
      test('throws CacheBackendException on write failure', () async {
        // Arrange
        cache = CacheStore(backend: FailingCacheBackend(), clock: clock, defaultCodec: StringCodec());

        // Act & Assert
        expect(() => cache.put('key', 'value'), throwsA(isA<CacheBackendException>()));
      });

      test('throws CacheBackendException on read failure', () async {
        // Arrange
        cache = CacheStore(backend: FailingCacheBackend(), clock: clock, defaultCodec: StringCodec());

        // Act & Assert
        expect(() => cache.get('key'), throwsA(isA<CacheBackendException>()));
      });
    });
  });

  group('DefaultTtlPolicy', () {
    const policy = DefaultTtlPolicy();
    late FakeClock clock;

    setUp(() {
      clock = FakeClock(initialTimeMs: 1000);
    });

    test('returns null for null ttl', () {
      // Act & Assert
      final result = policy.computeExpiresAtEpochMs(ttl: null, clock: clock);
      expect(result, isNull);
    });

    test('returns current time for zero/negative ttl', () {
      // Act & Assert
      expect(policy.computeExpiresAtEpochMs(ttl: Duration.zero, clock: clock), equals(1000));

      expect(policy.computeExpiresAtEpochMs(ttl: Duration(seconds: -5), clock: clock), equals(1000));
    });

    test('returns future time for positive ttl', () {
      // Act & Assert
      expect(
        policy.computeExpiresAtEpochMs(ttl: Duration(seconds: 60), clock: clock),
        equals(1000 + 60 * 1000),
      );
    });
  });

  group('CacheEntry', () {
    test('isExpired returns true for expired entry', () {
      // Arrange
      final entry = CacheEntry(
        key: 'test',
        typeId: 'string:v1',
        payload: 'value',
        createdAtEpochMs: 1000,
        expiresAtEpochMs: 2000,
        tags: {},
      );

      // Act & Assert
      expect(entry.isExpired(1500), isFalse);
      expect(entry.isExpired(2000), isTrue);
      expect(entry.isExpired(3000), isTrue);
    });

    test('isExpired returns false for non-expiring entry', () {
      // Arrange
      final entry = CacheEntry(
        key: 'test',
        typeId: 'string:v1',
        payload: 'value',
        createdAtEpochMs: 1000,
        expiresAtEpochMs: null,
        tags: {},
      );

      // Act & Assert
      expect(entry.isExpired(999999), isFalse);
    });

    test('copyWith creates new entry with updated fields', () {
      // Arrange
      final original = CacheEntry(
        key: 'test',
        typeId: 'string:v1',
        payload: 'value',
        createdAtEpochMs: 1000,
        expiresAtEpochMs: 2000,
        tags: {'tag1'},
      );

      // Act
      final updated = original.copyWith(payload: 'new-value', tags: {'tag1', 'tag2'});

      // Assert
      expect(updated.key, equals('test'));
      expect(updated.typeId, equals('string:v1'));
      expect(updated.payload, equals('new-value'));
      expect(updated.createdAtEpochMs, equals(1000));
      expect(updated.tags, equals({'tag1', 'tag2'}));
    });
  });
}

/// Failing backend for testing error scenarios.
class FailingCacheBackend implements CacheBackend {
  @override
  Future<void> clear() async => throw CacheBackendException('Backend error');

  @override
  Future<void> delete(String key) async => throw CacheBackendException('Backend error');

  @override
  Future<void> deleteTag(String tag) async => throw CacheBackendException('Backend error');

  @override
  Future<Set<String>> keysByTag(String tag) async => throw CacheBackendException('Backend error');

  @override
  Future<int> purgeExpired(int nowEpochMs) async => throw CacheBackendException('Backend error');

  @override
  Future<CacheEntry<E>?> read<E>(String key) async => throw CacheBackendException('Backend error');

  @override
  Future<void> write<E>(CacheEntry<E> entry) async => throw CacheBackendException('Backend error');
}

/// Codec that fails on decode.
class FailingDecodeCodec implements CacheCodec<String, String> {
  @override
  String get typeId => 'failing:v1';

  @override
  String decode(String data) => throw Exception('Decode failed');

  @override
  String encode(String value) => value;
}

/// Fake in-memory backend for testing.
class FakeCacheBackend implements CacheBackend {
  final Map<String, CacheEntry<dynamic>> _storage = {};
  final Map<String, Set<String>> _tagIndex = {};

  @override
  Future<void> clear() async {
    _storage.clear();
    _tagIndex.clear();
  }

  @override
  Future<void> delete(String key) async {
    final entry = _storage.remove(key);
    if (entry != null) {
      for (final tag in entry.tags) {
        _tagIndex[tag]?.remove(key);
      }
    }
  }

  @override
  Future<void> deleteTag(String tag) async {
    _tagIndex.remove(tag);
  }

  @override
  Future<Set<String>> keysByTag(String tag) async {
    return _tagIndex[tag] ?? {};
  }

  @override
  Future<int> purgeExpired(int nowEpochMs) async {
    var count = 0;
    final expiredKeys = _storage.entries
        .where((e) => e.value.isExpired(nowEpochMs))
        .map((e) => e.key)
        .toList();

    for (final key in expiredKeys) {
      await delete(key);
      count++;
    }
    return count;
  }

  @override
  Future<CacheEntry<E>?> read<E>(String key) async {
    return _storage[key] as CacheEntry<E>?;
  }

  @override
  Future<void> write<E>(CacheEntry<E> entry) async {
    _storage[entry.key] = entry;
    for (final tag in entry.tags) {
      _tagIndex.putIfAbsent(tag, () => {}).add(entry.key);
    }
  }
}

/// Fake clock for controlling time in tests.
class FakeClock implements Clock {
  int _nowEpochMs = 0;

  FakeClock({int initialTimeMs = 0}) : _nowEpochMs = initialTimeMs;

  void advance(Duration duration) {
    _nowEpochMs += duration.inMilliseconds;
  }

  @override
  int nowEpochMs() => _nowEpochMs;

  void setTime(int epochMs) {
    _nowEpochMs = epochMs;
  }
}

/// Test codec for integers.
class IntCodec implements CacheCodec<int, int> {
  @override
  String get typeId => 'int:v1';

  @override
  int decode(int data) => data;

  @override
  int encode(int value) => value;
}

/// Simple test codec for strings.
class StringCodec implements CacheCodec<String, String> {
  @override
  String get typeId => 'string:v1';

  @override
  String decode(String data) => data;

  @override
  String encode(String value) => value;
}
