import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/data/review_repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/study/session_plan.dart';

void main() {
  late AppDatabase db;
  late StudyRepository repo;
  late ReviewRepository reviews;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StudyRepository(db);
    reviews = ReviewRepository(db);
  });
  tearDown(() => db.close());

  const set = GeneratedSet([
    QuizQuestion(prompt: 'Q1', choices: ['a', 'b'], answerIndex: 0),
    QuizQuestion(prompt: 'Q2', choices: ['a', 'b', 'c'], answerIndex: 2),
  ], [
    Flashcard(front: 'f1', back: 'b1'),
    Flashcard(front: 'f2', back: 'b2'),
    Flashcard(front: 'f3', back: 'b3'),
  ]);

  final monday = DateTime(2026, 10, 12, 9);

  test('every card and question is a candidate, with no schedule until it is answered', () async {
    final a = await repo.saveSet('One', set);
    final b = await repo.saveSet('Two', const GeneratedSet([], [Flashcard(front: 'x', back: 'y')]));
    final all = await reviews.candidates();
    expect(all.where((c) => c.kind == ItemKind.card).length, 4);
    expect(all.where((c) => c.kind == ItemKind.question).length, 2);
    expect(all.every((c) => c.schedule == null), isTrue);
    expect({for (final c in all) c.setId}, {a, b});
  });

  test('an answer is logged and moves the schedule on', () async {
    final id = await repo.saveSet('One', set);
    final card = (await repo.getSet(id)).flashcards.first;
    await reviews.record(kind: ItemKind.card, itemId: card.id, setId: id, correct: true, mode: 'practice', now: monday);

    final log = await db.select(db.reviewLog).get();
    expect(log, hasLength(1));
    expect(log.single.kind, 'card');
    expect(log.single.itemId, card.id);
    expect(log.single.correct, isTrue);
    expect(log.single.mode, 'practice');
    expect(log.single.chosen, isNull);

    final c = (await reviews.candidates()).firstWhere((c) => c.kind == ItemKind.card && c.itemId == card.id);
    expect(c.schedule!.box, 1);
    expect(c.schedule!.dueDay, DateTime(2026, 10, 15));
    expect(c.schedule!.streak, 1);
  });

  test('a candidate knows the day it was last answered', () async {
    final id = await repo.saveSet('One', set);
    final card = (await repo.getSet(id)).flashcards.first;
    await reviews.record(kind: ItemKind.card, itemId: card.id, setId: id, correct: true, mode: 'practice', now: DateTime(2026, 10, 12, 21, 40));
    final all = await reviews.candidates();
    expect(all.firstWhere((c) => c.itemId == card.id && c.kind == ItemKind.card).schedule!.lastDay, DateTime(2026, 10, 12));
    expect(all.firstWhere((c) => c.itemId != card.id && c.kind == ItemKind.card).schedule, isNull);
  });

  test('what was answered today is not offered again today, but can be on a later day', () async {
    final id = await repo.saveSet('One', const GeneratedSet([], [Flashcard(front: 'f', back: 'b')]));
    final card = (await repo.getSet(id)).flashcards.single;
    await reviews.record(kind: ItemKind.card, itemId: card.id, setId: id, correct: true, mode: 'practice', now: DateTime(2026, 10, 12, 9));
    expect((await reviews.startSession(size: 5, now: DateTime(2026, 10, 12, 20))).items, isEmpty);
    expect((await reviews.counts(now: DateTime(2026, 10, 12, 20))).doneToday, 1);
    // two days later it is not due (a 3-day gap) but it was not answered that day, so it can be revisited
    final later = await reviews.startSession(size: 5, now: DateTime(2026, 10, 14, 9));
    expect(later.items.single.prompt, 'f');
    expect(later.plan.ahead, 1);
  });

  test('answering the same item again updates its one row; the log keeps every answer', () async {
    final id = await repo.saveSet('One', set);
    final q = (await repo.getSet(id)).questions.first;
    Future<void> answer(bool ok, DateTime at, {int? chosen}) => reviews.record(
        kind: ItemKind.question, itemId: q.id, setId: id, correct: ok, chosen: chosen, mode: 'practice', now: at);

    await answer(true, monday, chosen: 0);
    await answer(false, DateTime(2026, 10, 15), chosen: 1); // wrong on the day it was due
    expect(await db.select(db.reviewStates).get(), hasLength(1));
    expect(await db.select(db.reviewLog).get(), hasLength(2));

    final s = (await db.select(db.reviewStates).getSingle());
    expect(s.box, 0);
    expect(s.dueDay, DateTime(2026, 10, 16));
    expect(s.lapses, 1);
    expect(s.streak, 0);
    expect((await db.select(db.reviewLog).get()).map((e) => e.chosen), [0, 1]);
  });

  test('a card and a question with the same number are two different items', () async {
    final id = await repo.saveSet('One', set);
    await reviews.record(kind: ItemKind.card, itemId: 1, setId: id, correct: true, mode: 'practice', now: monday);
    await reviews.record(kind: ItemKind.question, itemId: 1, setId: id, correct: false, mode: 'practice', now: monday);
    expect(await db.select(db.reviewStates).get(), hasLength(2));
  });

  test('a finished quiz records every answer with its question, and the schedule follows', () async {
    final id = await repo.saveSet('One', set);
    final qs = (await repo.getSet(id)).questions;
    await reviews.recordQuiz(
      setId: id,
      answers: [
        (questionId: qs[0].id, chosen: 0, correct: true),
        (questionId: qs[1].id, chosen: 0, correct: false),
      ],
      now: monday,
    );
    final log = await db.select(db.reviewLog).get();
    expect(log.map((e) => e.mode), ['quiz', 'quiz']);
    expect(log.map((e) => e.itemId), [qs[0].id, qs[1].id]);
    expect(log.map((e) => e.correct), [true, false]);
    expect(log.map((e) => e.chosen), [0, 0]);
    final cs = {for (final c in await reviews.candidates()) if (c.kind == ItemKind.question) c.itemId: c.schedule!};
    expect(cs[qs[0].id]!.dueDay, DateTime(2026, 10, 15));
    expect(cs[qs[1].id]!.dueDay, DateTime(2026, 10, 13)); // the missed one is back tomorrow
  });

  test('deleting a study set deletes its practice history too', () async {
    final id = await repo.saveSet('One', set);
    final keep = await repo.saveSet('Keep', set);
    final card = (await repo.getSet(id)).flashcards.first;
    final other = (await repo.getSet(keep)).flashcards.first;
    await reviews.record(kind: ItemKind.card, itemId: card.id, setId: id, correct: true, mode: 'practice', now: monday);
    await reviews.record(kind: ItemKind.card, itemId: other.id, setId: keep, correct: true, mode: 'practice', now: monday);
    await repo.deleteSet(id);
    expect(await db.select(db.reviewStates).get(), hasLength(1));
    expect((await db.select(db.reviewLog).get()).single.studySetId, keep);
  });

  group('streak', () {
    test('a day with practice and no quiz still counts', () async {
      final id = await repo.saveSet('One', set);
      final card = (await repo.getSet(id)).flashcards.first;
      for (final day in [10, 11, 12]) {
        await reviews.record(
            kind: ItemKind.card, itemId: card.id, setId: id, correct: true, mode: 'practice', now: DateTime(2026, 10, day, 8));
      }
      final lib = await repo.libraryData(now: DateTime(2026, 10, 12, 20));
      expect(lib.stats.streakDays, 3);
    });

    test('practice and quizzes on different days join up into one streak', () async {
      final id = await repo.saveSet('One', set);
      final card = (await repo.getSet(id)).flashcards.first;
      await repo.saveAttempt(setId: id, score: 1, total: 2, durationSeconds: 5, results: const [], takenAt: DateTime(2026, 10, 11, 10));
      await reviews.record(kind: ItemKind.card, itemId: card.id, setId: id, correct: true, mode: 'practice', now: DateTime(2026, 10, 12, 8));
      expect((await repo.libraryData(now: DateTime(2026, 10, 12, 20))).stats.streakDays, 2);
    });

    test('no practice and no quizzes is no streak', () async {
      await repo.saveSet('One', set);
      expect((await repo.libraryData(now: monday)).stats.streakDays, 0);
    });
  });

  test('answerTimes lists when each answer was given', () async {
    final id = await repo.saveSet('One', set);
    await reviews.record(kind: ItemKind.card, itemId: 1, setId: id, correct: true, mode: 'practice', now: monday);
    final times = await reviews.answerTimes();
    expect(times, hasLength(1));
    expect(times.single.isAtSameMomentAs(monday), isTrue);
  });

  test('quizAnswersFrom ties each result to its question, and leaves out one that was not answered', () {
    final answers = quizAnswersFrom([
      {'q': 0, 'chosen': 1, 'correct': false},
      {'q': 1, 'chosen': -1, 'correct': false},
      {'q': 2, 'chosen': 0, 'correct': true},
    ], [101, 102, 103]);
    expect(answers, [
      (questionId: 101, chosen: 1, correct: false),
      (questionId: 103, chosen: 0, correct: true),
    ]);
    expect(quizAnswersFrom(const [], const []), isEmpty);
  });

  test('a version-5 database gets the practice tables and keeps everything it had', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE study_sets (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, '
          "source_type TEXT NOT NULL DEFAULT 'text', source_text TEXT NOT NULL DEFAULT '', "
          "source_paths TEXT NOT NULL DEFAULT '[]', summary TEXT NOT NULL DEFAULT '', "
          "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))");
      raw.execute("INSERT INTO study_sets (title) VALUES ('Old set')");
      raw.execute('CREATE TABLE flashcard_rows (id INTEGER PRIMARY KEY AUTOINCREMENT, study_set_id INTEGER NOT NULL, '
          "front TEXT NOT NULL, back TEXT NOT NULL, source TEXT NOT NULL DEFAULT '')");
      raw.execute("INSERT INTO flashcard_rows (study_set_id, front, back) VALUES (1, 'f', 'b')");
      raw.execute('CREATE TABLE question_rows (id INTEGER PRIMARY KEY AUTOINCREMENT, study_set_id INTEGER NOT NULL, '
          "type TEXT NOT NULL DEFAULT 'multiple_choice', prompt TEXT NOT NULL, choices TEXT NOT NULL, "
          "answer_index INTEGER NOT NULL, explanation TEXT NOT NULL DEFAULT '', source TEXT NOT NULL DEFAULT '')");
      raw.execute('CREATE TABLE readers (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE stories (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE reading_attempts (id INTEGER PRIMARY KEY AUTOINCREMENT, wpm INTEGER)');
      raw.execute('CREATE TABLE saved_words (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('PRAGMA user_version = 5');
    }));
    addTearDown(old.close);
    final d = await StudyRepository(old).getSet(1);
    expect(d.flashcards.single.front, 'f');
    final tables = {
      for (final r in await old.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get()) r.read<String>('name'),
    };
    expect(tables, containsAll(['review_states', 'review_log']));
    // and practice can be recorded in the upgraded database
    await ReviewRepository(old).record(kind: ItemKind.card, itemId: 1, setId: 1, correct: true, mode: 'practice', now: DateTime(2026, 10, 12));
    expect(await old.select(old.reviewStates).get(), hasLength(1));
  });

  group('starting a session', () {
    test('the items come with their content, and what was answered wrong comes first next day', () async {
      final id = await repo.saveSet('Module 3', set);
      final d = await repo.getSet(id);
      // yesterday: one card right, one card wrong
      await reviews.record(kind: ItemKind.card, itemId: d.flashcards[0].id, setId: id, correct: true, mode: 'practice', now: DateTime(2026, 10, 11, 9));
      await reviews.record(kind: ItemKind.card, itemId: d.flashcards[1].id, setId: id, correct: false, mode: 'practice', now: DateTime(2026, 10, 11, 9));

      final start = await reviews.startSession(size: 3, now: DateTime(2026, 10, 12, 9));
      expect(start.plan.due, 1); // only the missed card is due; the right one is 3 days out
      expect(start.items.first.prompt, 'f2');
      expect(start.items.first.answer, 'b2');
      expect(start.items.first.setTitle, 'Module 3');
      expect(start.items.length, 3); // then new items fill the room
      expect(start.plan.fresh, 2);
      final q = start.items.firstWhere((i) => i.isQuestion);
      expect(q.choices, isNotEmpty);
      expect(q.answer, q.choices[q.answerIndex]);
    });

    test('a session can be limited to one set, and says how many items each kind has', () async {
      const other = GeneratedSet([
        QuizQuestion(prompt: 'P1', choices: ['a', 'b'], answerIndex: 0),
        QuizQuestion(prompt: 'P2', choices: ['a', 'b', 'c'], answerIndex: 2),
      ], [
        Flashcard(front: 'g1', back: 'c1'),
        Flashcard(front: 'g2', back: 'c2'),
        Flashcard(front: 'g3', back: 'c3'),
      ]);
      final a = await repo.saveSet('One', set);
      await repo.saveSet('Two', other);
      final start = await reviews.startSession(size: 10, setId: a, now: DateTime(2026, 10, 12));
      expect({for (final i in start.items) i.setId}, {a});
      expect(start.items.length, 5);
      final counts = await reviews.counts(setId: a, now: DateTime(2026, 10, 12));
      expect(counts.fresh, 5);
      expect(counts.due, 0);
      expect((await reviews.counts(now: DateTime(2026, 10, 12))).fresh, 10);
    });

    test('a card and a question with the same wording are asked once in a session', () async {
      const both = GeneratedSet([
        QuizQuestion(prompt: 'What does the ACM Code express?', choices: ['The conscience of the profession', 'Law'], answerIndex: 0),
        QuizQuestion(prompt: 'Which term is this?', choices: ['Fraud', 'Bribery'], answerIndex: 1),
      ], [
        Flashcard(front: 'What does the ACM code express?', back: 'The conscience of the profession'),
        Flashcard(front: 'Whistle-blowing', back: 'Drawing attention to wrongdoing'),
      ]);
      final id = await repo.saveSet('Module 2', both);
      final items = (await reviews.startSession(size: 10, setId: id)).items;
      expect(items.where((i) => i.prompt.toLowerCase().contains('acm code express')).length, 1);
      expect(items.length, 3);
      expect((await reviews.counts(setId: id)).fresh, 3);
    });

    test('an empty library gives an empty session', () async {
      final start = await reviews.startSession(size: 5, now: DateTime(2026, 10, 12));
      expect(start.items, isEmpty);
      expect((await reviews.counts()).total, 0);
    });

    test('the source of a card is carried through, and a missing one is fine', () async {
      const withSource = GeneratedSet([], [
        Flashcard(front: 'f', back: 'b', source: SourceRef(kind: SourceKind.copied, pages: [4], score: 1)),
        Flashcard(front: 'g', back: 'c'),
      ]);
      final id = await repo.saveSet('Src', withSource);
      final items = (await reviews.startSession(size: 5, setId: id)).items;
      expect(items.firstWhere((i) => i.prompt == 'f').source!.page, 4);
      expect(items.firstWhere((i) => i.prompt == 'g').source, isNull);
    });

    test('a question with unreadable choices, or an answer that is out of range, is left out', () async {
      final id = await repo.saveSet('Bad', set);
      await db.customStatement("UPDATE question_rows SET choices = 'not json' WHERE study_set_id = $id AND prompt = 'Q1'");
      await db.customStatement("UPDATE question_rows SET answer_index = 9 WHERE study_set_id = $id AND prompt = 'Q2'");
      final items = (await reviews.startSession(size: 10, setId: id)).items;
      expect(items.where((i) => i.isQuestion), isEmpty);
      expect(items.where((i) => !i.isQuestion).length, 3); // the cards are fine
    });

    test('an item whose card was deleted after it was picked is left out, not a crash', () async {
      final id = await repo.saveSet('One', set);
      final picked = (await reviews.candidates()).where((c) => c.setId == id).toList();
      await repo.deleteSet(id);
      expect(await reviews.itemsFor(picked), isEmpty);
    });

    test('setsById gives the sets that exist, and leaves out a deleted one', () async {
      final a = await repo.saveSet('One', set);
      final b = await repo.saveSet('Two', set);
      await repo.deleteSet(b);
      final found = await reviews.setsById([a, b, 999]);
      expect(found.keys, [a]);
      expect(found[a]!.title, 'One');
      expect(await reviews.setsById(const []), isEmpty);
    });

    test('recordPractice logs the answer as practice and moves the schedule', () async {
      final id = await repo.saveSet('One', set);
      final item = (await reviews.startSession(size: 1, setId: id)).items.single;
      await reviews.recordPractice(item, false, null, now: DateTime(2026, 10, 12, 9));
      final log = await db.select(db.reviewLog).getSingle();
      expect(log.mode, 'practice');
      expect(log.correct, isFalse);
      final state = await db.select(db.reviewStates).getSingle();
      expect(state.dueDay, DateTime(2026, 10, 13));
    });
  });
}
