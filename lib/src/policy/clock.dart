// coverage:ignore-file
/// Abstracts time for testability.
///
/// Replace the system clock with a deterministic implementation in tests.
abstract interface class Clock {
  /// Returns the current time in milliseconds since epoch (UTC).
  int nowEpochMs();
}

/// Uses [DateTime.now] as the time source.
final class SystemClock implements Clock {
  /// Creates a new system clock.
  const SystemClock();

  @override
  int nowEpochMs() => DateTime.now().millisecondsSinceEpoch;
}
