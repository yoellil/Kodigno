import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/reading/story_engine.dart';

/// Answers by looking at the prompt, so the story can use whatever name the planner picked.
class ScriptedRuntime implements LlmRuntime {
  ScriptedRuntime(this.reply);
  final String Function(String system, String user) reply;
  final calls = <String>[];

  @override
  Future<String> chat(List<Map<String, String>> messages,
      {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) async {
    final system = messages.first['content']!, user = messages.last['content']!;
    calls.add(user);
    return reply(system, user);
  }

  @override
  Future<String> complete(String prompt, {int maxTokens = 1024, Map<String, Object?>? schema}) =>
      chat([{'role': 'user', 'content': prompt}]);

  @override
  Future<void> dispose() async {}
}

String _name(String user) => RegExp(r'Main character: (\w+)').firstMatch(user)![1]!;

String goodStory(String n) => jsonEncode({
      'title': '$n and the Ball',
      'paragraphs': [
        '$n lived in Cebu. $n liked to play basketball. He had a red ball.',
        'One day $n went to the park. His friend Lito was there. They played basketball.',
        '$n made a shot. Lito clapped his hands. $n felt happy.',
      ],
    });

String goodQuestions(String n) => jsonEncode({
      'questions': [
        {'evidence': 1, 'question': 'Where did $n live?', 'answer': 'Cebu', 'wrong': ['Davao', 'Iloilo', 'Baguio']},
        {'evidence': 3, 'question': "What color was $n's ball?", 'answer': 'red', 'wrong': ['blue', 'green', 'yellow']},
        {'evidence': 9, 'question': 'How did $n feel after the shot?', 'answer': 'happy', 'wrong': ['sad', 'angry', 'scared']},
        {'evidence': 8, 'question': 'Who clapped his hands?', 'answer': 'Lito', 'wrong': ['the coach', 'a neighbor', 'the teacher']},
      ],
    });

/// The AI reader: picks the choice that is one of the true answers.
String answerCheck(String user) {
  const truth = ['cebu', 'red', 'happy', 'lito'];
  for (final m in RegExp(r'^([ABCD])\) (.+)$', multiLine: true).allMatches(user)) {
    if (truth.contains(m[2]!.toLowerCase())) return jsonEncode({'answer': m[1]});
  }
  return jsonEncode({'answer': 'A'});
}

void main() {
  test('writes a checked story whose answers are stated in their proof sentences', () async {
    String? name;
    final rt = ScriptedRuntime((system, user) {
      if (user.startsWith('Write a story')) return goodStory(name = _name(user));
      if (system.contains('careful student')) return answerCheck(user);
      return goodQuestions(name!);
    });
    final engine = StoryEngine(() async => rt, random: Random(1));
    final steps = <int>[];
    final s = await engine.makeStory(0, 'Basketball', job: Job(Priority.reader), onStep: (n, _) => steps.add(n));
    expect(s.questions.length, 3);
    expect(s.checks['v'], pipelineVersion);
    expect(s.checks['drafts'], 1);
    for (final q in s.questions) {
      expect(s.sentences[q.evidence].toLowerCase(), contains(q.choices[q.answer].toLowerCase()));
    }
    expect(steps, containsAll([2, 3, 4, 5, 6, 7]));
  });

  test('a draft that drops the name, or broken JSON, is rewritten', () async {
    var drafts = 0;
    String? name;
    final rt = ScriptedRuntime((system, user) {
      if (user.startsWith('Write a story')) {
        drafts++;
        name = _name(user);
        if (drafts == 1) return '{"title": "x", "paragraphs": ['; // cut off
        if (drafts == 2) return '{"title": "x", "paragraphs": [';
        if (drafts == 3) return goodStory('Someone');
        expect(user, contains('Your last draft had these problems'));
        return goodStory(name!);
      }
      if (system.contains('careful student')) return answerCheck(user);
      return goodQuestions(name!);
    });
    final s = await StoryEngine(() async => rt, random: Random(2)).makeStory(0, 'Basketball', job: Job(Priority.reader));
    expect(s.checks['drafts'], 3); // draft 1 broken twice, draft 2 unnamed, draft 3 good
    expect(s.paras.first.first, startsWith(name!));
  });

  test('a question the AI reader gets wrong is thrown out', () async {
    String? name;
    final rt = ScriptedRuntime((system, user) {
      if (user.startsWith('Write a story')) return goodStory(name = _name(user));
      if (system.contains('careful student')) {
        // Misses only the color question.
        if (user.contains('What color')) return _wrongLetter(user);
        return answerCheck(user);
      }
      if (user.contains('This question failed')) return jsonEncode({'evidence': 3, 'question': 'What did $name have?', 'answer': 'a red ball', 'wrong': ['x']});
      return goodQuestions(name!);
    });
    final s = await StoryEngine(() async => rt, random: Random(3)).makeStory(0, 'Basketball', job: Job(Priority.reader));
    expect(s.questions.any((q) => q.question.contains('What color')), isFalse);
    expect(s.checks['rewritten'], 1);
    expect(s.questions.length, 3);
  });

  test('word help rejects a meaning that uses the word, then falls back to the synonym', () async {
    var tries = 0;
    final rt = ScriptedRuntime((system, user) {
      tries++;
      return jsonEncode({'meaning': 'a vendor who vends', 'synonym': 'seller'});
    });
    final w = await StoryEngine(() async => rt).explainWord('vendor', 'The vendor sold fish.', 1);
    expect(tries, 3);
    expect(w.meaning, 'It means about the same as "seller".');
    expect(w.synonym, isNull);
  });

  test('a waiting word lookup goes ahead of background writing', () async {
    final line = CallLine();
    final order = <String>[];
    final gate = Completer<void>();
    final bg1 = line.run(Job(Priority.background), () async {
      await gate.future;
      order.add('bg1');
    });
    final bg2 = line.run(Job(Priority.background), () async => order.add('bg2'));
    final word = line.run(Job(Priority.word), () async => order.add('word'));
    gate.complete();
    await Future.wait([bg1, bg2, word]);
    expect(order, ['bg1', 'word', 'bg2']);
  });
}

String _wrongLetter(String user) {
  for (final m in RegExp(r'^([ABCD])\) (.+)$', multiLine: true).allMatches(user)) {
    if (m[2]!.toLowerCase() != 'red') return jsonEncode({'answer': m[1]});
  }
  return jsonEncode({'answer': 'A'});
}
