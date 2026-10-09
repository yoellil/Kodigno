import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/reading/levels.dart';
import 'package:kodigno/reading/reading_controller.dart';
import 'package:kodigno/reading/reading_repository.dart';
import 'package:kodigno/reading/story_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'story_engine_test.dart' show ScriptedRuntime;

WrittenStory story(int level, String topic, {int questions = 3}) => WrittenStory(
      level,
      topic,
      'A $topic story',
      [
        ['Mika went to the park.', 'Mika saw Jun.'],
        ['They played.', 'Mika felt happy.']
      ],
      [for (var i = 0; i < questions; i++) Question('Where did Mika go? $i', ['The park', 'b', 'c', 'd'], 0, 0)],
      {'v': pipelineVersion},
    );

void main() {
  late AppDatabase db;
  late ReadingRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ReadingRepository(db);
  });
  tearDown(() => db.close());

  test('reader names are unique, ignoring case', () async {
    await repo.addReader('Ana R');
    expect(() => repo.addReader('  ana   r '), throwsA(isA<DuplicateReader>()));
    expect(() => repo.addReader('   '), throwsArgumentError);
  });

  test('unread skips stories the reader answered and other colors and old pipelines', () async {
    final r = await repo.addReader('Ana');
    final a = await repo.saveStory(story(2, 'Fiesta'));
    final b = await repo.saveStory(story(2, 'Fiesta'));
    await repo.saveStory(story(3, 'Fiesta'));
    await db.into(db.stories).insert(StoriesCompanion.insert(
        level: 2, topic: 'Fiesta', title: 'old', paras: '[]', questions: '[]', pipeline: pipelineVersion - 1));
    expect(await repo.unread(r.id, 2, 'fiesta'), a);
    await repo.answer(r.copyWith(level: 2), (await repo.story(a))!, [0, 0, 0]);
    expect(await repo.unread(r.id, 2, 'Fiesta'), b);
    expect(await repo.unread(r.id, 2, 'Basketball'), isNull);
    expect(await repo.unread(r.id, 2, null), b);
  });

  test('3 strong scores move a reader up; the teacher report counts skills', () async {
    await repo.addReader('Ana');
    await repo.setLevel((await repo.readers()).single.id, 2);
    var r = (await repo.readers()).single;
    AnswerResult? res;
    for (var i = 0; i < 3; i++) {
      final s = (await repo.story(await repo.saveStory(story(2, 'Fiesta'))))!;
      res = await repo.answer(r, s, [0, 0, 0]);
      r = (await repo.reader(r.id))!;
    }
    expect(res!.from, 2);
    expect(res.level, 3);
    expect(r.level, 3);
    final rep = await repo.classReport();
    expect(rep.readers.single.stories, 3);
    expect(rep.readers.single.avg, 100);
    expect(rep.skills['Details'], (9, 9));
    expect(rep.focus, isNull);
  });

  test('the weakest skill under 70% is the one to teach next', () {
    expect(weakest({'Details': (9, 10), 'Feelings': (1, 4), 'Word meaning': (0, 2)})?.skill, 'Feelings');
    expect(weakest({'Details': (9, 10)}), isNull);
  });

  test('starter stories load once', () async {
    final json = jsonEncode([
      {'level': 0, 'topic': 'Fiesta', 'title': 'T', 'paras': [['A.']], 'questions': [], 'checks': {}}
    ]);
    await repo.loadStarters(json);
    await repo.loadStarters(json);
    expect((await db.select(db.stories).get()).length, 1);
  });

  test('upgrading a version 1 database keeps study sets and adds the Kulay tables', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true; // a second, separate in-memory database
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE study_sets (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, '
          "source_type TEXT NOT NULL DEFAULT 'text', source_text TEXT NOT NULL DEFAULT '', "
          "source_paths TEXT NOT NULL DEFAULT '[]', created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))");
      raw.execute("INSERT INTO study_sets (title) VALUES ('Biology')");
      raw.execute('PRAGMA user_version = 1');
    }));
    expect((await old.select(old.studySets).get()).single.title, 'Biology');
    final r = await ReadingRepository(old).addReader('Ana');
    expect(r.placed, isFalse);
    await old.close();
  });

  group('controller', () {
    late ReadingController c;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      c = ReadingController(
        repo: repo,
        engine: StoryEngine(() async => ScriptedRuntime((_, _) => throw ModelUnavailableException('test'))),
        prefs: await SharedPreferences.getInstance(),
      );
    });

    test('a new class reader takes the reading check and lands on a color', () async {
      await c.open();
      expect(c.screen, KulayScreenId.welcome);
      await c.setMode(KulayMode.classroom);
      expect(c.screen, KulayScreenId.readers);
      expect(await c.addReader('Ana'), isNull);
      expect(c.screen, KulayScreenId.placement);
      // Pass the first two passages, fail the third: between Gold and Red.
      for (final pass in [true, true, false]) {
        final p = c.passage!;
        for (final (i, q) in p.questions.indexed) {
          c.choose(i, pass ? q.answer : (q.answer + 1) % 4);
        }
        c.checkPlacement();
        await c.nextPlacement();
      }
      expect(c.screen, KulayScreenId.home);
      expect(c.reader!.level, placement[2].level - 1);
      expect(c.reader!.placed, isTrue);
    });

    test('with the AI down, a saved story at the color is offered, then served with a notice', () async {
      await c.setMode(KulayMode.personal);
      await c.addReader('Ana');
      await repo.setLevel(c.reader!.id, 1);
      await c.pickReader(c.reader!);
      await repo.saveStory(story(1, 'Fiesta'), source: 'starter');
      await c.readTopic('Basketball');
      // Not swapped in: the reader is told and offered the Fiesta story.
      expect(c.screen, KulayScreenId.writing);
      expect(c.error, contains('Basketball'));
      expect(c.fallbackTopic, 'Fiesta');
      await c.readFallback();
      expect(c.screen, KulayScreenId.story);
      expect(c.notice, contains('ready Fiesta story'));
      for (var i = 0; i < c.answers.length; i++) {
        c.choose(i, 1); // all wrong
      }
      await c.submitStory();
      expect(c.result!.correct, 0);
    });

    test('teacher PIN is set once, then checked', () async {
      await c.setMode(KulayMode.classroom);
      expect(c.hasPin, isFalse);
      expect(await c.unlockTeacher('12'), isFalse);
      expect(await c.unlockTeacher('1234'), isTrue);
      expect(c.hasPin, isTrue);
      expect(await c.unlockTeacher('9999'), isFalse);
      expect(await c.unlockTeacher('1234'), isTrue);
    });
  });
}
