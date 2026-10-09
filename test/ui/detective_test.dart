import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/data/review_repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/study/diagnosis.dart';
import 'package:kodigno/study/session_plan.dart';
import 'package:kodigno/ui/diagnosis_line.dart';
import 'package:kodigno/ui/practice_screen.dart';
import 'package:kodigno/ui/quiz_screen.dart';
import 'package:kodigno/ui/slide_tag.dart';
import 'package:kodigno/ui/theme.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await t.pump(const Duration(milliseconds: 60));
  }
}

/// A PDF's text as the app stores it, with a marker before each page.
final _notes = [
  pageMarker(14),
  'Fraud\n- Crime of obtaining goods, services, or property through deception or trickery.',
  '',
  pageMarker(16),
  'Breach of contract\n- One party fails to meet the terms of a contract.',
  '',
  pageMarker(30),
  'Whistle-blowing\n- Attracts attention to a negligent, illegal, unethical, abusive, or dangerous act.',
].join('\n');

// Which term fits? answer: Breach of contract (slide 16). Fraud is on slide 14 (close by).
const _question = QuizQuestion(
  prompt: 'Which term is this? One party fails to meet the terms.',
  choices: ['Fraud', 'Breach of contract', 'Vandalism'],
  answerIndex: 1,
  explanation: 'Breach of contract: One party fails to meet the terms of a contract.',
  source: SourceRef(kind: SourceKind.copied, pages: [16], score: 1, quote: 'One party fails to meet the terms of a contract.'),
);

Future<(AppDatabase, StudyRepository, int)> _env(WidgetTester t, {String notes = ''}) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1000, 1200);
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() => t.runAsync(db.close));
  final repo = StudyRepository(db);
  final id = (await t.runAsync(() => repo.saveSet('Module 3', const GeneratedSet([_question], []),
      sourceType: 'pdf', sourceText: notes, sourcePaths: ['C:/none.pdf'])))!;
  return (db, repo, id);
}

void main() {
  group('DiagnosisLine', () {
    final index = PageIndex(parsePages(_notes));
    Diagnosis? dg(int chosen, {int earlier = 0}) => diagnose(
        choices: _question.choices, answerIndex: 1, chosen: chosen, pages: index, questionSource: _question.source, earlierPicks: earlier);

    testWidgets('says where the pick came from, with a tag for the pick and one for the answer', (t) async {
      t.view.devicePixelRatio = 1.0;
      t.view.physicalSize = const Size(900, 800);
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(theme: kTheme(), home: Scaffold(body: DiagnosisLine(dg(0)))));
      expect(find.text('WHERE YOUR PICK CAME FROM'), findsOneWidget);
      expect(find.textContaining('You picked "Fraud" (slide 14)'), findsOneWidget);
      expect(find.text('Your pick'), findsOneWidget);
      expect(find.text('Answer'), findsOneWidget);
      expect(find.text('Slide 14'), findsOneWidget);
      expect(find.text('Slide 16'), findsOneWidget);
    });

    testWidgets('a pick that is not in the slides has no tag for the pick', (t) async {
      await t.pumpWidget(MaterialApp(theme: kTheme(), home: Scaffold(body: DiagnosisLine(dg(2)))));
      expect(find.textContaining('not in your slides'), findsOneWidget);
      expect(find.text('Your pick'), findsNothing);
      expect(find.text('Answer'), findsOneWidget);
    });

    testWidgets('says so when it was picked before', (t) async {
      await t.pumpWidget(MaterialApp(theme: kTheme(), home: Scaffold(body: DiagnosisLine(dg(0, earlier: 1)))));
      expect(find.textContaining('You picked it before, too.'), findsOneWidget);
    });

    testWidgets('nothing at all when there is nothing to say', (t) async {
      await t.pumpWidget(MaterialApp(theme: kTheme(), home: const Scaffold(body: DiagnosisLine(null))));
      expect(find.text('WHERE YOUR PICK CAME FROM'), findsNothing);
      final none = diagnose(choices: const ['a', 'b'], answerIndex: 0, chosen: 1, pages: PageIndex(const []));
      await t.pumpWidget(MaterialApp(theme: kTheme(), home: Scaffold(body: DiagnosisLine(none))));
      expect(find.text('WHERE YOUR PICK CAME FROM'), findsNothing); // no pages: no message
    });

    testWidgets('a tag opens the slide', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: kTheme(),
        home: Scaffold(
          body: SourceScope(title: 'Module 3', paths: const [], pages: parsePages(_notes), child: DiagnosisLine(dg(0))),
        ),
      ));
      await t.tap(find.text('Slide 14'));
      await t.pumpAndSettle();
      expect(find.text('Slide 14 of Module 3'), findsOneWidget);
    });
  });

  group('the quiz results', () {
    Future<void> miss(WidgetTester t, {Map<int, Map<int, int>> before = const {}}) async {
      await t.pumpWidget(MaterialApp(
        theme: kTheme(),
        home: Scaffold(
          body: SourceScope(
            title: 'Module 3',
            paths: const [],
            pages: parsePages(_notes),
            child: QuizBody(
              title: 'Contracts',
              questions: const [_question],
              earlierPicks: (q, c) => before[q]?[c] ?? 0,
              onFinished: (_, _, _, _) {},
            ),
          ),
        ),
      ));
      await t.tap(find.text('Fraud')); // wrong on purpose
      await t.pump();
      await t.tap(find.text('Finish'));
      await t.pumpAndSettle();
    }

    testWidgets('a missed question says where the pick came from', (t) async {
      await miss(t);
      expect(find.textContaining('You picked "Fraud" (slide 14). The answer, "Breach of contract", is on slide 16, close by.'), findsOneWidget);
      expect(find.textContaining('before, too'), findsNothing);
    });

    testWidgets('and says so when the same wrong choice was picked before', (t) async {
      await miss(t, before: {0: {0: 2}});
      expect(find.textContaining('You picked it before, too.'), findsOneWidget);
    });

    testWidgets('a right answer is not diagnosed', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: kTheme(),
        home: Scaffold(
          body: SourceScope(
            title: 'Module 3', paths: const [], pages: parsePages(_notes),
            child: QuizBody(title: 'Contracts', questions: const [_question], onFinished: (_, _, _, _) {}),
          ),
        ),
      ));
      await t.tap(find.text('Breach of contract'));
      await t.pump();
      await t.tap(find.text('Finish'));
      await t.pumpAndSettle();
      expect(find.text('WHERE YOUR PICK CAME FROM'), findsNothing);
    });

    testWidgets('a set without pages (a Word file) says nothing and does not fail', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: kTheme(),
        home: Scaffold(
          body: QuizBody(title: 'Contracts', questions: const [_question], onFinished: (_, _, _, _) {}),
        ),
      ));
      await t.tap(find.text('Fraud'));
      await t.pump();
      await t.tap(find.text('Finish'));
      await t.pumpAndSettle();
      expect(find.text('review these'), findsOneWidget);
      expect(find.text('WHERE YOUR PICK CAME FROM'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });

  group('the quiz screen reads what was picked before', () {
    testWidgets('a wrong pick on an earlier day is said to be picked before', (t) async {
      final (db, repo, id) = await _env(t, notes: _notes);
      final q = (await t.runAsync(() => repo.getSet(id)))!.questions.single;
      await t.runAsync(() => ReviewRepository(db).record(
          kind: ItemKind.question, itemId: q.id, setId: id, correct: false, chosen: 0, mode: 'practice',
          now: DateTime(2026, 10, 10, 9)));
      await t.pumpWidget(MaterialApp(theme: kTheme(), home: QuizScreen(repo: repo, setId: id)));
      await settle(t);
      // the choices are shuffled by the generator, not here: choice 0 is "Fraud"
      await t.tap(find.text('Fraud'));
      await t.pump();
      await t.tap(find.text('Finish'));
      await t.pumpAndSettle();
      expect(find.textContaining('You picked it before, too.'), findsOneWidget);
    });

    testWidgets('and a first wrong pick is not', (t) async {
      final (_, repo, id) = await _env(t, notes: _notes);
      await t.pumpWidget(MaterialApp(theme: kTheme(), home: QuizScreen(repo: repo, setId: id)));
      await settle(t);
      await t.tap(find.text('Fraud'));
      await t.pump();
      await t.tap(find.text('Finish'));
      await t.pumpAndSettle();
      expect(find.textContaining('You picked "Fraud" (slide 14)'), findsOneWidget);
      expect(find.textContaining('before, too'), findsNothing);
    });
  });

  group('practice feedback', () {
    testWidgets('a wrong answer says where the pick came from, right away', (t) async {
      final (_, repo, id) = await _env(t, notes: _notes);
      await t.pumpWidget(MaterialApp(
          theme: kTheme(), home: PracticeScreen(repo: repo, reviews: ReviewRepository(repo.db), setId: id)));
      await settle(t);
      await t.tap(find.text('Fraud'));
      await settle(t);
      expect(find.textContaining('Not quite. The answer is Breach of contract.'), findsOneWidget);
      expect(find.text('WHERE YOUR PICK CAME FROM'), findsOneWidget);
      expect(find.textContaining('You picked "Fraud" (slide 14)'), findsOneWidget);
    });

    testWidgets('picking the same wrong choice again in a later session says so', (t) async {
      final (db, repo, id) = await _env(t, notes: _notes);
      final reviews = ReviewRepository(db);
      final q = (await t.runAsync(() => repo.getSet(id)))!.questions.single;
      await t.runAsync(() => reviews.record(
          kind: ItemKind.question, itemId: q.id, setId: id, correct: false, chosen: 0, mode: 'practice',
          now: DateTime.now().subtract(const Duration(days: 2))));
      await t.pumpWidget(MaterialApp(theme: kTheme(), home: PracticeScreen(repo: repo, reviews: reviews, setId: id)));
      await settle(t);
      await t.tap(find.text('Fraud'));
      await settle(t);
      expect(find.textContaining('You picked it before, too.'), findsOneWidget);
    });

    testWidgets('a right answer shows no diagnosis', (t) async {
      final (_, repo, id) = await _env(t, notes: _notes);
      await t.pumpWidget(MaterialApp(
          theme: kTheme(), home: PracticeScreen(repo: repo, reviews: ReviewRepository(repo.db), setId: id)));
      await settle(t);
      await t.tap(find.text('Breach of contract'));
      await settle(t);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('WHERE YOUR PICK CAME FROM'), findsNothing);
    });

    testWidgets('a set with no pages (a Word file) says nothing about a wrong pick, and does not fail', (t) async {
      final (_, repo, id) = await _env(t, notes: 'Plain notes with no pages at all.');
      await t.pumpWidget(MaterialApp(
          theme: kTheme(), home: PracticeScreen(repo: repo, reviews: ReviewRepository(repo.db), setId: id)));
      await settle(t);
      await t.tap(find.text('Fraud'));
      await settle(t);
      expect(find.textContaining('Not quite'), findsOneWidget);
      expect(find.text('WHERE YOUR PICK CAME FROM'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('a quick second tap on another choice does not change the answer', (t) async {
      final (db, repo, id) = await _env(t, notes: _notes);
      await t.pumpWidget(MaterialApp(
          theme: kTheme(), home: PracticeScreen(repo: repo, reviews: ReviewRepository(repo.db), setId: id)));
      await settle(t);
      await t.tap(find.text('Fraud'));
      await t.tap(find.text('Vandalism'), warnIfMissed: false);
      await settle(t);
      final log = (await t.runAsync(() => db.select(db.reviewLog).get()))!;
      expect(log, hasLength(1));
      expect(log.single.chosen, 0);
    });
  });

  group('pick history', () {
    testWidgets('timesPicked and wrongPickCounts count only wrong picks of questions', (t) async {
      final (db, repo, id) = await _env(t, notes: _notes);
      final reviews = ReviewRepository(db);
      final q = (await t.runAsync(() => repo.getSet(id)))!.questions.single;
      await t.runAsync(() async {
        for (final c in [0, 0, 2]) {
          await reviews.record(kind: ItemKind.question, itemId: q.id, setId: id, correct: false, chosen: c, mode: 'quiz', now: DateTime(2026, 10, 10));
        }
        await reviews.record(kind: ItemKind.question, itemId: q.id, setId: id, correct: true, chosen: 1, mode: 'quiz', now: DateTime(2026, 10, 10));
        await reviews.record(kind: ItemKind.card, itemId: q.id, setId: id, correct: false, mode: 'practice', now: DateTime(2026, 10, 10));
      });
      expect((await t.runAsync(() => reviews.timesPicked(q.id, 0))), 2);
      expect((await t.runAsync(() => reviews.timesPicked(q.id, 2))), 1);
      expect((await t.runAsync(() => reviews.timesPicked(q.id, 1))), 0); // that one was right
      expect((await t.runAsync(() => reviews.wrongPickCounts())), {q.id: {0: 2, 2: 1}});
      expect((await t.runAsync(() => reviews.wrongPickCounts(setId: id + 99))), isEmpty);
    });
  });
}
