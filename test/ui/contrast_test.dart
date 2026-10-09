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
import 'package:kodigno/ui/practice_screen.dart';
import 'package:kodigno/ui/theme.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 14; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await t.pump(const Duration(milliseconds: 70));
  }
}

final _notes = [
  pageMarker(14),
  'Fraud\n- Crime of obtaining goods, services, or property through deception or trickery.',
  '',
  pageMarker(16),
  'Breach of contract\n- One party fails to meet the terms of a contract that was agreed between them.',
].join('\n');

// 0 Fraud, 1 Breach of contract (right), 2 Vandalism
const _q1 = QuizQuestion(prompt: 'Which term is this? One party fails to meet the terms.', choices: ['Fraud', 'Breach of contract', 'Vandalism'], answerIndex: 1);
// 0 Breach of contract (right), 1 Fraud, 2 Bribery
const _q2 = QuizQuestion(prompt: 'Which term fits a failure to keep a promise?', choices: ['Breach of contract', 'Fraud', 'Bribery'], answerIndex: 0);

class _Env {
  _Env(this.db, this.repo, this.reviews, this.setId, this.questions);
  final AppDatabase db;
  final StudyRepository repo;
  final ReviewRepository reviews;
  final int setId;
  final List<QuestionRow> questions;
}

/// A set with two questions that Fraud and Breach of contract were each picked for, wrongly, on
/// [mixedUp] separate earlier days: a pattern, with the questions due today.
Future<_Env> _env(WidgetTester t, {String notes = '', int mixedUp = 2}) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1000, 1300);
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() => t.runAsync(db.close));
  final repo = StudyRepository(db);
  final reviews = ReviewRepository(db);
  final id = (await t.runAsync(() => repo.saveSet('Module 3', const GeneratedSet([_q1, _q2], []),
      sourceType: 'pdf', sourceText: notes, sourcePaths: ['C:/none.pdf'])))!;
  final qs = (await t.runAsync(() async => (await repo.getSet(id)).questions..sort((a, b) => a.id.compareTo(b.id))))!;
  await t.runAsync(() async {
    for (var i = 0; i < mixedUp; i++) {
      // Fraud picked for q1 (wrong), Fraud picked for q2 (wrong): the same pair either way
      final q = i.isEven ? 0 : 1;
      await reviews.record(
          kind: ItemKind.question, itemId: qs[q].id, setId: id, correct: false, chosen: q == 0 ? 0 : 1, mode: 'quiz',
          now: DateTime.now().subtract(Duration(days: 3 - i)));
    }
  });
  return _Env(db, repo, reviews, id, qs);
}

Future<void> _open(WidgetTester t, _Env e, {int minutes = 5}) async {
  await t.pumpWidget(MaterialApp(
      theme: kTheme(), home: PracticeScreen(repo: e.repo, reviews: e.reviews, setId: e.setId, minutes: minutes)));
  await settle(t);
}

void main() {
  testWidgets('a pattern opens the session with the two terms side by side, then asks the question', (t) async {
    final e = await _env(t, notes: _notes);
    await _open(t, e);

    expect(find.textContaining('EASY TO MIX UP · Module 3'), findsOneWidget);
    expect(find.text('You have mixed up these 2 times. Here is what your slides say about each.'), findsOneWidget);
    expect(find.text('Fraud'), findsOneWidget);
    expect(find.text('Breach of contract'), findsOneWidget);
    expect(find.textContaining('Crime of obtaining goods'), findsOneWidget);
    expect(find.textContaining('One party fails to meet the terms of a contract'), findsOneWidget);
    expect(find.text('Slide 14'), findsOneWidget);
    expect(find.text('Slide 16'), findsOneWidget);
    expect(find.text('Ask me again'), findsOneWidget);
    // it is not a question: no choices yet, and the counter is of the asked items
    expect(find.text('Vandalism'), findsNothing);
    expect(find.text('1 of 2'), findsOneWidget);

    await t.tap(find.text('Ask me again'));
    await settle(t);
    expect(find.textContaining('QUESTION · Module 3'), findsOneWidget);
    expect(find.text('Which term fits a failure to keep a promise?'), findsOneWidget); // the one missed last
    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.text('Ask me again'), findsNothing);
  });

  testWidgets('seeing the card is noted, and it does not show again the same day', (t) async {
    final e = await _env(t, notes: _notes);
    await _open(t, e);
    await t.tap(find.text('Ask me again'));
    await settle(t);
    final log = (await t.runAsync(() => e.db.select(e.db.reviewLog).get()))!;
    expect(log.where((l) => l.kind == 'contrast'), hasLength(1));

    // open practice again: today's card has been seen
    await _open(t, e);
    expect(find.textContaining('EASY TO MIX UP'), findsNothing);
  });

  testWidgets('Space gets past the card', (t) async {
    final e = await _env(t, notes: _notes);
    await _open(t, e);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await settle(t);
    expect(find.textContaining('QUESTION · Module 3'), findsOneWidget);
  });

  testWidgets('mixing them up again shows the pattern at the end, now one more time', (t) async {
    final e = await _env(t, notes: _notes);
    await _open(t, e);
    await t.tap(find.text('Ask me again'));
    await settle(t);
    await t.tap(find.text('Fraud')); // wrong again: the answer is Breach of contract
    await settle(t);
    // the other question may come next; go through whatever is left
    for (var i = 0; i < 3 && find.text('practice complete').evaluate().isEmpty; i++) {
      final next = find.text('Next').evaluate().isNotEmpty ? 'Next' : 'Finish';
      await t.tap(find.text(next));
      await settle(t);
      if (find.text('practice complete').evaluate().isEmpty) {
        final choice = find.text('Vandalism').evaluate().isNotEmpty ? 'Vandalism' : 'Bribery';
        await t.tap(find.text(choice));
        await settle(t);
      }
    }
    expect(find.text('practice complete'), findsOneWidget);
    expect(find.text('patterns'), findsOneWidget);
    expect(find.text('You have mixed up "Breach of contract" and "Fraud" 3 times.'), findsOneWidget);
    expect(find.text('A side-by-side comparison will come up in your next practice.'), findsOneWidget);
  });

  testWidgets('getting it right at the end shows no pattern', (t) async {
    final e = await _env(t, notes: _notes);
    await _open(t, e);
    await t.tap(find.text('Ask me again'));
    await settle(t);
    await t.tap(find.text('Breach of contract')); // right for q2
    await settle(t);
    for (var i = 0; i < 3 && find.text('practice complete').evaluate().isEmpty; i++) {
      final next = find.text('Next').evaluate().isNotEmpty ? 'Next' : 'Finish';
      await t.tap(find.text(next));
      await settle(t);
      if (find.text('practice complete').evaluate().isEmpty) {
        await t.tap(find.text('Breach of contract').evaluate().isNotEmpty ? find.text('Breach of contract') : find.text('Vandalism'));
        await settle(t);
      }
    }
    expect(find.text('practice complete'), findsOneWidget);
    expect(find.text('patterns'), findsNothing);
  });

  testWidgets('a mix-up that happened only once is not a pattern: no card', (t) async {
    final e = await _env(t, notes: _notes, mixedUp: 1);
    await _open(t, e);
    expect(find.textContaining('EASY TO MIX UP'), findsNothing);
    expect(find.textContaining('QUESTION · Module 3'), findsOneWidget);
  });

  testWidgets('a set made from a Word file (no pages) has no card, and nothing fails', (t) async {
    final e = await _env(t, notes: 'Plain notes with no pages at all.');
    await _open(t, e);
    expect(find.textContaining('EASY TO MIX UP'), findsNothing);
    expect(find.textContaining('QUESTION · Module 3'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('on a narrow window the two sides stack instead of overflowing', (t) async {
    final e = await _env(t, notes: _notes);
    t.view.physicalSize = const Size(420, 1100);
    await _open(t, e);
    expect(find.text('Fraud'), findsOneWidget);
    expect(find.text('Breach of contract'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('the tags on the card open the slides', (t) async {
    final e = await _env(t, notes: _notes);
    await _open(t, e);
    await t.tap(find.text('Slide 14'));
    await t.pumpAndSettle();
    expect(find.text('Slide 14 of Module 3'), findsOneWidget);
  });
}
