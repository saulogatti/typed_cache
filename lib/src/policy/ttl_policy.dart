import 'clock.dart';

/// Default TTL policy: expires at (now + ttl).
///
/// - If [ttl] is null, the entry never expires
/// - If [ttl] is zero or negative, the entry expires immediately
/// - Otherwise, the entry expires after [ttl] from now
final class DefaultTtlPolicy implements TtlPolicy {
  const DefaultTtlPolicy();

  @override
  int? computeExpiresAtEpochMs({required Duration? ttl, required Clock clock}) {
    if (ttl == null) return null;
    if (ttl <= Duration.zero) return clock.nowEpochMs();
    return clock.nowEpochMs() + ttl.inMilliseconds;
  }
}

/// Computes expiration timestamps for cache entries based on TTL.
///
/// Implement this interface to customize TTL behavior (e.g., sliding windows,
/// adaptive TTLs, or per-entry logic).
abstract interface class TtlPolicy {
  /// Computes the expiration timestamp for an entry.
  ///
  /// Parameters:
  /// - [ttl]: The desired time-to-live, or null for no expiration
  /// - [clock]: The current time source
  ///
  /// Returns:
  /// - `null` if [ttl] is null (no expiration)
  /// - Current time in ms if [ttl] is zero or negative (immediate expiration)
  /// - Current time + ttl in ms otherwise
  int? computeExpiresAtEpochMs({required Duration? ttl, required Clock clock});
}
