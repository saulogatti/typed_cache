import 'package:typed_cache/typed_cache.dart';

import 'cache_objects.dart';

/// Runs a minimal illustrative cache workflow.
///
/// The in-memory backend below is intentionally small and is not a
/// production storage recommendation.
void main() async {
  final backend = InMemoryBackend();
  final cache = createTypedCache(
    backend: backend,
    defaultCodec: MyObjectCodec(),
    log: (message, error, st) {},
  );
  await cache.put(
    'my_object',
    MyObjectCacheObject(key: 'my_object', value: MyObject('data to be cached')),
  );
  final myObject = await cache.get('my_object');
  // ignore: unnecessary_statements
  myObject?.value;
}

/// Minimal in-memory backend used only by this executable example.
class InMemoryBackend implements CacheBackend {
  /// Creates an empty backend.
  InMemoryBackend();

  final Map<String, CacheEntry<dynamic>> _entries = {};

  @override
  Future<void> clear() async {
    _entries.clear();
  }

  @override
  Future<void> delete(String key) async {
    _entries.remove(key);
  }

  @override
  Future<void> deleteTag(String tag) async {
    _entries.removeWhere((key, entry) => entry.tags.contains(tag));
  }

  @override
  Future<Set<String>> keysByTag(String tag) => Future.value(
    _entries.keys.where((key) => _entries[key]?.tags.contains(tag) ?? false).toSet(),
  );

  @override
  Future<int> purgeExpired(int nowEpochMs) async {
    final expiredKeys = _entries.entries
        .where((entry) => entry.value.isExpired(nowEpochMs))
        .map((entry) => entry.key)
        .toList();
    for (final key in expiredKeys) {
      await delete(key);
    }
    return expiredKeys.length;
  }

  @override
  Future<CacheEntry<E>?> read<E>(String key) async => _entries[key] as CacheEntry<E>?;

  @override
  Future<List<CacheEntry<E>>> readAll<E>() =>
      Future.value(_entries.values.toList() as List<CacheEntry<E>>);

  @override
  Future<void> write<E>(CacheEntry<E> entry) {
    _entries[entry.key] = entry;
    return Future.value();
  }
}

/// Domain value encoded by [MyObjectCodec].
class MyObject {
  /// Creates a value from [value].
  MyObject(this.value);

  /// Encoded value used by the example.
  final String value;

  @override
  String toString() => '''MyObject(value: $value)''';
}

/// Converts cache objects to and from their illustrative string payload.
class MyObjectCodec implements CacheCodec<String, CacheObject<MyObject>> {
  @override
  String get typeId => 'my_object';

  @override
  CacheObject<MyObject> decode(String data) =>
      MyObjectCacheObject(key: data, value: MyObject(data));

  @override
  String encode(CacheObject<MyObject> value) {
    switch (value) {
      case MyObjectCacheObject():
        return value.key;
      case StringCacheObject():
        return value.value.toString();
      case IntCacheObject():
        return value.value.toString();
    }
  }
}
