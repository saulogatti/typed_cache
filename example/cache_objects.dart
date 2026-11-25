import 'example.dart';

sealed class CacheObject<T> {
  CacheObject({required this.key, required this.value});

  final String key;
  final T value;
}

class IntCacheObject extends CacheObject<int> {
  IntCacheObject({required super.key, required super.value});
}

class MyObjectCacheObject extends CacheObject<MyObject> {
  MyObjectCacheObject({required super.key, required super.value});
}

class StringCacheObject extends CacheObject<String> {
  StringCacheObject({required super.key, required super.value});
}
