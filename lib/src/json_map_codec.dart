import 'package:typed_cache/src/codec.dart';

final class JsonMapCodec<T> implements CacheCodec<T> {
  @override
  final String typeId;

  final Map<String, Object?> Function(T) toJson;
  final T Function(Map<String, Object?>) fromJson;

  const JsonMapCodec({
    required this.typeId,
    required this.toJson,
    required this.fromJson,
  });

  @override
  T decode(Object data) => fromJson(Map<String, Object?>.from(data as Map));

  @override
  Object encode(T value) => toJson(value);
}
