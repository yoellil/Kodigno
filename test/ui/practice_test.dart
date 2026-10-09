import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/data/review_repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/study/session_plan.dart';
import 'package:kodigno/ui/practice_card.dart';
import 'package:kodigno/ui/practice_screen.dart';
import 'package:kodigno/ui/slide_tag.dart';
import 'package:kodigno/ui/theme.dart';

/// Real time for the database to answer, and frames for the screen to draw it.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await t.pump(const Duration(milliseconds: 60));
  }
}

class _Env {
  _Env(this.db) : repo = StudyRepository(db), reviews = ReviewRepository(db);
  final AppDatabase db;
  final StudyRepository repo;
  final ReviewRepository reviews;
}

Future<_Env> _env(WidgetTester t) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1000, 1100);
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() => t.runAsync(db.close));
  return _Env(db);
}

Future<int> _save(WidgetTester t, _Env e, String title, GeneratedSet set) async =>
    (await t.runAsync(() => e.repo.saveSet(title, set)))!;

Future<void> _show(WidgetTester t, Widget home) async {
  await t.pumpWidget(MaterialApp(theme: kTheme(), home: home));
  await settle(t);
}

const _oneCard = GeneratedSet([], [Flashcard(front: 'What is a patent?', back: 'A right to exclude others')]);
const _oneQuestion = GeneratedSet([
  QuizQuestion(
    prompt: 'Which term fits?',
    choices: ['Fraud', 'Bribery', 'Whistle-blowing'],
    answerIndex: 2,
    explanation: 'Whistle-blowing draws attention to wrongdoing.',
  ),
], []);

Future<List<ReviewEntry>> _log(WidgetTester t, _Env e) async => (await t.runAsync(() => e.db.select(e.db.reviewLog).get()))!;

void main() {
  group('PracticeScreen', () {
    testWidgets('an empty library says there is nothing to practice', (t) async {
      final e = await _env(t);
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews));
      expect(find.text('Nothing to practice yet'), findsOneWidget);
    });

    testWidgets('a card: show the answer, say you got it, and it is recorded with a day to come back', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', _oneCard);
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews));

      expect(find.text('What is a patent?'), findsOneWidget);
      expect(find.text('A right to exclude others'), findsNothing); // the answer waits
      expect(find.text('1 of 1'), findsOneWidget);
      expect(find.textContaining('FLASHCARD · Module 3'), findsOneWidget);

      await t.tap(find.text('Show answer'));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('A right to exclude others'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      expect(find.text('Missed it'), findsOneWidget);

      await t.tap(find.text('Got it'));
      await settle(t);
      expect(find.text('practice complete'), findsOneWidget);
      expect(find.text('1 of 1'), findsOneWidget);
      expect(find.text('All right. Nice.'), findsOneWidget);

      final log = await _log(t, e);
      expect(log, hasLength(1));
      expect(log.single.correct, isTrue);
      expect(log.single.mode, 'practice');
      final state = (await t.runAsync(() => e.db.select(e.db.reviewStates).getSingle()))!;
      expect(state.box, 1);
      expect(t.takeException(), isNull);
    });

    testWidgets('a missed card comes back tomorrow and is listed with its answer to review', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', _oneCard);
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews));
      await t.tap(find.text('Show answer'));
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.text('Missed it'));
      await settle(t);

      expect(find.text('0 of 1'), findsOneWidget);
      expect(find.text('review these'), findsOneWidget);
      expect(find.text('Answer: A right to exclude others'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget); // back tomorrow
      final state = (await t.runAsync(() => e.db.select(e.db.reviewStates).getSingle()))!;
      expect(state.box, 0);
      expect(state.lapses, 1);
    });

    testWidgets('a question: a wrong choice shows the right one, why, and the choice is logged', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', _oneQuestion);
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews));

      expect(find.text('Which term fits?'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      await t.tap(find.text('Fraud')); // wrong on purpose
      await settle(t);
      expect(find.text('Not quite. The answer is Whistle-blowing.'), findsOneWidget);
      expect(find.text('Whistle-blowing draws attention to wrongdoing.'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget); // the only question, so Finish

      // the choices are now locked
      await t.tap(find.text('Bribery'));
      await settle(t);
      expect(await _log(t, e), hasLength(1));

      await t.tap(find.text('Finish'));
      await settle(t);
      expect(find.text('practice complete'), findsOneWidget);
      final log = (await _log(t, e)).single;
      expect(log.chosen, 0);
      expect(log.correct, isFalse);
    });

    testWidgets('a right choice says Correct', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', _oneQuestion);
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews));
      await t.tap(find.text('Whistle-blowing'));
      await settle(t);
      expect(find.text('Correct'), findsOneWidget);
      expect((await _log(t, e)).single.correct, isTrue);
    });

    testWidgets('the length sets how many items: 2 minutes is 3 of a bigger set', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Big', GeneratedSet(const [], [for (var i = 1; i <= 8; i++) Flashcard(front: 'f$i', back: 'b$i')]));
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews, minutes: 2));
      expect(find.text('1 of 3'), findsOneWidget);
    });

    testWidgets('only the chosen set is practiced', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Other', const GeneratedSet([], [Flashcard(front: 'other front', back: 'other back')]));
      final mine = await _save(t, e, 'Mine', _oneCard);
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews, setId: mine));
      expect(find.text('1 of 1'), findsOneWidget);
      expect(find.text('What is a patent?'), findsOneWidget);
    });

    testWidgets('Space shows the answer', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', _oneCard);
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews));
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('A right to exclude others'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 500)); // let the answer finish animating in
    });

    testWidgets('Enter moves on after a question has been answered', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', const GeneratedSet([
        QuizQuestion(prompt: 'First?', choices: ['a', 'b'], answerIndex: 0),
        QuizQuestion(prompt: 'Second?', choices: ['a', 'b'], answerIndex: 0),
      ], []));
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews));
      final first = find.text('First?').evaluate().isNotEmpty ? 'First?' : 'Second?';
      await t.sendKeyEvent(LogicalKeyboardKey.enter); // nothing answered yet: nothing happens
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text(first), findsOneWidget);
      await t.tap(find.text('a'));
      await settle(t);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(t);
      expect(find.text('2 of 2'), findsOneWidget);
    });

    testWidgets('Practice more starts another session', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Big', GeneratedSet(const [], [for (var i = 1; i <= 4; i++) Flashcard(front: 'f$i', back: 'b$i')]));
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews, minutes: 2));
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text('Show answer'));
        await t.pump(const Duration(milliseconds: 500));
        await t.tap(find.text('Got it'));
        await settle(t);
      }
      expect(find.text('practice complete'), findsOneWidget);
      await t.tap(find.text('Practice more'));
      await settle(t);
      expect(find.text('1 of 1'), findsOneWidget); // the one new card left; the three just done are not asked again
      expect(find.text('practice complete'), findsNothing);
    });

    testWidgets('a card from a PDF shows where its answer comes from', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', const GeneratedSet([], [
        Flashcard(
          front: 'What is a patent?',
          back: 'A right to exclude others',
          source: SourceRef(kind: SourceKind.copied, pages: [16], score: 1, quote: 'A patent permits its owner'),
        ),
      ]));
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews));
      expect(find.byType(SlideTag), findsNothing); // not before the answer
      await t.tap(find.text('Show answer'));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Slide 16'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 500)); // let the answer finish animating in
    });

    testWidgets('when everything has been answered today, Practice more says it is all done', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', _oneCard);
      await _show(t, PracticeScreen(repo: e.repo, reviews: e.reviews));
      await t.tap(find.text('Show answer'));
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.text('Got it'));
      await settle(t);
      await t.tap(find.text('Practice more'));
      await settle(t);
      expect(find.text('All done for today'), findsOneWidget);
      expect(find.text('Nothing to practice yet'), findsNothing);
    });
  });

  group('practiceSummary', () {
    test('says how many items, how long, and what kind', () {
      final s = practiceSummary(const PracticeCounts(due: 2, fresh: 6), 5);
      expect(s.headline, '5 items · about 3 min');
      expect(s.detail, '2 due · 3 new');
    });

    test('a short session is fewer items', () {
      expect(practiceSummary(const PracticeCounts(due: 9), 2).headline, '3 items · about 2 min');
      expect(practiceSummary(const PracticeCounts(due: 9), 10).headline, '9 items · about 6 min');
    });

    test('one item is "item", not "items"', () {
      expect(practiceSummary(const PracticeCounts(due: 1), 5).headline, '1 item · about 1 min');
    });

    test('with only early items it says nothing is due', () {
      final s = practiceSummary(const PracticeCounts(ahead: 4), 5);
      expect(s.headline, 'Nothing due today');
      expect(s.detail, startsWith('Practice ahead: 4 items'));
    });

    test('with nothing at all it says so', () {
      expect(practiceSummary(const PracticeCounts(), 5).headline, 'Nothing to practice yet');
    });

    test('with everything answered today it says the day is done, not that there is nothing', () {
      final s = practiceSummary(const PracticeCounts(doneToday: 6), 5);
      expect(s.headline, 'All done for today');
      expect(s.detail, contains('another day'));
    });

    test('early items that fill the room are mentioned', () {
      expect(practiceSummary(const PracticeCounts(due: 1, ahead: 8), 5).detail, '1 due · 4 to revisit early');
    });
  });

  group('PracticeCard', () {
    Future<List<StudySet>> sets(WidgetTester t, _Env e) async =>
        (await t.runAsync(() => e.db.select(e.db.studySets).get()))!;

    Future<void> card(WidgetTester t, _Env e, List<StudySet> list, void Function(int, int?) onStart, {Object? snapshot}) =>
        _show(t, Scaffold(body: PracticeCard(reviews: e.reviews, sets: list, snapshot: snapshot ?? Object(), onStart: onStart)));

    testWidgets('shows what is waiting, and Start passes the length and set', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', GeneratedSet(const [], [for (var i = 1; i <= 8; i++) Flashcard(front: 'f$i', back: 'b$i')]));
      (int, int?)? started;
      await card(t, e, await sets(t, e), (m, s) => started = (m, s));
      expect(find.text("Today's practice"), findsOneWidget);
      expect(find.text('5 items · about 3 min'), findsOneWidget);
      expect(find.text('5 new'), findsOneWidget);

      await t.tap(find.text('Start'));
      expect(started, (5, null));
    });

    testWidgets('picking a length changes the counts and what Start passes', (t) async {
      final e = await _env(t);
      await _save(t, e, 'Module 3', GeneratedSet(const [], [for (var i = 1; i <= 12; i++) Flashcard(front: 'f$i', back: 'b$i')]));
      (int, int?)? started;
      await card(t, e, await sets(t, e), (m, s) => started = (m, s));

      await t.tap(find.text('2 min'));
      await settle(t);
      expect(find.text('3 items · about 2 min'), findsOneWidget);
      await t.tap(find.text('10 min'));
      await settle(t);
      expect(find.text('10 items · about 6 min'), findsOneWidget);
      await t.tap(find.text('Start'));
      expect(started, (10, null));
    });

    testWidgets('with one set there is no set picker; with several there is, and it limits the counts', (t) async {
      final e = await _env(t);
      final a = await _save(t, e, 'Alpha', GeneratedSet(const [], [for (var i = 1; i <= 2; i++) Flashcard(front: 'a$i', back: 'x')]));
      (int, int?)? started;
      await card(t, e, await sets(t, e), (m, s) => started = (m, s));
      expect(find.text('All sets'), findsNothing);

      await _save(t, e, 'Beta', GeneratedSet(const [], [for (var i = 1; i <= 9; i++) Flashcard(front: 'b$i', back: 'x')]));
      await card(t, e, await sets(t, e), (m, s) => started = (m, s), snapshot: Object());
      expect(find.text('All sets'), findsOneWidget);
      expect(find.text('5 items · about 3 min'), findsOneWidget);

      await t.tap(find.text('All sets'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('Alpha').last);
      await settle(t);
      expect(find.text('2 items · about 2 min'), findsOneWidget);
      await t.tap(find.text('Start'));
      expect(started, (5, a));
    });

    testWidgets('nothing to practice: it says so and Start is off', (t) async {
      final e = await _env(t);
      var started = false;
      await card(t, e, const [], (_, _) => started = true);
      expect(find.text('Nothing to practice yet'), findsOneWidget);
      await t.tap(find.text('Start'), warnIfMissed: false);
      expect(started, isFalse);
    });

    testWidgets('a new snapshot makes it read the counts again', (t) async {
      final e = await _env(t);
      final id = await _save(t, e, 'Module 3', GeneratedSet(const [], [for (var i = 1; i <= 2; i++) Flashcard(front: 'f$i', back: 'b$i')]));
      await card(t, e, await sets(t, e), (_, _) {});
      expect(find.text('2 items · about 2 min'), findsOneWidget);
      await t.runAsync(() async {
        final cards = await e.db.select(e.db.flashcardRows).get();
        await e.reviews.record(
            kind: ItemKind.card, itemId: cards.first.id, setId: id, correct: true, mode: 'practice', now: DateTime.now());
      });
      await card(t, e, await sets(t, e), (_, _) {}, snapshot: Object());
      expect(find.text('1 item · about 1 min'), findsOneWidget); // the one answered today is not offered again
      expect(find.text('1 new'), findsOneWidget);
    });
  });
}
