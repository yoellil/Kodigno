import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/data/review_repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/study/confusions.dart';
import 'package:kodigno/study/practice_session.dart';
import 'package:kodigno/study/session_plan.dart';

final _notes = [
  pageMarker(14),
  'Fraud\n- Crime of obtaining goods, services, or property through deception or trickery.',
  '',
  pageMarker(16),
  'Breach of contract\n- One party fails to meet the terms of a contract that was agreed between them.',
  '',
  pageMarker(30),
  'Whistle-blowing\n- Attracts attention to a negligent, illegal, unethical, abusive, or dangerous act.',
].join('\n');

// choices: 0 Fraud, 1 Breach of contract (right), 2 Vandalism
const _q1 = QuizQuestion(prompt: 'Which term is this? One party fails to meet the terms.', choices: ['Fraud', 'Breach of contract', 'Vandalism'], answerIndex: 1);
const _q2 = QuizQuestion(prompt: 'Which term fits a failure to keep a promise?', choices: ['Breach of contract', 'Fraud', 'Bribery'], answerIndex: 0);

PracticeItem _item(ItemKind k, int id, {ContrastCard? contrast}) => PracticeItem(
    kind: k, itemId: id, setId: 1, setTitle: 'S', prompt: 'p$id', answer: 'a$id', choices: const ['a', 'b'], answerIndex: 1, contrast: contrast);

ContrastCard get _card => const ContrastCard(
      a: ContrastSide(term: 'Breach of contract', text: 'One party fails.', page: 16),
      b: ContrastSide(term: 'Fraud', text: 'Crime of obtaining goods.', page: 14),
      times: 2,
      questionId: 1,
      setId: 1,
    );

void main() {
  group('PracticeSession with a contrast card', () {
    PracticeSession make(List<PracticeItem> items, List<(ItemKind, bool)> log) =>
        PracticeSession(items, (item, correct, chosen) async => log.add((item.kind, correct)));

    test('counts only the items that are asked', () {
      final s = make([_item(ItemKind.contrast, 1, contrast: _card), _item(ItemKind.question, 1), _item(ItemKind.card, 2)], []);
      expect(s.total, 3);
      expect(s.gradedTotal, 2);
      expect(s.gradedIndex, 0);
      expect(s.isInterlude, isTrue);
      expect(s.isLastGraded, isFalse);
    });

    test('acknowledging notes it, adds nothing to the score or the missed list, and lets the session move on', () async {
      final log = <(ItemKind, bool)>[];
      final s = make([_item(ItemKind.contrast, 1, contrast: _card), _item(ItemKind.question, 1)], log);
      await s.acknowledge();
      expect(log, [(ItemKind.contrast, true)]);
      expect(s.answered, isTrue);
      expect(s.correctCount, 0);
      expect(s.missed, isEmpty);
      s.next();
      expect(s.isInterlude, isFalse);
      expect(s.gradedIndex, 0);
      expect(s.current.kind, ItemKind.question);
      expect(s.isLastGraded, isTrue);
    });

    test('a contrast card cannot be answered right or wrong, and can be acknowledged only once', () async {
      final log = <(ItemKind, bool)>[];
      final s = make([_item(ItemKind.contrast, 1, contrast: _card), _item(ItemKind.question, 1)], log);
      await s.answer(correct: false);
      await s.choose(0);
      expect(log, isEmpty);
      await Future.wait([s.acknowledge(), s.acknowledge()]);
      expect(log, hasLength(1));
    });

    test('a question cannot be acknowledged', () async {
      final log = <(ItemKind, bool)>[];
      final s = make([_item(ItemKind.question, 1)], log);
      await s.acknowledge();
      expect(log, isEmpty);
      expect(s.answered, isFalse);
    });

    test('the score is out of the asked items, whatever comes between', () async {
      final s = make([_item(ItemKind.contrast, 1, contrast: _card), _item(ItemKind.question, 1), _item(ItemKind.card, 2)], []);
      await s.acknowledge();
      s.next();
      await s.choose(1); // right: the answer is 1
      s.next();
      await s.answer(correct: false);
      s.next();
      expect(s.isDone, isTrue);
      expect(s.correctCount, 1);
      expect(s.gradedTotal, 2);
      expect(s.missed, hasLength(1));
    });

    test('a session without a contrast card counts as before', () {
      final s = make([_item(ItemKind.card, 1), _item(ItemKind.card, 2)], []);
      expect(s.gradedTotal, s.total);
      expect(s.gradedIndex, s.index);
      expect(s.isInterlude, isFalse);
    });

    test('if noting it fails, the session carries on and says so', () async {
      final s = PracticeSession([_item(ItemKind.contrast, 1, contrast: _card), _item(ItemKind.question, 1)], (_, _, _) async => throw StateError('x'));
      await s.acknowledge();
      expect(s.saveFailed, isTrue);
      s.next();
      expect(s.current.kind, ItemKind.question);
    });
  });

  group('patterns and contrast cards from the history', () {
    late AppDatabase db;
    late StudyRepository repo;
    late ReviewRepository reviews;
    late int setId;
    late List<QuestionRow> questions;
    final monday = DateTime(2026, 10, 12, 9);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = StudyRepository(db);
      reviews = ReviewRepository(db);
      setId = await repo.saveSet('Module 3', const GeneratedSet([_q1, _q2], [Flashcard(front: 'f1', back: 'b1'), Flashcard(front: 'f2', back: 'b2')]),
          sourceType: 'pdf', sourceText: _notes);
      questions = (await repo.getSet(setId)).questions..sort((a, b) => a.id.compareTo(b.id));
    });
    tearDown(() => db.close());

    Future<void> wrong(int qi, int chosen, DateTime at, {int? set}) => reviews.record(
        kind: ItemKind.question, itemId: questions[qi].id, setId: set ?? setId, correct: false, chosen: chosen, mode: 'quiz', now: at);

    test('wrongPicks gives the choice picked and the right one, oldest first', () async {
      await wrong(0, 0, monday);
      await wrong(1, 1, monday.add(const Duration(minutes: 1)));
      await reviews.record(kind: ItemKind.question, itemId: questions[0].id, setId: setId, correct: true, chosen: 1, mode: 'quiz', now: monday);
      final picks = await reviews.wrongPicks();
      expect(picks.map((p) => (p.picked, p.answer)), [('Fraud', 'Breach of contract'), ('Fraud', 'Breach of contract')]);
      expect(picks.map((p) => p.questionId), [questions[0].id, questions[1].id]);
      expect(await reviews.wrongPicks(setId: setId + 9), isEmpty);
    });

    test('a pair mixed up twice is a pattern; once is not', () async {
      await wrong(0, 0, monday);
      expect(await reviews.confusions(), isEmpty);
      await wrong(1, 1, monday.add(const Duration(days: 1)));
      final c = (await reviews.confusions()).single;
      expect(c.times, 2);
      expect({c.a, c.b}, {'Fraud', 'Breach of contract'});
      expect(c.questionId, questions[1].id);
      expect(c.setId, setId);
    });

    test('it settles when the questions are then answered right twice in a row', () async {
      await wrong(0, 0, monday);
      await wrong(1, 1, monday);
      for (final qi in [0, 1]) {
        for (final day in [14, 15]) {
          await reviews.record(
              kind: ItemKind.question, itemId: questions[qi].id, setId: setId, correct: true, chosen: qi == 0 ? 1 : 0, mode: 'practice', now: DateTime(2026, 10, day, 9));
        }
      }
      expect(await reviews.confusions(), isEmpty);
    });

    test('contrastFor puts the two terms side by side with what the slides say', () async {
      await wrong(0, 0, monday);
      await wrong(1, 1, monday);
      final card = (await reviews.contrastFor((await reviews.confusions()).single))!;
      expect(card.times, 2);
      final sides = {for (final s in [card.a, card.b]) s.term: s};
      expect(sides['Fraud']!.page, 14);
      expect(sides['Fraud']!.text, startsWith('Crime of obtaining goods'));
      expect(sides['Breach of contract']!.page, 16);
      expect(sides['Breach of contract']!.text, startsWith('One party fails'));
    });

    test('a set with no pages has no contrast card, though the pattern is still found', () async {
      final plain = await repo.saveSet('Word file', const GeneratedSet([_q1], []), sourceText: 'Plain notes, no pages at all.');
      final q = (await repo.getSet(plain)).questions.single;
      for (final d in [10, 11]) {
        await reviews.record(kind: ItemKind.question, itemId: q.id, setId: plain, correct: false, chosen: 0, mode: 'quiz', now: DateTime(2026, 10, d));
      }
      final c = (await reviews.confusions(setId: plain)).single;
      expect(await reviews.contrastFor(c), isNull);
    });

    test('the session starts with the card, then the question that was missed', () async {
      await wrong(0, 0, monday);
      await wrong(1, 1, monday);
      final start = await reviews.startSession(size: 5, now: DateTime(2026, 10, 13, 9));
      expect(start.items.first.kind, ItemKind.contrast);
      expect(start.items.first.contrast!.times, 2);
      expect(start.items[1].kind, ItemKind.question);
      expect(start.items[1].itemId, questions[1].id); // the one missed most recently
      expect(start.items.where((i) => i.kind == ItemKind.contrast), hasLength(1));
    });

    test('the question is not asked twice when it was already in the session', () async {
      await wrong(0, 0, monday);
      await wrong(1, 1, monday); // it is due on the 13th
      final start = await reviews.startSession(size: 5, now: DateTime(2026, 10, 13, 9));
      expect(start.items.where((i) => i.kind == ItemKind.question && i.itemId == questions[1].id), hasLength(1));
    });

    test('a full session keeps its size: the question to ask again takes the last place', () async {
      await wrong(0, 0, monday);
      await wrong(1, 1, monday);
      // both questions are due, but a session of one holds only the first; the pair's question is the second
      final start = await reviews.startSession(size: 1, now: DateTime(2026, 10, 13, 9));
      expect(start.items.map((i) => i.kind), [ItemKind.contrast, ItemKind.question]);
      expect(start.items[1].itemId, questions[1].id);
      expect(start.items.where((i) => i.kind != ItemKind.contrast), hasLength(1)); // still one asked
    });

    test('with room to spare the question is added without taking another item place', () async {
      await repo.saveSet('Extra', const GeneratedSet([], [Flashcard(front: 'e1', back: 'x'), Flashcard(front: 'e2', back: 'x')]), sourceText: 'Extra plain notes only.');
      await wrong(0, 0, monday);
      await wrong(1, 1, monday);
      final start = await reviews.startSession(size: 10, now: DateTime(2026, 10, 13, 9));
      final asked = start.items.where((i) => i.kind != ItemKind.contrast).toList();
      expect(asked.where((i) => i.kind == ItemKind.question && i.itemId == questions[1].id), hasLength(1));
      expect(asked.length, start.plan.items.length); // everything planned is still there
    });

    test('once seen today it is not shown again today, but is again tomorrow', () async {
      await wrong(0, 0, monday);
      await wrong(1, 1, monday);
      final day = DateTime(2026, 10, 13, 9);
      var start = await reviews.startSession(size: 5, now: day);
      final card = start.items.first;
      await reviews.recordPractice(card, true, null, now: day);
      expect(await reviews.contrastShownOn(questions[1].id, day.add(const Duration(hours: 5))), isTrue);
      start = await reviews.startSession(size: 5, now: day.add(const Duration(hours: 5)));
      expect(start.items.where((i) => i.kind == ItemKind.contrast), isEmpty);
      start = await reviews.startSession(size: 5, now: DateTime(2026, 10, 14, 9));
      expect(start.items.first.kind, ItemKind.contrast);
    });

    test('seeing the card is only noted in the log: it is not an answer and moves no schedule', () async {
      await wrong(0, 0, monday);
      await wrong(1, 1, monday);
      final before = (await db.select(db.reviewStates).get()).length;
      final start = await reviews.startSession(size: 5, now: DateTime(2026, 10, 13, 9));
      await reviews.recordPractice(start.items.first, true, null, now: DateTime(2026, 10, 13, 9));
      expect((await db.select(db.reviewStates).get()).length, before);
      final log = (await db.select(db.reviewLog).get()).last;
      expect(log.kind, 'contrast');
      expect(log.correct, isTrue);
      // and it does not look like a wrong pick, or a right one, to anything that reads the log
      expect((await reviews.wrongPicks()).length, 2);
      expect((await reviews.wrongPickCounts()).values.expand((m) => m.values).fold<int>(0, (a, b) => a + b), 2);
    });

    test('no session has a card without a pattern, and the limit can be turned off', () async {
      expect((await reviews.startSession(size: 5, now: monday)).items.where((i) => i.kind == ItemKind.contrast), isEmpty);
      await wrong(0, 0, monday);
      await wrong(1, 1, monday);
      expect((await reviews.startSession(size: 5, now: DateTime(2026, 10, 13), contrastLimit: 0)).items.where((i) => i.kind == ItemKind.contrast), isEmpty);
    });

    test('a card does not appear for a set the session was not limited to', () async {
      final other = await repo.saveSet('Other', const GeneratedSet([], [Flashcard(front: 'x', back: 'y')]), sourceText: 'Other plain notes only.');
      await wrong(0, 0, monday);
      await wrong(1, 1, monday);
      final start = await reviews.startSession(size: 5, setId: other, now: DateTime(2026, 10, 13, 9));
      expect(start.items.where((i) => i.kind == ItemKind.contrast), isEmpty);
    });
  });
}
