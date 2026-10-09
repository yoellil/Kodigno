import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/domain/summary.dart';

void main() {
  late AppDatabase db;
  late StudyRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StudyRepository(db);
  });
  tearDown(() => db.close());

  const set = GeneratedSet(
    [QuizQuestion(prompt: 'Q', choices: ['a', 'b'], answerIndex: 1, explanation: 'e')],
    [Flashcard(front: 'f', back: 'b')],
  );

  test('save then load a set with source info', () async {
    final id = await repo.saveSet('Bio', set,
        sourceType: 'pdf', sourceText: 'cells', sourcePaths: ['C:/n.pdf']);
    final d = await repo.getSet(id);
    expect(d.set.title, 'Bio');
    expect(d.set.sourceType, 'pdf');
    expect(d.set.sourceText, 'cells');
    expect(d.questions.single.answerIndex, 1);
    expect(d.questions.single.choices, '["a","b"]');
    expect(d.flashcards.single.back, 'b');
  });

  const lesson = LessonSummary(
    overview: 'About cells.',
    sections: [
      SummarySection(
          heading: 'The cell',
          explanation: 'Cells are the units of life.',
          keyPoints: ['Cells divide'],
          facts: ['Built in 1859.']),
    ],
    takeaways: ['Cells make up every organism.'],
    keyTerms: ['cell'],
  );

  test('a lesson saved with the set, or saved later, is read back; saving again replaces it', () async {
    final a = await repo.saveSet('Bio', set);
    expect((await repo.getSet(a)).summary, isNull);
    await repo.saveSummary(a, lesson);
    expect((await repo.getSet(a)).summary!.encode(), lesson.encode());

    final b = await repo.saveSet('Bio 2', set, summary: lesson);
    expect((await repo.getSet(b)).summary!.sections.single.facts, ['Built in 1859.']);
    await repo.saveSummary(
        b, const LessonSummary(sections: [SummarySection(heading: 'New', explanation: 'Replaced.')]));
    expect((await repo.getSet(b)).summary!.sections.single.heading, 'New');
    expect((await repo.getSet(a)).summary!.sections.single.heading, 'The cell'); // others untouched
  });

  test('a database from before lessons existed upgrades and keeps its sets', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE study_sets (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          "title TEXT NOT NULL, source_type TEXT NOT NULL DEFAULT 'text', "
          "source_text TEXT NOT NULL DEFAULT '', source_paths TEXT NOT NULL DEFAULT '[]', "
          "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))");
      raw.execute("INSERT INTO study_sets (title, source_text) VALUES ('Old set', 'old notes')");
      raw.execute('PRAGMA user_version = 1');
    }));
    addTearDown(old.close);
    final sets = await old.select(old.studySets).get();
    expect(sets.single.title, 'Old set');
    expect(sets.single.sourceText, 'old notes');
    expect(sets.single.summary, '');
    final oldRepo = StudyRepository(old);
    await oldRepo.saveSummary(sets.single.id, lesson);
    expect((await old.select(old.studySets).getSingle()).summary, isNotEmpty);
  });

  // The reading tables and the lesson column were both added at version 2, by
  // different people, so a version-2 database has one of them but not the other.
  String studySetsSql({required bool withSummary}) =>
      'CREATE TABLE study_sets (id INTEGER PRIMARY KEY AUTOINCREMENT, '
      "title TEXT NOT NULL, source_type TEXT NOT NULL DEFAULT 'text', "
      "source_text TEXT NOT NULL DEFAULT '', source_paths TEXT NOT NULL DEFAULT '[]', "
      "${withSummary ? "summary TEXT NOT NULL DEFAULT '', " : ''}"
      "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))";

  Future<Set<String>> tablesOf(AppDatabase d) async => {
        for (final r in await d.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get())
          r.read<String>('name'),
      };

  test('a teammate\'s version-2 database (reading tables, no lesson column) gets the column', () async {
    final theirs = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(studySetsSql(withSummary: false));
      raw.execute("INSERT INTO study_sets (title) VALUES ('Their set')");
      for (final t in ['readers', 'stories', 'reading_attempts']) {
        raw.execute('CREATE TABLE $t (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      }
      raw.execute('PRAGMA user_version = 2');
    }));
    addTearDown(theirs.close);
    final sets = await theirs.select(theirs.studySets).get();
    expect(sets.single.title, 'Their set');
    expect(sets.single.summary, '');
    expect(await tablesOf(theirs), containsAll(['readers', 'stories', 'reading_attempts']));
  });

  test('a version-2 database with the lesson column but no reading tables gets the tables', () async {
    final mine = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(studySetsSql(withSummary: true));
      raw.execute("INSERT INTO study_sets (title, summary) VALUES ('My set', '{\"sections\":[]}')");
      raw.execute('PRAGMA user_version = 2');
    }));
    addTearDown(mine.close);
    final sets = await mine.select(mine.studySets).get();
    expect(sets.single.title, 'My set');
    expect(sets.single.summary, '{"sections":[]}'); // kept as it was
    expect(await tablesOf(mine), containsAll(['readers', 'stories', 'reading_attempts']));
  });

  Future<Set<String>> columnsOf(AppDatabase d, String table) async => {
        for (final r in await d.customSelect('PRAGMA table_info($table)').get()) r.read<String>('name'),
      };

  test('a teammate\'s current version-3 database (words a minute, saved words, no lesson column) gets the column', () async {
    final theirs = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(studySetsSql(withSummary: false));
      raw.execute("INSERT INTO study_sets (title) VALUES ('Their set')");
      raw.execute('CREATE TABLE readers (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE stories (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE reading_attempts (id INTEGER PRIMARY KEY AUTOINCREMENT, wpm INTEGER)');
      raw.execute('CREATE TABLE saved_words (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('PRAGMA user_version = 3');
    }));
    addTearDown(theirs.close);
    final sets = await theirs.select(theirs.studySets).get();
    expect(sets.single.title, 'Their set');
    expect(sets.single.summary, '');
    expect(await columnsOf(theirs, 'reading_attempts'), contains('wpm'));
  });

  test('a version-3 database from before words a minute and saved words existed gets both', () async {
    final mine = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(studySetsSql(withSummary: true));
      raw.execute("INSERT INTO study_sets (title, summary) VALUES ('My set', '{\"sections\":[]}')");
      raw.execute('CREATE TABLE readers (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE stories (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE reading_attempts (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('PRAGMA user_version = 3');
    }));
    addTearDown(mine.close);
    final sets = await mine.select(mine.studySets).get();
    expect(sets.single.summary, '{"sections":[]}'); // kept as it was
    expect(await columnsOf(mine, 'reading_attempts'), contains('wpm'));
    expect(await tablesOf(mine), contains('saved_words'));
  });

  test('the page behind each card and question is saved and read back', () async {
    const withSources = GeneratedSet([
      QuizQuestion(
        prompt: 'Q',
        choices: ['a', 'b'],
        answerIndex: 1,
        source: SourceRef(kind: SourceKind.copied, pages: [3], score: 1, quote: 'A line.'),
      ),
      QuizQuestion(prompt: 'No source', choices: ['a', 'b'], answerIndex: 0),
    ], [
      Flashcard(front: 'f', back: 'b', source: SourceRef(kind: SourceKind.unmatched, pages: [7], score: 0.1)),
      Flashcard(front: 'g', back: 'c'),
    ]);
    final id = await repo.saveSet('Bio', withSources);
    final d = await repo.getSet(id);
    final q = d.questions.firstWhere((x) => x.prompt == 'Q');
    expect(SourceRef.decode(q.source)!.kind, SourceKind.copied);
    expect(SourceRef.decode(q.source)!.page, 3);
    expect(SourceRef.decode(q.source)!.quote, 'A line.');
    expect(SourceRef.decode(d.questions.firstWhere((x) => x.prompt == 'No source').source), isNull);
    final c = d.flashcards.firstWhere((x) => x.front == 'f');
    expect(SourceRef.decode(c.source)!.kind, SourceKind.unmatched); // flagged, and kept
    expect(SourceRef.decode(c.source)!.page, 7);
    expect(d.flashcards.firstWhere((x) => x.front == 'g').source, '');
  });

  test('a version-4 database gets the source columns on cards and questions, and keeps its rows', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(studySetsSql(withSummary: true));
      raw.execute("INSERT INTO study_sets (title) VALUES ('Old set')");
      raw.execute('CREATE TABLE question_rows (id INTEGER PRIMARY KEY AUTOINCREMENT, study_set_id INTEGER NOT NULL, '
          "type TEXT NOT NULL DEFAULT 'multiple_choice', prompt TEXT NOT NULL, choices TEXT NOT NULL, "
          "answer_index INTEGER NOT NULL, explanation TEXT NOT NULL DEFAULT '')");
      raw.execute('CREATE TABLE flashcard_rows (id INTEGER PRIMARY KEY AUTOINCREMENT, study_set_id INTEGER NOT NULL, '
          'front TEXT NOT NULL, back TEXT NOT NULL)');
      raw.execute("INSERT INTO question_rows (study_set_id, prompt, choices, answer_index) VALUES (1, 'Q', '[\"a\",\"b\"]', 0)");
      raw.execute("INSERT INTO flashcard_rows (study_set_id, front, back) VALUES (1, 'f', 'b')");
      raw.execute('CREATE TABLE readers (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE stories (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE reading_attempts (id INTEGER PRIMARY KEY AUTOINCREMENT, wpm INTEGER)');
      raw.execute('CREATE TABLE saved_words (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('PRAGMA user_version = 4');
    }));
    addTearDown(old.close);
    final d = await StudyRepository(old).getSet(1);
    expect(d.questions.single.prompt, 'Q');
    expect(d.questions.single.source, ''); // not looked up for old rows
    expect(d.flashcards.single.front, 'f');
    expect(d.flashcards.single.source, '');
    expect(await columnsOf(old, 'question_rows'), contains('source'));
    expect(await columnsOf(old, 'flashcard_rows'), contains('source'));
  });

  test('library lists newest first with stats and last score percent', () async {
    final now = DateTime(2026, 10, 9, 12);
    final a = await repo.saveSet('One', set);
    final b = await repo.saveSet('Two', set);
    await repo.saveAttempt(setId: a, score: 3, total: 5, durationSeconds: 9,
        results: const [], takenAt: DateTime(2026, 9, 20)); // outside the week
    await repo.saveAttempt(setId: a, score: 4, total: 5, durationSeconds: 9,
        results: const [], takenAt: DateTime(2026, 10, 9, 9));
    await repo.saveAttempt(setId: b, score: 1, total: 4, durationSeconds: 9,
        results: const [], takenAt: DateTime(2026, 10, 8, 9));
    final lib = await repo.libraryData(now: now);
    expect(lib.sets.map((s) => s.title), ['Two', 'One']);
    expect(lib.lastPercent[a], 80);
    expect(lib.lastPercent[b], 25);
    expect(lib.stats.sets, 2);
    expect(lib.stats.answeredThisWeek, 9); // 5 + 4
  });

  test('watchLibrary emits current data', () async {
    await repo.saveSet('One', set);
    final lib = await repo.watchLibrary().first;
    expect(lib.sets, hasLength(1));
  });

  test('deleting a set cascades to questions, cards and attempts', () async {
    final id = await repo.saveSet('Bio', set);
    await repo.saveAttempt(setId: id, score: 1, total: 1, durationSeconds: 5,
        results: [{'q': 0, 'chosen': 1, 'correct': true}]);
    expect((await repo.attemptsFor(id)).single.score, 1);
    await repo.deleteSet(id);
    expect(await repo.attemptsFor(id), isEmpty);
    expect(await db.select(db.questionRows).get(), isEmpty);
    expect(await db.select(db.flashcardRows).get(), isEmpty);
  });

  group('flashcards the student writes or corrects', () {
    test('addFlashcard saves a trimmed card to the set and returns its id', () async {
      final setId = await repo.saveSet('Bio', set);
      final id = await repo.addFlashcard(setId, '  Mitochondria ', ' Makes ATP.  ');
      final cards = (await repo.getSet(setId)).flashcards;
      expect(cards, hasLength(2));
      final added = cards.firstWhere((c) => c.id == id);
      expect((added.front, added.back), ('Mitochondria', 'Makes ATP.'));
    });

    test('updateFlashcard rewrites one card and leaves the others alone', () async {
      final setId = await repo.saveSet('Bio', set);
      final other = await repo.addFlashcard(setId, 'Nucleus', 'Holds the DNA.');
      final first = (await repo.getSet(setId)).flashcards.first;
      expect(await repo.updateFlashcard(first.id, 'Corrected term', ' Corrected answer '), isTrue);
      final cards = {for (final c in (await repo.getSet(setId)).flashcards) c.id: c};
      expect((cards[first.id]!.front, cards[first.id]!.back), ('Corrected term', 'Corrected answer'));
      expect(cards[other]!.front, 'Nucleus');
    });

    test('a blank side is refused, and a card that is gone returns false', () async {
      final setId = await repo.saveSet('Bio', set);
      expect(() => repo.addFlashcard(setId, 'Term', '   '), throwsArgumentError);
      final id = (await repo.getSet(setId)).flashcards.first.id;
      expect(() => repo.updateFlashcard(id, '', 'x'), throwsArgumentError);
      expect(await repo.updateFlashcard(9999, 'a', 'b'), isFalse);
      expect((await repo.getSet(setId)).flashcards.first.front, 'f'); // unchanged
    });

    test('deleting the set removes its added cards too', () async {
      final setId = await repo.saveSet('Bio', set);
      await repo.addFlashcard(setId, 'Nucleus', 'Holds the DNA.');
      await repo.deleteSet(setId);
      expect(await db.select(db.flashcardRows).get(), isEmpty);
    });
  });
}
