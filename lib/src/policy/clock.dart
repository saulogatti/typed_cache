/// Abstracts time for testability.
///
/// Inject different Clock implementations to control time in tests:
/// - [SystemClock]: Real time from the system
/// - `FakeClock`: Fixed or controlled time for unit tests
abstract interface class Clock {
  /// Returns the current time in milliseconds since epoch (UTC).
  int nowEpochMs();
}

/// Real system clock using [DateTime.now].
final class SystemClock implements Clock {
  const SystemClock();

  @override
  int nowEpochMs() => DateTime.now().millisecondsSinceEpoch;
}
