/// Consecutive days, ending today (or yesterday if today has none yet),
/// that have at least one attempt.
int computeStreak(Iterable<DateTime> attemptTimes, DateTime now) {
  final days = {
    for (final t in attemptTimes) DateTime(t.year, t.month, t.day),
  };
  var day = DateTime(now.year, now.month, now.day);
  if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
  var n = 0;
  while (days.contains(day)) {
    n++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return n;
}
