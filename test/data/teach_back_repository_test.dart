import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/data/teach_back_repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/study/teach_back.dart';

TeachBackResult _result({int covered = 2, int partly = 1, int total = 4, bool copied = false, int flags = 0}) {
  IdeaResult idea(Coverage c) => IdeaResult(const Idea('An idea of the topic'), coverage: c, score: 0);
  return TeachBackResult(
    ideas: [
      for (var i = 0; i < covered; i++) idea(Coverage.covered),
      for (var i = 0; i < partly; i++) idea(Coverage.partly),
      for (var i = 0; i < total - covered - partly; i++) idea(Coverage.missing),
    ],
    missingTerms: const [],
    flags: [for (var i = 0; i < flags; i++) Flag(FlagKind.number, 'A sentence.', '$i')],
    copied: copied,
    words: 30,
  );
}

void main() {
  late AppDatabase db;
  late StudyRepository repo;
  late TeachBackRepository tb;
  late int setId;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = StudyRepository(db);
    tb = TeachBackRepository(db);
    setId = await repo.saveSet('Module 3', const GeneratedSet([], []));
  });
  tearDown(() => db.close());

  test('a try is saved with the answer and what the check found', () async {
    final id = await tb.save(
        setId: setId, section: 'Patents', sectionIndex: 7, answer: 'A patent protects an invention.', result: _result(flags: 2, copied: true));
    final a = (await tb.attemptsFor(setId, 'Patents')).single;
    expect(a.id, id);
    expect(a.answer, 'A patent protects an invention.');
    expect((a.covered, a.partly, a.total), (2, 1, 4));
    expect(a.copied, isTrue);
    expect(a.flagCount, 2);
    expect(a.sectionIndex, 7);
    expect(a.overruledIdeas, isEmpty);
    expect(a.coveredCounted, 2);
  });

  test('tries come back newest first, and only for their own topic and set', () async {
    final other = await repo.saveSet('Other', const GeneratedSet([], []));
    await tb.save(setId: setId, section: 'Patents', sectionIndex: 0, answer: 'first', result: _result(covered: 1), now: DateTime(2026, 10, 10));
    await tb.save(setId: setId, section: 'Patents', sectionIndex: 0, answer: 'second', result: _result(covered: 3), now: DateTime(2026, 10, 11));
    await tb.save(setId: setId, section: 'Privacy', sectionIndex: 1, answer: 'elsewhere', result: _result());
    await tb.save(setId: other, section: 'Patents', sectionIndex: 0, answer: 'another set', result: _result());
    expect((await tb.attemptsFor(setId, 'Patents')).map((a) => a.answer), ['second', 'first']);
    expect(await tb.attemptsFor(setId, 'Nothing here'), isEmpty);
  });

  test('the latest try at each topic', () async {
    await tb.save(setId: setId, section: 'Patents', sectionIndex: 0, answer: 'old', result: _result(covered: 1));
    await tb.save(setId: setId, section: 'Patents', sectionIndex: 0, answer: 'new', result: _result(covered: 3));
    await tb.save(setId: setId, section: 'Privacy', sectionIndex: 1, answer: 'only', result: _result(covered: 0, partly: 0));
    final latest = await tb.latestBySection(setId);
    expect(latest.keys, unorderedEquals(['Patents', 'Privacy']));
    expect(latest['Patents']!.answer, 'new');
    expect(latest['Privacy']!.covered, 0);
    expect(await tb.latestBySection(setId + 9), isEmpty);
  });

  group('"I covered this"', () {
    test('counts the idea as covered, once, however often it is said', () async {
      final id = await tb.save(setId: setId, section: 'Patents', sectionIndex: 0, answer: 'x', result: _result(covered: 1, partly: 1, total: 4));
      await tb.overrule(id, 2);
      await tb.overrule(id, 2);
      var a = (await tb.attemptsFor(setId, 'Patents')).single;
      expect(a.overruledIdeas, [2]);
      expect(a.coveredCounted, 2);
      await tb.overrule(id, 3);
      a = (await tb.attemptsFor(setId, 'Patents')).single;
      expect(a.overruledIdeas, [2, 3]);
      expect(a.coveredCounted, 3);
    });

    test('never counts more than the ideas there are', () async {
      final id = await tb.save(setId: setId, section: 'Patents', sectionIndex: 0, answer: 'x', result: _result(covered: 3, partly: 0, total: 4));
      for (final i in [0, 1, 2, 3]) {
        await tb.overrule(id, i);
      }
      expect((await tb.attemptsFor(setId, 'Patents')).single.coveredCounted, 4);
    });

    test('a position that is not an idea, or a try that is not there, is ignored', () async {
      final id = await tb.save(setId: setId, section: 'Patents', sectionIndex: 0, answer: 'x', result: _result(total: 4));
      await tb.overrule(id, 4);
      await tb.overrule(id, -1);
      await tb.overrule(id + 99, 0);
      expect((await tb.attemptsFor(setId, 'Patents')).single.overruledIdeas, isEmpty);
    });

    test('a damaged list reads as none', () async {
      final id = await tb.save(setId: setId, section: 'Patents', sectionIndex: 0, answer: 'x', result: _result());
      await db.customStatement("UPDATE teach_back_attempts SET overruled = 'not json' WHERE id = $id");
      final a = (await tb.attemptsFor(setId, 'Patents')).single;
      expect(a.overruledIdeas, isEmpty);
      expect(a.coveredCounted, a.covered);
    });
  });

  test('deleting a study set deletes its tries too', () async {
    final keep = await repo.saveSet('Keep', const GeneratedSet([], []));
    await tb.save(setId: setId, section: 'Patents', sectionIndex: 0, answer: 'gone', result: _result());
    await tb.save(setId: keep, section: 'Patents', sectionIndex: 0, answer: 'kept', result: _result());
    await repo.deleteSet(setId);
    final left = await db.select(db.teachBackAttempts).get();
    expect(left.map((a) => a.answer), ['kept']);
  });

  group('key ideas kept for a topic', () {
    const two = ['A patent lets the owner stop others.', 'A utility patent covers a new process.'];

    test('are saved once and read back the same, per topic and per set', () async {
      expect(await tb.conceptsFor(setId, 'Patents'), isNull);
      await tb.saveConcepts(setId, 'Patents', two);
      expect(await tb.conceptsFor(setId, 'Patents'), two);
      expect(await tb.conceptsFor(setId, 'Privacy'), isNull);
      final other = await repo.saveSet('Other', const GeneratedSet([], []));
      expect(await tb.conceptsFor(other, 'Patents'), isNull);
    });

    test('saving again replaces them, with one row for the topic', () async {
      await tb.saveConcepts(setId, 'Patents', two);
      await tb.saveConcepts(setId, 'Patents', [...two, 'A design patent covers how a thing looks.']);
      expect(await tb.conceptsFor(setId, 'Patents'), hasLength(3));
      expect(await db.select(db.topicConcepts).get(), hasLength(1));
    });

    test('a damaged or too short list reads as none, so they are written again', () async {
      await tb.saveConcepts(setId, 'Short', ['Only one idea here.']);
      expect(await tb.conceptsFor(setId, 'Short'), isNull);
      await tb.saveConcepts(setId, 'Patents', two);
      await db.customStatement("UPDATE topic_concepts SET concepts = 'not json'");
      expect(await tb.conceptsFor(setId, 'Patents'), isNull);
    });

    test('are deleted with their study set', () async {
      await tb.saveConcepts(setId, 'Patents', two);
      await repo.deleteSet(setId);
      expect(await db.select(db.topicConcepts).get(), isEmpty);
    });
  });

  test('a try records whether the AI model or only the words checked it', () async {
    await tb.save(setId: setId, section: 'A', sectionIndex: 0, answer: 'x', result: _result());
    final judged = TeachBackResult(
        ideas: _result().ideas, missingTerms: const [], flags: const [], copied: false, words: 30, checkedBy: CheckedBy.model);
    await tb.save(setId: setId, section: 'B', sectionIndex: 1, answer: 'y', result: judged);
    expect((await tb.attemptsFor(setId, 'A')).single.checkedBy, 'words');
    expect((await tb.attemptsFor(setId, 'B')).single.checkedBy, 'model');
  });

  test('a version-7 database gets the column and the table, and keeps its tries', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE study_sets (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, '
          "source_type TEXT NOT NULL DEFAULT 'text', source_text TEXT NOT NULL DEFAULT '', "
          "source_paths TEXT NOT NULL DEFAULT '[]', summary TEXT NOT NULL DEFAULT '', "
          "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))");
      raw.execute("INSERT INTO study_sets (title) VALUES ('Old set')");
      raw.execute('CREATE TABLE flashcard_rows (id INTEGER PRIMARY KEY AUTOINCREMENT, study_set_id INTEGER NOT NULL, '
          "front TEXT NOT NULL, back TEXT NOT NULL, source TEXT NOT NULL DEFAULT '')");
      raw.execute('CREATE TABLE question_rows (id INTEGER PRIMARY KEY AUTOINCREMENT, study_set_id INTEGER NOT NULL, '
          "type TEXT NOT NULL DEFAULT 'multiple_choice', prompt TEXT NOT NULL, choices TEXT NOT NULL, "
          "answer_index INTEGER NOT NULL, explanation TEXT NOT NULL DEFAULT '', source TEXT NOT NULL DEFAULT '')");
      raw.execute('CREATE TABLE readers (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE stories (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE reading_attempts (id INTEGER PRIMARY KEY AUTOINCREMENT, wpm INTEGER)');
      raw.execute('CREATE TABLE saved_words (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE review_states (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE review_log (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      // the table as version 7 made it: no checked_by column
      raw.execute('CREATE TABLE teach_back_attempts (id INTEGER PRIMARY KEY AUTOINCREMENT, study_set_id INTEGER NOT NULL, '
          "section TEXT NOT NULL, section_index INTEGER NOT NULL DEFAULT 0, answer TEXT NOT NULL, covered INTEGER NOT NULL DEFAULT 0, "
          'partly INTEGER NOT NULL DEFAULT 0, total INTEGER NOT NULL DEFAULT 0, copied INTEGER NOT NULL DEFAULT 0, '
          "flag_count INTEGER NOT NULL DEFAULT 0, overruled TEXT NOT NULL DEFAULT '[]', "
          "taken_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))");
      raw.execute("INSERT INTO teach_back_attempts (study_set_id, section, answer, covered, total) VALUES (1, 'Patents', 'my old try', 2, 4)");
      raw.execute('PRAGMA user_version = 7');
    }));
    addTearDown(old.close);
    final a = (await TeachBackRepository(old).attemptsFor(1, 'Patents')).single;
    expect(a.answer, 'my old try');
    expect((a.covered, a.total), (2, 4));
    expect(a.checkedBy, 'words'); // tries from before the model took part were checked by words
    await TeachBackRepository(old).saveConcepts(1, 'Patents', const ['One idea in a sentence.', 'Another idea in a sentence.']);
    expect(await TeachBackRepository(old).conceptsFor(1, 'Patents'), hasLength(2));
  });

  test('a version-6 database gets the table and keeps everything it had', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE study_sets (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, '
          "source_type TEXT NOT NULL DEFAULT 'text', source_text TEXT NOT NULL DEFAULT '', "
          "source_paths TEXT NOT NULL DEFAULT '[]', summary TEXT NOT NULL DEFAULT '', "
          "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))");
      raw.execute("INSERT INTO study_sets (title) VALUES ('Old set')");
      raw.execute('CREATE TABLE flashcard_rows (id INTEGER PRIMARY KEY AUTOINCREMENT, study_set_id INTEGER NOT NULL, '
          "front TEXT NOT NULL, back TEXT NOT NULL, source TEXT NOT NULL DEFAULT '')");
      raw.execute('CREATE TABLE question_rows (id INTEGER PRIMARY KEY AUTOINCREMENT, study_set_id INTEGER NOT NULL, '
          "type TEXT NOT NULL DEFAULT 'multiple_choice', prompt TEXT NOT NULL, choices TEXT NOT NULL, "
          "answer_index INTEGER NOT NULL, explanation TEXT NOT NULL DEFAULT '', source TEXT NOT NULL DEFAULT '')");
      raw.execute('CREATE TABLE readers (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE stories (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE reading_attempts (id INTEGER PRIMARY KEY AUTOINCREMENT, wpm INTEGER)');
      raw.execute('CREATE TABLE saved_words (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE review_states (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('CREATE TABLE review_log (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      raw.execute('PRAGMA user_version = 6');
    }));
    addTearDown(old.close);
    expect((await old.select(old.studySets).getSingle()).title, 'Old set');
    final id = await TeachBackRepository(old).save(setId: 1, section: 'Patents', sectionIndex: 0, answer: 'x', result: _result());
    expect(id, 1);
    expect(await old.select(old.teachBackAttempts).get(), hasLength(1));
  });
}
