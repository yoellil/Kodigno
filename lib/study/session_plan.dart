import 'scheduler.dart';

enum ItemKind {
  card,
  question,

  /// Two terms the student keeps mixing up, side by side. Not asked, and not
  /// scheduled: it comes before the question that was missed.
  contrast,
}

/// What is being asked, in letters and digits only: so a flashcard and a quiz
/// question that ask the same thing in the same words are known to be one fact.
String practiceKey(String text) => text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// A flashcard or quiz question that could go into a practice session.
class Candidate {
  const Candidate({required this.kind, required this.itemId, required this.setId, this.schedule, this.key});

  final ItemKind kind;

  /// flashcard_rows.id or question_rows.id.
  final int itemId;
  final int setId;

  /// Null if it has never been answered.
  final Schedule? schedule;

  /// What it asks, from [practiceKey]. Two items with the same key are the same
  /// fact, and a session asks it only once. Null means unknown: never matched.
  final String? key;

  @override
  bool operator ==(Object other) => other is Candidate && other.kind == kind && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(kind, itemId);

  @override
  String toString() => '${kind.name}#$itemId(set $setId)';
}

/// How many items are waiting: due on the schedule, never seen, or not due yet.
/// Items already answered today are not waiting; they are counted apart, so a
/// finished day can say so.
class PracticeCounts {
  const PracticeCounts({this.due = 0, this.fresh = 0, this.ahead = 0, this.doneToday = 0});
  final int due, fresh, ahead;

  /// Not due yet, and answered today: nothing more to do with them until another day.
  final int doneToday;

  int get total => due + fresh + ahead;

  /// What a session of up to [size] items would hold: what is due first, then new
  /// items, then items that are not due yet; the same order [planSession] uses.
  PracticeCounts within(int size) {
    final d = due < size ? due : size;
    final f = fresh < size - d ? fresh : size - d;
    final a = ahead < size - d - f ? ahead : size - d - f;
    return PracticeCounts(due: d, fresh: f, ahead: a);
  }
}

/// The items for one session, and how many of them are due, new, or early.
class SessionPlan {
  const SessionPlan(this.items, {this.due = 0, this.fresh = 0, this.ahead = 0});
  final List<Candidate> items;
  final int due, fresh, ahead;
}

List<Candidate> _only(List<Candidate> all, int? setId) =>
    setId == null ? all : [for (final c in all) if (c.setId == setId) c];

/// True if [c] has been answered today.
bool _answeredToday(Candidate c, DateTime today) => c.schedule?.lastDay == today;

/// New items, spread so a session is not five cards from one set: the newest set
/// first, one item from each set in turn, and within a set a card and a question
/// in turn.
List<Candidate> _spread(List<Candidate> fresh) {
  final bySet = <int, List<Candidate>>{};
  for (final c in fresh) {
    bySet.putIfAbsent(c.setId, () => []).add(c);
  }
  final queues = <List<Candidate>>[];
  for (final setId in (bySet.keys.toList()..sort((a, b) => b.compareTo(a)))) {
    final cards = [for (final c in bySet[setId]!) if (c.kind == ItemKind.card) c]..sort((a, b) => a.itemId.compareTo(b.itemId));
    final questions = [for (final c in bySet[setId]!) if (c.kind == ItemKind.question) c]..sort((a, b) => a.itemId.compareTo(b.itemId));
    final mixed = <Candidate>[];
    for (var i = 0; i < cards.length || i < questions.length; i++) {
      if (i < cards.length) mixed.add(cards[i]);
      if (i < questions.length) mixed.add(questions[i]);
    }
    queues.add(mixed);
  }
  final out = <Candidate>[];
  for (var round = 0; queues.any((q) => round < q.length); round++) {
    for (final q in queues) {
      if (round < q.length) out.add(q[round]);
    }
  }
  return out;
}

/// Everything that could be asked today, in the order it would be asked, each
/// fact once.
class _Ordered {
  _Ordered(this.due, this.fresh, this.ahead, this.doneToday);
  final List<Candidate> due, fresh, ahead;
  final int doneToday;
}

_Ordered _order(List<Candidate> pool, DateTime today) {
  final due = <Candidate>[], fresh = <Candidate>[], ahead = <Candidate>[];
  final doneKeys = <String>{};
  var done = 0;
  for (final c in pool) {
    final s = c.schedule;
    if (s == null || s.dueDay == null) {
      fresh.add(c);
    } else if (s.isDueBy(today)) {
      due.add(c);
    } else if (_answeredToday(c, today)) {
      done++;
      if (c.key != null) doneKeys.add(c.key!);
    } else {
      ahead.add(c);
    }
  }
  due.sort((a, b) {
    final byDay = a.schedule!.dueDay!.compareTo(b.schedule!.dueDay!);
    if (byDay != 0) return byDay;
    final byLapses = b.schedule!.lapses.compareTo(a.schedule!.lapses);
    return byLapses != 0 ? byLapses : a.itemId.compareTo(b.itemId);
  });
  ahead.sort((a, b) {
    final byDay = a.schedule!.dueDay!.compareTo(b.schedule!.dueDay!);
    return byDay != 0 ? byDay : a.itemId.compareTo(b.itemId);
  });
  final spread = _spread(fresh);

  // Each fact once. What is due is always asked, so only another due item with the
  // same wording is dropped; what was answered today then keeps its other forms
  // (the card, the question) from being asked again today.
  final seen = <String>{};
  List<Candidate> once(List<Candidate> list) => [
        for (final c in list)
          if (c.key == null || seen.add(c.key!)) c,
      ];
  final dueOnce = once(due);
  seen.addAll(doneKeys);
  return _Ordered(dueOnce, once(spread), once(ahead), done);
}

PracticeCounts countFor(List<Candidate> all, DateTime now, {int? setId}) {
  final o = _order(_only(all, setId), dayOf(now));
  return PracticeCounts(due: o.due.length, fresh: o.fresh.length, ahead: o.ahead.length, doneToday: o.doneToday);
}

/// Picks up to [size] items for a session on [now]: what is due first, the most
/// overdue and the most often missed at the front; then new items to learn; then,
/// if there is still room, items that are not due yet, the soonest first, so a
/// student can always practice. Items answered today are left out of that last
/// group: asking again what was just asked is not practice. A fact that exists as
/// both a card and a question is asked once. With [setId], only that set's items.
SessionPlan planSession(List<Candidate> all, {required DateTime now, required int size, int? setId}) {
  final o = _order(_only(all, setId), dayOf(now));
  final takeDue = o.due.take(size).toList();
  final takeFresh = o.fresh.take(size - takeDue.length).toList();
  final takeAhead = o.ahead.take(size - takeDue.length - takeFresh.length).toList();
  return SessionPlan(
    [...takeDue, ...takeFresh, ...takeAhead],
    due: takeDue.length,
    fresh: takeFresh.length,
    ahead: takeAhead.length,
  );
}
