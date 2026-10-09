import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/study/scheduler.dart';

void main() {
  final monday = DateTime(2026, 10, 12, 21, 30); // evening
  final tomorrow = DateTime(2026, 10, 13);

  group('afterAnswer', () {
    test('a new item answered right goes to box 1, due in 3 days', () {
      final s = afterAnswer(const Schedule(), correct: true, now: monday);
      expect(s.box, 1);
      expect(s.dueDay, DateTime(2026, 10, 15));
      expect(s.streak, 1);
      expect(s.lapses, 0);
    });

    test('a new item answered wrong goes to box 0, due tomorrow', () {
      final s = afterAnswer(const Schedule(), correct: false, now: monday);
      expect(s.box, 0);
      expect(s.dueDay, tomorrow);
      expect(s.streak, 0);
      expect(s.lapses, 1);
    });

    test('each right answer on the due day moves it up a box, to longer gaps', () {
      var s = const Schedule();
      final gaps = <int>[];
      var day = monday;
      for (var i = 0; i < 6; i++) {
        s = afterAnswer(s, correct: true, now: day);
        gaps.add(s.dueDay!.difference(dayOf(day)).inDays);
        day = s.dueDay!; // practice again on the day it is due
      }
      expect(gaps, [3, 7, 21, 45, 45, 45]); // the top box stays at 45 days
      expect(s.box, topBox);
      expect(s.streak, 6);
    });

    test('a wrong answer sends a well-known item back to box 0, tomorrow, and counts the lapse', () {
      final known = Schedule(box: 4, dueDay: DateTime(2026, 10, 12), streak: 5, lapses: 1);
      final s = afterAnswer(known, correct: false, now: monday);
      expect(s.box, 0);
      expect(s.dueDay, tomorrow);
      expect(s.streak, 0);
      expect(s.lapses, 2);
    });

    test('a right answer before it is due keeps the schedule, so answering early cannot push it away', () {
      final notYet = Schedule(box: 2, dueDay: DateTime(2026, 10, 19), streak: 2);
      final s = afterAnswer(notYet, correct: true, now: monday);
      expect(s.box, 2);
      expect(s.dueDay, DateTime(2026, 10, 19));
      expect(s.streak, 3); // it still counts as a right answer
    });

    test('a wrong answer before it is due still brings it back tomorrow', () {
      final notYet = Schedule(box: 3, dueDay: DateTime(2026, 11, 2), streak: 3);
      final s = afterAnswer(notYet, correct: false, now: monday);
      expect(s.box, 0);
      expect(s.dueDay, tomorrow);
    });

    test('answering the same item twice in a day does not move it up twice', () {
      var s = afterAnswer(const Schedule(), correct: true, now: monday);
      s = afterAnswer(s, correct: true, now: monday.add(const Duration(minutes: 5)));
      expect(s.box, 1);
      expect(s.dueDay, DateTime(2026, 10, 15));
    });

    test('an item answered late is counted from the day it was answered, not the day it was due', () {
      final late = Schedule(box: 1, dueDay: DateTime(2026, 10, 5));
      final s = afterAnswer(late, correct: true, now: monday);
      expect(s.box, 2);
      expect(s.dueDay, DateTime(2026, 10, 19)); // 7 days after Monday the 12th
    });

    test('the time of day makes no difference, and months and years roll over', () {
      final lateNight = afterAnswer(const Schedule(), correct: false, now: DateTime(2026, 12, 31, 23, 59));
      expect(lateNight.dueDay, DateTime(2027, 1, 1));
      final earlyMorning = afterAnswer(const Schedule(), correct: false, now: DateTime(2026, 12, 31, 0, 1));
      expect(earlyMorning.dueDay, DateTime(2027, 1, 1));
    });
  });

  group('lastDay', () {
    test('is today after any answer: right, wrong, or right ahead of its day', () {
      expect(afterAnswer(const Schedule(), correct: true, now: monday).lastDay, DateTime(2026, 10, 12));
      expect(afterAnswer(const Schedule(), correct: false, now: monday).lastDay, DateTime(2026, 10, 12));
      final early = afterAnswer(Schedule(box: 2, dueDay: DateTime(2026, 10, 19)), correct: true, now: monday);
      expect(early.lastDay, DateTime(2026, 10, 12));
      expect(const Schedule().lastDay, isNull);
    });

    test('moves on with each later answer', () {
      var s = afterAnswer(const Schedule(), correct: true, now: monday);
      s = afterAnswer(s, correct: true, now: DateTime(2026, 10, 15, 8));
      expect(s.lastDay, DateTime(2026, 10, 15));
    });
  });

  group('isDueBy', () {
    test('is due on its day and after, never before, and never if never answered', () {
      final s = Schedule(dueDay: DateTime(2026, 10, 13));
      expect(s.isDueBy(DateTime(2026, 10, 12)), isFalse);
      expect(s.isDueBy(DateTime(2026, 10, 13)), isTrue);
      expect(s.isDueBy(DateTime(2026, 10, 20)), isTrue);
      expect(const Schedule().isDueBy(DateTime(2026, 10, 13)), isFalse);
    });
  });

  test('dayOf is midnight of the same day', () {
    expect(dayOf(DateTime(2026, 10, 12, 23, 59, 59)), DateTime(2026, 10, 12));
  });

  test('estimateMinutes rounds up, and is zero for nothing', () {
    expect(estimateMinutes(0), 0);
    expect(estimateMinutes(1), 1);
    expect(estimateMinutes(3), 2);
    expect(estimateMinutes(5), 3);
    expect(estimateMinutes(10), 6);
  });

  test('a session holds about 35 seconds of work per item: 2 min is 3 items, 5 is 5, 10 is 10', () {
    expect(sessionSizeFor(2), 3);
    expect(sessionSizeFor(5), 5);
    expect(sessionSizeFor(10), 10);
    expect(sessionSizeFor(1), 3);
    expect(sessionSizeFor(30), 10);
  });
}
