import 'dart:math';

/// Days until an item is due again, by the box it has reached. A new or missed
/// item sits in box 0 and comes back tomorrow; each right answer moves it up a
/// box, to be asked less and less often.
const reviewIntervals = [1, 3, 7, 21, 45];
const topBox = 4;

/// Midnight at the start of [t]'s day. Schedules count in whole days, so it does
/// not matter at what time of day a student practices.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime _plusDays(DateTime day, int n) => DateTime(day.year, day.month, day.day + n);

/// Where one flashcard or question stands: its box, the day it is next due, and
/// how it has gone.
class Schedule {
  const Schedule({this.box = 0, this.dueDay, this.streak = 0, this.lapses = 0, this.lastDay});

  final int box;

  /// The day it was last answered, or null if it never has been.
  final DateTime? lastDay;

  /// The day it is next due, or null if it has never been answered.
  final DateTime? dueDay;

  /// Right answers in a row.
  final int streak;

  /// Wrong answers, in all.
  final int lapses;

  /// True if it is due on [day], or was due before it.
  bool isDueBy(DateTime day) => dueDay != null && !dueDay!.isAfter(day);
}

/// The schedule after one answer on [now].
///
/// Wrong: back to box 0, due tomorrow, whether or not it was due. Right and due:
/// up one box. Right but not yet due (practicing ahead, or answering the same
/// thing twice in a day) keeps the schedule as it is, so answering early cannot
/// push something far away before it has been remembered over time.
Schedule afterAnswer(Schedule s, {required bool correct, required DateTime now}) {
  final today = dayOf(now);
  if (!correct) {
    return Schedule(
        box: 0, dueDay: _plusDays(today, reviewIntervals[0]), streak: 0, lapses: s.lapses + 1, lastDay: today);
  }
  if (s.dueDay != null && s.dueDay!.isAfter(today)) {
    return Schedule(box: s.box, dueDay: s.dueDay, streak: s.streak + 1, lapses: s.lapses, lastDay: today);
  }
  final box = min(s.box + 1, topBox);
  return Schedule(
      box: box, dueDay: _plusDays(today, reviewIntervals[box]), streak: s.streak + 1, lapses: s.lapses, lastDay: today);
}

/// About how many minutes [items] take: about 35 seconds each, never under 1.
int estimateMinutes(int items) => items <= 0 ? 0 : ((items * 35) / 60).ceil();

/// How many items a practice session of [minutes] holds: about 35 seconds each.
int sessionSizeFor(int minutes) => switch (minutes) {
      <= 2 => 3,
      <= 5 => 5,
      _ => 10,
    };
