import 'example.dart';

/// Sealed container used to demonstrate encoding different domain values.
sealed class CacheObject<T> {
  /// Creates a cache object identified by [key].
  CacheObject({required this.key, required this.value});

  /// Key associated with this example value.
  final String key;

  /// Domain value wrapped by the cache object.
  final T value;
}

/// Example cache object that contains an integer.
class IntCacheObject extends CacheObject<int> {
  /// Creates an integer cache object.
  IntCacheObject({required super.key, required super.value});
}

/// Example cache object that contains [MyObject].
class MyObjectCacheObject extends CacheObject<MyObject> {
  /// Creates a custom-object cache object.
  MyObjectCacheObject({required super.key, required super.value});
}

/// Example cache object that contains a string.
class StringCacheObject extends CacheObject<String> {
  /// Creates a string cache object.
  StringCacheObject({required super.key, required super.value});
}
