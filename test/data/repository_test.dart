import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/models.dart';
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
    expect(lib.stats.streakDays, 2);
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
}
