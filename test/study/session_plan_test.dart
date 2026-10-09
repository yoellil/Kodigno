import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/study/scheduler.dart';
import 'package:kodigno/study/session_plan.dart';

final _now = DateTime(2026, 10, 12, 9);
final _today = DateTime(2026, 10, 12);

Candidate _card(int id, {int set = 1, Schedule? s, String? key}) =>
    Candidate(kind: ItemKind.card, itemId: id, setId: set, schedule: s, key: key);
Candidate _q(int id, {int set = 1, Schedule? s, String? key}) =>
    Candidate(kind: ItemKind.question, itemId: id, setId: set, schedule: s, key: key);
Schedule _due(int daysAgo, {int lapses = 0}) =>
    Schedule(box: 1, dueDay: DateTime(2026, 10, 12 - daysAgo), lapses: lapses);
Schedule _later(int days) => Schedule(box: 2, dueDay: DateTime(2026, 10, 12 + days));

/// Not due for a while, and answered today.
Schedule _doneToday() => Schedule(box: 1, dueDay: DateTime(2026, 10, 15), lastDay: _today);

/// Not due for a while, and last answered on another day.
Schedule _answeredBefore() => Schedule(box: 1, dueDay: DateTime(2026, 10, 15), lastDay: DateTime(2026, 10, 10));

List<String> _ids(SessionPlan p) => [for (final c in p.items) '${c.kind.name[0]}${c.itemId}'];

void main() {
  group('planSession', () {
    test('what is due comes first, the most overdue and most missed at the front', () {
      final plan = planSession([
        _card(1, s: _due(0)),
        _card(2, s: _due(5)),
        _q(3, s: _due(2, lapses: 3)),
        _q(4, s: _due(2, lapses: 1)),
        _card(5, s: _later(4)),
      ], now: _now, size: 4);
      expect(_ids(plan), ['c2', 'q3', 'q4', 'c1']);
      expect(plan.due, 4);
      expect(plan.fresh, 0);
      expect(plan.ahead, 0);
    });

    test('items due today count as due, and tomorrow\'s do not', () {
      final plan = planSession([_card(1, s: Schedule(box: 1, dueDay: _today)), _card(2, s: _later(1))], now: _now, size: 5);
      expect(_ids(plan), ['c1', 'c2']);
      expect(plan.due, 1);
      expect(plan.ahead, 1);
    });

    test('room left after the due items is filled with new ones to learn', () {
      final plan = planSession([_card(1, s: _due(1)), _card(2), _card(3), _q(4), _card(5, s: _later(3))], now: _now, size: 3);
      expect(plan.items.first.itemId, 1);
      expect(plan.due, 1);
      expect(plan.fresh, 2);
      expect(plan.ahead, 0); // there was no room for early ones
      expect(plan.items.length, 3);
    });

    test('with nothing due or new, it offers items that are not due yet, the soonest first', () {
      final plan = planSession([_card(1, s: _later(10)), _card(2, s: _later(2)), _card(3, s: _later(5))], now: _now, size: 2);
      expect(_ids(plan), ['c2', 'c3']);
      expect(plan.ahead, 2);
      expect(plan.due, 0);
    });

    test('items answered today are not asked again; earlier ones can fill the room', () {
      final plan = planSession([
        _card(1, s: _doneToday()),
        _card(2, s: _doneToday()),
        _card(3, s: _answeredBefore()),
        _card(4, s: _later(9)),
      ], now: _now, size: 5);
      expect(_ids(plan), ['c3', 'c4']);
      expect(plan.ahead, 2);
    });

    test('when everything has been answered today, there is nothing to ask', () {
      final plan = planSession([_card(1, s: _doneToday()), _q(2, s: _doneToday())], now: _now, size: 5);
      expect(plan.items, isEmpty);
    });

    test('an item that is due today is asked even if it has an answer from today', () {
      final plan = planSession([_card(1, s: Schedule(box: 0, dueDay: _today, lastDay: _today))], now: _now, size: 3);
      expect(plan.due, 1);
    });

    test('never more than the size, and an empty library gives an empty session', () {
      final many = [for (var i = 1; i <= 30; i++) _card(i)];
      expect(planSession(many, now: _now, size: 10).items, hasLength(10));
      expect(planSession(const [], now: _now, size: 5).items, isEmpty);
      expect(planSession(many, now: _now, size: 0).items, isEmpty);
    });

    test('a session is not five of one kind: new cards and questions alternate within a set', () {
      final plan = planSession([_card(1), _card(2), _card(3), _q(11), _q(12), _q(13)], now: _now, size: 4);
      expect(_ids(plan), ['c1', 'q11', 'c2', 'q12']);
    });

    test('new items are spread across sets, the newest set first', () {
      final plan = planSession([
        _card(1, set: 1), _card(2, set: 1), _card(3, set: 1),
        _card(10, set: 2), _card(11, set: 2),
        _card(20, set: 3), _card(21, set: 3),
      ], now: _now, size: 5);
      expect([for (final c in plan.items) c.setId], [3, 2, 1, 3, 2]);
    });

    test('with a set chosen, only that set\'s items are used', () {
      final all = [_card(1, set: 1, s: _due(1)), _card(2, set: 2, s: _due(9)), _card(3, set: 2), _q(4, set: 1)];
      final plan = planSession(all, now: _now, size: 5, setId: 1);
      expect({for (final c in plan.items) c.setId}, {1});
      expect(plan.items.length, 2);
      expect(planSession(all, now: _now, size: 5, setId: 9).items, isEmpty);
    });

    test('a due item with a schedule but no day (never answered) is treated as new', () {
      final plan = planSession([_card(1, s: const Schedule())], now: _now, size: 3);
      expect(plan.fresh, 1);
      expect(plan.due, 0);
    });

    test('the same input always gives the same session', () {
      final all = [for (var i = 1; i <= 12; i++) i.isEven ? _q(i, set: i % 3) : _card(i, set: i % 3)];
      expect(_ids(planSession(all, now: _now, size: 6)), _ids(planSession(all, now: _now, size: 6)));
    });
  });

  group('the same fact is asked once', () {
    test('a card and a question with the same wording are one fact: only the first is in the session', () {
      final plan = planSession([
        _card(1, key: 'what is a patent'),
        _q(11, key: 'what is a patent'),
        _card(2, key: 'what is a trade secret'),
        _q(12, key: 'what is a trade secret'),
        _card(3, key: 'who is whistle blowing about'),
      ], now: _now, size: 5);
      expect(_ids(plan), ['c1', 'c2', 'c3']);
      expect(plan.fresh, 3);
    });

    test('the room freed by a duplicate goes to the next fact', () {
      final plan = planSession([
        _card(1, key: 'a'), _q(11, key: 'a'), _card(2, key: 'b'), _q(12, key: 'b'), _card(3, key: 'c'), _q(13, key: 'c'),
      ], now: _now, size: 3);
      expect(plan.items.length, 3);
      expect({for (final c in plan.items) c.key}, {'a', 'b', 'c'});
    });

    test('items with no key are never taken for the same fact', () {
      final plan = planSession([_card(1), _q(11), _card(2)], now: _now, size: 5);
      expect(plan.items.length, 3);
    });

    test('two due items with the same wording: the first is asked, the other waits', () {
      final plan = planSession([_card(1, s: _due(3), key: 'x'), _q(2, s: _due(1), key: 'x')], now: _now, size: 5);
      expect(_ids(plan), ['c1']);
      expect(plan.due, 1);
    });

    test('a fact answered today is not asked again today in its other form', () {
      final plan = planSession([_card(1, s: _doneToday(), key: 'x'), _q(2, key: 'x'), _q(3, key: 'y')], now: _now, size: 5);
      expect(_ids(plan), ['q3']);
    });

    test('but an item that is due is asked even if its other form was answered today', () {
      final plan = planSession([_card(1, s: _doneToday(), key: 'x'), _q(2, s: _due(1), key: 'x')], now: _now, size: 5);
      expect(_ids(plan), ['q2']);
    });

    test('the same wording in two sets is one fact', () {
      final plan = planSession([_card(1, set: 1, key: 'x'), _card(2, set: 2, key: 'x'), _card(3, set: 2, key: 'y')], now: _now, size: 5);
      expect(plan.items.length, 2);
    });

    test('limited to one set, a fact is still asked once within it, and not hidden by another set', () {
      final all = [_card(1, set: 1, key: 'x'), _q(2, set: 1, key: 'x'), _card(3, set: 2, key: 'x')];
      expect(planSession(all, now: _now, size: 5, setId: 1).items.length, 1);
      expect(planSession(all, now: _now, size: 5, setId: 2).items.length, 1);
    });

    test('the count says the same as the session, so the card never promises more than there is', () {
      final all = [_card(1, key: 'a'), _q(11, key: 'a'), _card(2, key: 'b'), _q(12, key: 'b'), _card(3, key: 'c')];
      final counts = countFor(all, _now);
      expect(counts.fresh, 3);
      expect(counts.within(5).total, planSession(all, now: _now, size: 5).items.length);
    });

    test('practiceKey ignores case, punctuation and spacing', () {
      expect(practiceKey('What does the ACM Code of Ethics express?'), practiceKey('what does the acm code of ethics   express'));
      expect(practiceKey('A, B'), 'a b');
      expect(practiceKey('  '), '');
    });
  });

  group('PracticeCounts.within', () {
    test('fills a session in the order due, new, early, and never past its size', () {
      const c = PracticeCounts(due: 2, fresh: 4, ahead: 9);
      final w = c.within(5);
      expect((w.due, w.fresh, w.ahead), (2, 3, 0));
      final big = c.within(10);
      expect((big.due, big.fresh, big.ahead), (2, 4, 4));
      expect(big.total, 10);
    });

    test('is what planSession actually picks', () {
      final all = [_card(1, s: _due(1)), _card(2), _card(3), _q(4, s: _later(2)), _q(5, s: _later(5))];
      final plan = planSession(all, now: _now, size: 4);
      final w = countFor(all, _now).within(4);
      expect((w.due, w.fresh, w.ahead), (plan.due, plan.fresh, plan.ahead));
    });

    test('items done today do not take up room', () {
      final c = countFor([_card(1, s: _doneToday()), _card(2), _card(3, s: _answeredBefore())], _now);
      expect((c.due, c.fresh, c.ahead, c.doneToday), (0, 1, 1, 1));
      expect(c.total, 2);
      expect(c.within(5).total, 2);
    });

    test('with nothing, or a size of zero, is nothing', () {
      expect(const PracticeCounts().within(5).total, 0);
      expect(const PracticeCounts(due: 3, fresh: 3).within(0).total, 0);
    });

    test('when everything is early, a session is early items', () {
      final w = const PracticeCounts(ahead: 7).within(3);
      expect((w.due, w.fresh, w.ahead), (0, 0, 3));
    });
  });

  group('countFor', () {
    final all = [
      _card(1, s: _due(2)), _card(2, s: Schedule(box: 1, dueDay: _today)),
      _q(3), _q(4), _q(5),
      _card(6, s: _later(3)), _card(7, set: 2, s: _due(1)),
    ];

    test('counts what is due, new, and not due yet', () {
      final c = countFor(all, _now);
      expect(c.due, 3);
      expect(c.fresh, 3);
      expect(c.ahead, 1);
      expect(c.total, 7);
    });

    test('counts what was answered today apart from what is waiting', () {
      final c = countFor([_card(1, s: _doneToday()), _q(2, s: _doneToday()), _card(3, s: _later(5))], _now);
      expect(c.doneToday, 2);
      expect(c.ahead, 1);
      expect(countFor([_card(1, s: _doneToday())], _now).total, 0);
    });

    test('can be limited to one set', () {
      final c = countFor(all, _now, setId: 1);
      expect(c.due, 2);
      expect(c.fresh, 3);
      expect(c.ahead, 1);
      expect(countFor(all, _now, setId: 2).due, 1);
      expect(countFor(const [], _now).total, 0);
    });
  });
}
