abstract interface class Clock {
  int nowEpochMs();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  int nowEpochMs() => DateTime.now().millisecondsSinceEpoch;
}
