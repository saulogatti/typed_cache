import 'package:typed_cache/src/policy/clock.dart';

/// Default TTL policy: expires at (now + ttl).
///
/// - If `ttl` is null, the entry never expires
/// - If `ttl` is zero or negative, the entry expires immediately
/// - Otherwise, the entry expires after `ttl` from now
final class DefaultTtlPolicy implements TtlPolicy {
  /// Creates a new default TTL policy.
  const DefaultTtlPolicy();

  @override
  int? computeExpiresAtEpochMs({required Duration? ttl, required Clock clock}) {
    if (ttl == null) {
      return null;
    }
    if (ttl <= Duration.zero) {
      return clock.nowEpochMs();
    }
    return clock.nowEpochMs() + ttl.inMilliseconds;
  }
}

/// Computes expiration timestamps for cache entries based on TTL.
///
/// Implement this interface to customize TTL behavior (e.g., sliding windows,
/// adaptive expiration, or per-entry logic).
abstract interface class TtlPolicy {
  /// Computes the expiration timestamp for an entry.
  ///
  /// The returned value is in epoch milliseconds. A `null` result indicates
  /// that the entry does not expire. Custom policies must consistently use the
  /// supplied [clock] rather than reading system time directly.
  int? computeExpiresAtEpochMs({required Duration? ttl, required Clock clock});
}
