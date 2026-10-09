import 'dart:convert';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/reading/nlp.dart';
import 'package:kodigno/reading/reading_repository.dart';
import 'package:kodigno/reading/story_engine.dart';

import 'reading_repository_test.dart' show story;
import 'story_engine_test.dart' show ScriptedRuntime, goodQuestions;

const _mainIdea = 'Ben and Lito had fun playing basketball';

/// The AI reader: picks the choice that is one of the true answers.
String _reader(String user) {
  const truth = ['cebu', 'red', 'happy', 'lito'];
  for (final m in RegExp(r'^([ABCD])\) (.+)$', multiLine: true).allMatches(user)) {
    final c = m[2]!.toLowerCase();
    if (truth.contains(c) || c == _mainIdea.toLowerCase()) return jsonEncode({'answer': m[1]});
  }
  return jsonEncode({'answer': 'A'});
}

const _text = 'Ben lived in Cebu. Ben liked to play basketball. He had a red ball.\n\n'
    'One day Ben went to the park. His friend Lito was there. They played basketball.\n\n'
    'Ben made a shot. Lito clapped his hands. Ben felt happy.';

String _deepReply(String user) => jsonEncode({
      'evidence': 1,
      'question': 'ignored',
      'answer': _mainIdea,
      'wrong': ['Ben lost his red ball', 'Lito moved to Davao', 'A storm closed the park'],
    });

void main() {
  group('question skills', () {
    test('sequence, main idea and inference are told apart from details', () {
      expect(skillOf('What did Ben do first?'), 'Sequence');
      expect(skillOf('What happened after the shot?'), 'Sequence');
      expect(skillOf('What is this story mostly about?'), 'Main idea');
      expect(skillOf('Why do you think Ben felt proud?'), 'Inference');
      expect(skillOf('What can you tell about Lito?'), 'Inference');
      expect(skillOf('Why did Ben go to the park?'), 'Cause and effect');
      expect(skillOf('Where did Ben live?'), 'Details');
    });

    final sents = ['Ben lived in Cebu.', 'Ben liked to play basketball.', 'Lito clapped his hands.', 'Ben felt happy.'];
    Map<String, dynamic> raw({String q = 'ignored', List<String>? wrong}) =>
        {'evidence': 2, 'question': q, 'answer': _mainIdea, 'wrong': wrong ?? ['Ben lost his ball', 'Lito moved away', 'A storm came']};

    test('a main-idea question gets a fixed question and 4 shuffled choices', () {
      final res = checkDeep(raw(), sents, mainIdea: true);
      expect(res.why, isNull);
      expect(res.q!.question, 'What is this story mostly about?');
      expect(res.q!.choices[res.q!.answer], _mainIdea);
      expect(res.q!.evidence, inInclusiveRange(0, sents.length - 1));
    });

    test('an inference question must open with the right words; repeats and placeholders fail', () {
      expect(checkDeep(raw(q: 'Where did Ben live?'), sents, mainIdea: false).why, contains('Why do you think'));
      final ok = checkDeep(raw(q: 'Why do you think Ben felt happy'), sents, mainIdea: false);
      expect(ok.q!.question, 'Why do you think Ben felt happy?');
      expect(checkDeep(raw(wrong: ['Ben lost his ball', 'Ben lost his ball', 'x']), sents, mainIdea: true).why, isNotNull);
      expect(checkDeep(raw(wrong: ['Ben lost his ball', 'Lito moved away', 'All of the above']), sents, mainIdea: true).why, isNotNull);
      expect(checkDeep(raw(wrong: ['a b c d e f g h i j k l m', 'Lito moved away', 'x y']), sents, mainIdea: true).why, isNotNull);
    });
  });

  group('teacher stories', () {
    ScriptedRuntime runtime() => ScriptedRuntime((system, user) {
          if (system.contains('careful student')) return _reader(user);
          if (user.contains('about the main idea')) return _deepReply(user);
          return goodQuestions('Ben');
        });

    test('the text is kept as written, and a main-idea question comes last from Gold up', () async {
      final s = await StoryEngine(() async => runtime(), random: Random(1))
          .makeTeacherStory('Ben at the park', _text, level: 2, job: Job(Priority.reader));
      expect(s.level, 2);
      expect(s.sentences.first, 'Ben lived in Cebu.');
      expect(s.sentences.length, 9);
      expect(s.questions.length, 4);
      expect(s.questions.last.question, 'What is this story mostly about?');
      expect(s.questions.last.choices[s.questions.last.answer], _mainIdea);
      expect(s.checks['teacher'], isTrue);
    });

    test('Aqua gets no main-idea question, and the color is picked from the text when not given', () async {
      final aqua = await StoryEngine(() async => runtime(), random: Random(1))
          .makeTeacherStory('Ben', _text, level: 0, job: Job(Priority.reader));
      expect(aqua.questions.length, 3);
      expect(aqua.questions.any((q) => q.question.contains('mostly about')), isFalse);
      final auto = await StoryEngine(() async => runtime(), random: Random(1)).makeTeacherStory('Ben', _text, job: Job(Priority.reader));
      expect(auto.level, inInclusiveRange(0, 7));
    });

    test('a text that is too short is turned away before the AI is asked', () async {
      final rt = runtime();
      await expectLater(
          StoryEngine(() async => rt).makeTeacherStory('Short', 'Ben ran. Ben sat.', job: Job(Priority.reader)), throwsA(isA<StoryFailed>()));
      expect(rt.calls, isEmpty);
    });

    test('a failing main-idea question is dropped, not shown', () async {
      final rt = ScriptedRuntime((system, user) {
        if (system.contains('careful student')) return _reader(user);
        if (user.contains('about the main idea')) return jsonEncode({'evidence': 1, 'question': 'x', 'answer': 'only one choice', 'wrong': []});
        return goodQuestions('Ben');
      });
      final s = await StoryEngine(() async => rt, random: Random(1)).makeTeacherStory('Ben', _text, level: 2, job: Job(Priority.reader));
      expect(s.questions.length, 3);
      expect(s.checks['dropped'], 1);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late ReadingRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ReadingRepository(db);
    });
    tearDown(() => db.close());

    test('My Words: asking again counts, 3 right in a row learns it, a miss starts over', () async {
      final r = await repo.addReader('Ana');
      await repo.saveWord(r.id, 'Vendor', 'A person who sells things', 'seller', 'The vendor sold fish.');
      await repo.saveWord(r.id, 'vendor', 'Someone who sells', null, 'A vendor came.');
      var w = (await repo.words(r.id)).single;
      expect((w.word, w.times, w.meaning, w.synonym), ('vendor', 2, 'Someone who sells', null));
      await repo.markWord(w.id, right: true);
      await repo.markWord(w.id, right: true);
      expect((await repo.words(r.id)).single.known, 2);
      await repo.markWord(w.id, right: false);
      w = (await repo.words(r.id)).single;
      expect(w.known, 0);
    });

    test('words belong to one reader and go when the reader goes', () async {
      final a = await repo.addReader('Ana'), b = await repo.addReader('Ben');
      await repo.saveWord(a.id, 'brave', 'not afraid', null, 'She was brave.');
      expect(await repo.words(b.id), isEmpty);
      await repo.deleteReader(a.id);
      expect(await db.select(db.savedWords).get(), isEmpty);
    });

    test('reading speed is saved with the score and averaged for the teacher', () async {
      final r = await repo.addReader('Ana');
      await repo.setLevel(r.id, 2);
      final reader = (await repo.reader(r.id))!;
      await repo.answer(reader, (await repo.story(await repo.saveStory(story(2, 'Fiesta'))))!, [0, 0, 0], wpm: 60);
      await repo.answer(reader, (await repo.story(await repo.saveStory(story(2, 'Fiesta'))))!, [0, 0, 0], wpm: 80);
      await repo.answer(reader, (await repo.story(await repo.saveStory(story(2, 'Fiesta'))))!, [0, 0, 0]); // not timed
      expect((await repo.classReport()).readers.single.wpm, 70);
    });

    test('teacher stories show for readers at that color until read, and only unread ones can be deleted', () async {
      final r = await repo.addReader('Ana');
      await repo.setLevel(r.id, 2);
      final mine = await repo.saveStory(story(2, 'Our trip'), source: 'teacher');
      await repo.saveStory(story(3, 'Other color'), source: 'teacher');
      await repo.saveStory(story(2, 'Fiesta'));
      expect((await repo.teacherStories(r.id, 2)).map((s) => s.id), [mine]);
      expect(await repo.allTeacherStories(), hasLength(2));

      await repo.answer((await repo.reader(r.id))!, (await repo.story(mine))!, [0, 0, 0]);
      expect(await repo.teacherStories(r.id, 2), isEmpty);
      expect(await repo.deleteTeacherStory(mine), isFalse); // has a score
      final other = (await repo.allTeacherStories()).firstWhere((s) => s.id != mine).id;
      expect(await repo.deleteTeacherStory(other), isTrue);
      expect(await repo.allTeacherStories(), hasLength(1));
    });
  });
}
