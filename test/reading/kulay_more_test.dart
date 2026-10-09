import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/reading/levels.dart';
import 'package:kodigno/reading/nlp.dart';
import 'package:kodigno/reading/reading_controller.dart';
import 'package:kodigno/reading/reading_repository.dart';
import 'package:kodigno/reading/story_engine.dart';
import 'package:kodigno/reading/report_pdf.dart';
import 'package:kodigno/reading/ui/story_view.dart' show canExplain;
import 'package:kodigno/ui/theme.dart' show K;
import 'package:pdf/src/pdf/font/ttf_parser.dart' show TtfParser;
import 'package:shared_preferences/shared_preferences.dart';

import 'kulay_ui_test.dart' show pumpKulay;
import 'reading_repository_test.dart' show story;
import 'story_engine_test.dart' show ScriptedRuntime, answerCheck, goodQuestions, goodStory;

/// A model that waits at a gate before it answers, so a test can decide when the story is done.
class _GatedRuntime extends ScriptedRuntime {
  _GatedRuntime(this.gate, super.reply);
  final Future<void> gate;

  @override
  Future<String> chat(List<Map<String, String>> messages, {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) async {
    await gate;
    return super.chat(messages, maxTokens: maxTokens, temperature: temperature, schema: schema);
  }
}

/// An AI that never answers, like a model stuck on a slow computer.
class _StuckRuntime implements LlmRuntime {
  @override
  Future<String> chat(List<Map<String, String>> messages, {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) =>
      Completer<String>().future;

  @override
  Future<String> complete(String prompt, {int maxTokens = 1024, Map<String, Object?>? schema}) => Completer<String>().future;

  @override
  Future<void> dispose() async {}
}

void main() {
  group('starter stories', () {
    final data = (jsonDecode(File('assets/kulay/starter_stories.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
    List<String> flat(Map<String, dynamic> m) => [for (final p in m['paras'] as List) ...List<String>.from(p as List)];
    List<Question> questions(Map<String, dynamic> m) => [for (final q in m['questions'] as List) Question.fromJson(q as Map<String, dynamic>)];
    final mine = data.where((m) => (m['checks'] as Map)['handwritten'] == true).toList();

    test('every starter has 4 different choices, a real answer and a real proof sentence', () {
      for (final m in data) {
        final sentences = flat(m);
        for (final q in questions(m)) {
          final why = '${m['title']}: ${q.question}';
          expect(q.choices.map((c) => c.toLowerCase()).toSet().length, 4, reason: why);
          expect(q.answer, inInclusiveRange(0, 3), reason: why);
          expect(q.evidence, inInclusiveRange(0, sentences.length - 1), reason: why);
        }
      }
      expect({for (final m in data) '${m['level']}|${m['title']}'}.length, data.length, reason: 'a title repeats within a color');
    });

    test('hand-written starters: answers are stated in their proof sentence, and the reading grade fits the color', () {
      const filler = {'a', 'an', 'the', 'his', 'her', 'their', 'my', 'to', 'of', 'and', 'in', 'on'};
      final letters = RegExp(r"[^a-z0-9' -]");
      expect(mine.length, 12);
      for (final m in mine) {
        final sentences = flat(m);
        final level = m['level'] as int;
        final qs = questions(m);
        expect(qs.length, levels[level].q, reason: '${m['title']} question count');
        for (final q in qs) {
          if (const ['Word meaning', 'Main idea', 'Inference'].contains(skillOf(q.question))) continue;
          final words = sentences[q.evidence].toLowerCase().replaceAll(letters, ' ').split(RegExp(r'\s+')).toSet();
          for (final w in q.choices[q.answer].toLowerCase().replaceAll(letters, ' ').split(RegExp(r'\s+'))) {
            if (w.isEmpty || filler.contains(w)) continue;
            expect(words, contains(w), reason: '${m['title']}: "${q.question}" answer word "$w" is not in its proof sentence');
          }
        }
        final band = levels[level].fk;
        final grade = measure(sentences).grade;
        expect(grade, inInclusiveRange(band.$1 - 2.0, band.$2 + 2.0), reason: '${m['title']} measured grade $grade vs ${levels[level].name} $band');
      }
    });

    test('the AI-question checker accepts every good hand-written question and keeps its proof sentence', () {
      var checked = 0;
      for (final m in data) {
        final sentences = flat(m);
        final ent = entities(sentences, null);
        for (final q in questions(m)) {
          if (const ['Main idea', 'Inference'].contains(skillOf(q.question))) continue;
          final raw = {
            'evidence': q.evidence + 1,
            'question': q.question,
            'answer': q.choices[q.answer],
            'wrong': [for (final (i, c) in q.choices.indexed) if (i != q.answer) c],
          };
          final res = checkQuestion(raw, sentences, ent, null);
          final why = '${m['title']}: "${q.question}"';
          expect(res.why, isNull, reason: why);
          expect(res.q!.evidence, q.evidence, reason: '$why proof moved');
          // A made-up wrong choice must not be bad English ("three hour") or still true ("a little glad but very excited").
          for (final c in res.q!.choices) {
            expect(RegExp(r'\b(two|three|four|2|3|4) (hour|minute|day)$').hasMatch(c.toLowerCase()), isFalse, reason: '$why: "$c"');
            expect(RegExp(r'but very excited').hasMatch(c.toLowerCase()) && c != q.choices[q.answer], isFalse, reason: '$why: "$c"');
          }
          checked++;
        }
      }
      expect(checked, greaterThan(90));
    });

    test('a place named in the story is a place, and a school name is not a person', () {
      final s = ['Joel lived in Talisay, a town beside Taal Lake.', 'Rina went to Santa Rosa Elementary School.', 'Ben stayed in Mika\'s room.'];
      final ent = entities(s, null);
      expect(ent.places, contains('Talisay'));
      expect(ent.people, isNot(contains('Talisay')));
      expect(ent.people, isNot(contains('Elementary')));
      expect(ent.people, contains('Mika')); // "in Mika's room" is a person's room, not a place
      expect(fitsKind('Talisay', 'place', ent), isTrue);
    });

    test('Gold and up have a main-idea question, Red and up also a thinking question', () {
      for (final m in mine) {
        final level = m['level'] as int;
        final skillsHere = [for (final q in questions(m)) skillOf(q.question)];
        expect(skillsHere.contains('Main idea'), level >= 2, reason: m['title'] as String);
        expect(skillsHere.contains('Inference'), level >= 4, reason: m['title'] as String);
      }
    });
  });

  group('progress and teacher tools', () {
    late AppDatabase db;
    late ReadingRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ReadingRepository(db);
    });
    tearDown(() => db.close());

    Future<void> readOn(int readerId, DateTime at) async {
      final id = await repo.saveStory(story(0, 'T'));
      await db.into(db.readingAttempts).insert(
          ReadingAttemptsCompanion.insert(readerId: readerId, storyId: id, level: 0, correct: 3, total: 3, takenAt: Value(at)));
    }

    test('new starters are added to a database that already has older ones', () async {
      String one(String t) => jsonEncode({'level': 0, 'topic': 'A', 'title': t, 'paras': [['A.']], 'questions': [], 'checks': {}});
      await repo.loadStarters('[${one('One')}]');
      await repo.loadStarters('[${one('One')}, ${one('Two')}]');
      await repo.loadStarters('[${one('One')}, ${one('Two')}]');
      expect((await db.select(db.stories).get()).map((s) => s.title), ['One', 'Two']);
    });

    test('the day streak counts back from today, or from yesterday, and stops at a gap', () async {
      final r = await repo.addReader('Ana');
      expect(await repo.dayStreak(r.id, now: DateTime(2026, 10, 9, 15)), (days: 0, today: false));
      await readOn(r.id, DateTime(2026, 10, 9, 8));
      await readOn(r.id, DateTime(2026, 10, 9, 18)); // two on one day count once
      await readOn(r.id, DateTime(2026, 10, 8, 20));
      await readOn(r.id, DateTime(2026, 10, 6, 9)); // the 7th is missing
      expect(await repo.dayStreak(r.id, now: DateTime(2026, 10, 9, 15)), (days: 2, today: true));
      expect(await repo.dayStreak(r.id, now: DateTime(2026, 10, 10, 9)), (days: 2, today: false));
      expect(await repo.dayStreak(r.id, now: DateTime(2026, 10, 11, 9)), (days: 0, today: false));
    });

    test('a color reached stays earned after a move down; speeds come back oldest first', () async {
      final r0 = await repo.addReader('Ana');
      await repo.setLevel(r0.id, 2);
      var r = (await repo.reader(r0.id))!;
      for (final wpm in [50, null, 60]) {
        final s = (await repo.story(await repo.saveStory(story(2, 'Fiesta'))))!;
        await repo.answer(r, s, [0, 0, 0], wpm: wpm);
        r = (await repo.reader(r.id))!;
      }
      expect(r.level, 3);
      await repo.setLevel(r.id, 1); // the teacher moves them down
      expect(await repo.bestLevel((await repo.reader(r.id))!), 3);
      expect(await repo.speeds(r.id), [50, 60]);
    });

    test('the reading check can be given again, and the color stays until it is done', () async {
      final r = await repo.addReader('Ana');
      await repo.setLevel(r.id, 3);
      await repo.resetPlacement(r.id);
      final again = (await repo.reader(r.id))!;
      expect((again.placed, again.level), (false, 3));
    });

    test('a story made for one reader shows only to them, at any color; others go by color', () async {
      final a = await repo.addReader('Ana'), b = await repo.addReader('Ben');
      await repo.setLevel(a.id, 2);
      await repo.setLevel(b.id, 2);
      final private = story(5, 'Just for Ben');
      private.checks['for'] = b.id;
      final privateId = await repo.saveStory(private, source: 'teacher');
      final shared = await repo.saveStory(story(2, 'For all'), source: 'teacher');
      expect((await repo.teacherStories(a.id, 2)).map((s) => s.id), [shared]);
      expect((await repo.teacherStories(b.id, 2)).map((s) => s.id), [privateId, shared]);
      expect(ReadingRepository.assignedTo(jsonEncode(private.checks)), b.id);
      expect(ReadingRepository.assignedTo('not json'), isNull);
    });

    test('the class report PDF is a real PDF, and names outside Latin-1 do not break it', () async {
      final r = await repo.addReader('Niño Réyes 李');
      await repo.setLevel(r.id, 1);
      TestWidgetsFlutterBinding.ensureInitialized();
      final font = await loadReportFont();
      final bytes = await buildReportPdf(await repo.classReport(), classroom: true, now: DateTime(2026, 10, 9), font: font);
      final glyphs = TtfParser(font).charToGlyphIndexMap;
      expect(['ñ', 'é', 'Ñ'].every((ch) => glyphs.containsKey(ch.runes.first)), isTrue);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(reportDate(DateTime(2026, 10, 9)), 'Oct 9, 2026');
    });
  });

  group('reading page', () {
    testWidgets('missed questions can be tried again without a new score', (t) async {
      final (c, db) = await pumpKulay(t);
      await c.addReader('Ana');
      await c.repo.setLevel(c.reader!.id, 0);
      final id = await c.repo.saveStory(story(0, 'Fiesta'));
      await c.pickReader(c.reader!);
      await c.readStoryById(id);
      await t.pump(const Duration(seconds: 1));

      c.choose(0, 1); // wrong
      c.choose(1, 0);
      c.choose(2, 1); // wrong
      await c.submitStory();
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Try the missed ones again'), findsOneWidget); // the button

      await t.tap(find.text('Try the missed ones again'));
      await t.pump(const Duration(seconds: 1));
      expect(c.retryOf, [0, 2]);
      expect(find.text('Back to my answers'), findsOneWidget);
      expect(find.text('Try the missed ones again'), findsOneWidget); // now the heading

      c.chooseRetry(0, 0);
      c.chooseRetry(1, 0);
      c.checkRetry();
      await t.pump(const Duration(seconds: 1));
      expect(c.retryChecked, isTrue);
      expect((await db.select(db.readingAttempts).get()).length, 1); // the first try is the only score

      c.endRetry();
      await t.pump(const Duration(seconds: 1));
      expect(c.retryOf, isNull);
      expect(t.takeException(), isNull);
    });

    testWidgets('Aa makes the text larger and switches the easy-read letters', (t) async {
      final (c, _) = await pumpKulay(t);
      await c.addReader('Ana'); // starts the reading check
      await t.pump(const Duration(seconds: 1));
      expect(c.textScale, 1.0);
      await t.tap(find.byTooltip('Reading look: text size, easy-read font and dark mode'));
      await t.pumpAndSettle();
      expect(find.text('Make reading easier'), findsOneWidget);
      await t.tap(find.text('Large'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(SwitchListTile, 'Easy-read letters'));
      await t.pumpAndSettle();
      expect((c.textSize, c.textScale, c.easyFont), (1, 1.2, true));
      expect(c.darkMode, isFalse);

      // Dark mode: saved, and Kulay redraws with its dark colors.
      await t.tap(find.widgetWithText(SwitchListTile, 'Dark mode'));
      await t.pumpAndSettle();
      expect(c.darkMode, isTrue);
      expect(c.prefs.getBool('kulay.dark'), isTrue);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      final scaffold = t.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFF1C1736)); // the dark frame
      expect(t.takeException(), isNull);
    });

    testWidgets("a reader's page shows the day streak, their badges and the teacher's story", (t) async {
      final (c, db) = await pumpKulay(t);
      await c.addReader('Ana');
      await c.repo.setLevel(c.reader!.id, 2);
      final now = DateTime.now();
      for (final at in [now, now.subtract(const Duration(days: 1))]) {
        final id = await c.repo.saveStory(story(0, 'T'));
        await db.into(db.readingAttempts).insert(
            ReadingAttemptsCompanion.insert(readerId: c.reader!.id, storyId: id, level: 0, correct: 3, total: 3, takenAt: Value(at)));
      }
      await c.repo.saveStory(story(2, 'Class trip'), source: 'teacher');
      await c.pickReader(c.reader!);
      await t.pump();
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300))); // the page's queries run on the real clock
      await t.pump(const Duration(seconds: 1));
      expect(find.text('2 days in a row.'), findsOneWidget);
      expect(find.text('From your teacher'), findsOneWidget);
      expect(find.text('A Class trip story'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsNWidgets(3)); // Aqua, Lime, Gold
      expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(5));
      expect(t.takeException(), isNull);
    });
  });

  group('bug fixes', () {
    late AppDatabase db;
    late ReadingRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ReadingRepository(db);
    });
    tearDown(() => db.close());

    test('small helper words cannot be tapped for help, real words and names are handled', () {
      for (final w in ['about', 'there', 'would', 'be', 'The']) {
        expect(canExplain(w), isFalse, reason: w);
      }
      for (final w in ['carabao', 'proud', 'because']) {
        expect(canExplain(w), isTrue, reason: w);
      }
    });

    test("a teacher's text is kept whole: a heading and a repeated line stay", () {
      final paras = splitStory('Our Class Trip\n\nWe went to the park. We went to the park. Yes! Dr. Cruz smiled.', keepAll: true);
      expect(paras, [
        ['Our Class Trip'],
        ['We went to the park.', 'We went to the park.', 'Yes!', 'Dr. Cruz smiled.'],
      ]);
      // An AI draft still loses the repeat and the cut-off fragment.
      expect(splitStory('We went to the park. We went to the park. And then'), [
        ['We went to the park.']
      ]);
    });

    test('a topic request never serves a teacher story, which may be for someone else', () async {
      final r = await repo.addReader('Ana');
      await repo.setLevel(r.id, 2);
      await repo.saveStory(story(2, 'Class trip'), source: 'teacher');
      expect(await repo.unread(r.id, 2, 'Class trip'), isNull);
      expect(await repo.unread(r.id, 2, null), isNull);
      expect(await repo.anyStory(2), isNull);
    });

    Future<ReadingController> controllerFor(ScriptedRuntime rt) async {
      SharedPreferences.setMockInitialValues({});
      final c = ReadingController(repo: repo, engine: StoryEngine(() async => rt, random: Random(1)), prefs: await SharedPreferences.getInstance());
      await c.addReader('Ana');
      await repo.setLevel(c.reader!.id, 0);
      await c.pickReader(c.reader!);
      await repo.saveStory(story(0, 'Jeepney ride'));
      return c;
    }

    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 300 && !done(); i++) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }

    test('the story asked for is remembered while a saved one is read, and the reader is told when it is ready', () async {
      final gate = Completer<void>();
      String? name;
      final c = await controllerFor(_GatedRuntime(gate.future, (system, user) {
        if (user.startsWith('Write a story')) return goodStory(name = RegExp(r'Main character: (\w+)').firstMatch(user)![1]!);
        if (system.contains('careful student')) return answerCheck(user);
        return goodQuestions(name!);
      }));
      unawaited(c.readTopic('Basketball'));
      await until(() => c.screen == KulayScreenId.writing);
      await c.readSavedInstead();
      expect((c.screen, c.waitingTopic, c.waitingState), (KulayScreenId.story, 'Basketball', Waiting.writing));

      gate.complete(); // the AI finishes while the reader is on the saved story
      await until(() => c.waitingState == Waiting.ready);
      expect((c.screen, c.waitingState), (KulayScreenId.story, Waiting.ready));
      expect((c.passage as Story).topic, 'Jeepney ride'); // still on the saved story: not pulled away

      await c.readWaiting();
      expect((c.passage as Story).topic, 'Basketball');
      expect(c.waitingTopic, isNull);
    });

    test('leaving the writing screen for My page also keeps the story, and a failure is reported', () async {
      final gate = Completer<void>();
      final c = await controllerFor(_GatedRuntime(gate.future, (_, _) => throw ModelUnavailableException('test')));
      unawaited(c.readTopic('Basketball'));
      await until(() => c.screen == KulayScreenId.writing);
      await c.goHome();
      expect((c.waitingTopic, c.waitingState), ('Basketball', Waiting.writing));
      gate.complete();
      await until(() => c.waitingState == Waiting.failed);
      expect(c.waitingState, Waiting.failed);
      expect(c.screen, KulayScreenId.home);
      c.dismissWaiting();
      expect(c.waitingTopic, isNull);
    });

    test('a reader can stop waiting for a stuck AI and read a saved story', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ReadingController(
        repo: repo,
        engine: StoryEngine(() async => _StuckRuntime()),
        prefs: await SharedPreferences.getInstance(),
      );
      await c.addReader('Ana');
      await repo.setLevel(c.reader!.id, 1);
      await c.pickReader(c.reader!);
      expect(await (() async {
        c.readSavedInstead(); // not on the writing screen yet: does nothing
        return c.screen;
      })(), KulayScreenId.home);

      unawaited(c.readTopic('Fiesta')); // the AI never answers
      await Future.delayed(const Duration(milliseconds: 50));
      expect(c.screen, KulayScreenId.writing);
      await c.readSavedInstead();
      expect(c.error, contains('no saved stories')); // none yet: stays put, says so
      expect(c.screen, KulayScreenId.writing);

      final id = await repo.saveStory(story(1, 'Basketball'));
      await c.readSavedInstead();
      expect(c.screen, KulayScreenId.story);
      expect((c.passage as Story).id, id);
      expect(c.notice, contains('saved story'));
      c.cancelAll();
    });

    test("a teacher's story is extra practice: it never moves a color or breaks a streak", () async {
      final r0 = await repo.addReader('Ana');
      await repo.setLevel(r0.id, 2);
      var r = (await repo.reader(r0.id))!;
      Future<AnswerResult> read(Story s, List<int> a) async => repo.answer(r, s, a);
      final good = (await repo.story(await repo.saveStory(story(2, 'A'))))!;
      final good2 = (await repo.story(await repo.saveStory(story(2, 'B'))))!;
      await read(good, [0, 0, 0]);
      await read(good2, [0, 0, 0]);
      // A teacher's story at another color, answered badly, between two strong scores.
      final extra = (await repo.story(await repo.saveStory(story(6, 'Hard'), source: 'teacher')))!;
      final res = await read(extra, [1, 1, 1]);
      expect((res.from, res.level, res.up), (2, 2, 2));
      final third = (await repo.story(await repo.saveStory(story(2, 'C'))))!;
      final up = await read(third, [0, 0, 0]);
      expect(up.level, 3); // the third strong score still moves the reader up
      r = (await repo.reader(r.id))!;
      expect(r.level, 3);
      final rep = await repo.classReport();
      expect(rep.readers.single.stories, 4); // all four are in the teacher's report
    });

  });

  group('bug fixes on screen', () {
    testWidgets('Submitting twice saves one score, and a teacher story starts no new AI story', (t) async {
      final (c, d) = await pumpKulay(t);
      await c.addReader('Ana');
      await c.repo.setLevel(c.reader!.id, 0);
      final story0 = story(0, 'Trip');
      final id = await c.repo.saveStory(story0, source: 'teacher');
      await c.pickReader(c.reader!);
      await c.readStoryById(id);
      for (var i = 0; i < 3; i++) {
        c.choose(i, 0);
      }
      await Future.wait([c.submitStory(), c.submitStory()]);
      await t.pump(const Duration(seconds: 1));
      expect((await d.select(d.readingAttempts).get()).length, 1);
      // The result: a skill summary, no "next story" for a teacher story.
      expect(find.text('Details  3 of 3'), findsOneWidget);
      expect(find.textContaining('Next Trip story'), findsNothing);
      expect(find.text('Back to my page'), findsOneWidget);
      expect((await d.select(d.stories).get()).length, 1); // nothing was prefetched
      expect(t.takeException(), isNull);
    });

    testWidgets('in dark mode Kulay keeps its light colors, so its buttons can be read', (t) async {
      K.dark = true;
      addTearDown(() => K.dark = false);
      await pumpKulay(t);
      final theme = Theme.of(t.element(find.text('Go to Kodigno')));
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF2E2378));
    });
  });
}
