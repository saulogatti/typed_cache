import 'clock.dart';

final class DefaultTtlPolicy implements TtlPolicy {
  const DefaultTtlPolicy();

  @override
  int? computeExpiresAtEpochMs({required Duration? ttl, required Clock clock}) {
    if (ttl == null) return null;
    if (ttl <= Duration.zero) {
      // TTL zero/negative => treat as immediately expired.
      return clock.nowEpochMs();
    }
    return clock.nowEpochMs() + ttl.inMilliseconds;
  }
}

abstract interface class TtlPolicy {
  /// Compute expiresAt based on now + ttl, or return null for no expiration.
  int? computeExpiresAtEpochMs({required Duration? ttl, required Clock clock});
}
