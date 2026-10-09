import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/ai/llm_ai_engine.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/summary.dart';
import 'package:kodigno/models/tier.dart';
import 'package:kodigno/study/teach_judge.dart';

const _tier = Tier(
  id: 'standard',
  label: 'Standard',
  model: 'm',
  url: 'u',
  sha256: 's',
  maxRamMb: null,
  sizeMb: 1000,
  chunkChars: 1500,
  questionsPerChunk: 5,
  cardsPerChunk: 5,
);

/// Returns scripted answers, and keeps the prompt and temperature of each call.
class _Runtime implements LlmRuntime {
  _Runtime(this.script);
  final List<Object> script;
  final prompts = <String>[];
  final temperatures = <double>[];
  final schemas = <Map<String, Object?>?>[];

  @override
  Future<String> complete(String prompt, {int maxTokens = 1024, Map<String, Object?>? schema}) =>
      chat([{'role': 'user', 'content': prompt}], maxTokens: maxTokens, schema: schema);

  @override
  Future<String> chat(List<Map<String, String>> messages,
      {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) async {
    prompts.add(messages.last['content']!);
    temperatures.add(temperature);
    schemas.add(schema);
    final next = script.removeAt(0);
    if (next is Exception) throw next;
    return next as String;
  }

  @override
  Future<void> dispose() async {}
}

const _slides = 'A patent permits its owner to exclude the public from making, using, or selling a protected invention, and it allows for legal action against violators.\n'
    'A utility patent is issued for the invention of a new and useful process, machine, or composition of matter.\n'
    'A design patent protects a new, original, and ornamental design of an article.';

const _c1 = 'A patent lets the owner stop the public from making, using, or selling a protected invention.';
const _c2 = 'A utility patent covers a new and useful process, machine, or composition of matter.';

String _concepts(List<String> c) => jsonEncode({'concepts': c});

const _answer = 'A patent gives the owner the right to stop other people from making, using or selling their invention. A design patent covers how a thing looks.';

String _judged(List<(String, String)> ideas) => jsonEncode({
      'ideas': [for (final (v, e) in ideas) {'verdict': v, 'evidence': e}],
      'opposites': <Object>[],
    });

LlmAiEngine _engine(_Runtime rt) => LlmAiEngine(rt, _tier);

void main() {
  group('topicConcepts', () {
    test('asks the model about the slides, and keeps the ideas the slides back up', () async {
      final rt = _Runtime([_concepts([_c1, _c2])]);
      final c = await _engine(rt).topicConcepts(_slides, topic: 'Patents');
      expect(c, [_c1, _c2]);
      expect(rt.prompts.single, contains('TOPIC: Patents'));
      expect(rt.prompts.single, contains('A utility patent is issued'));
      expect(rt.schemas.single, isNotNull); // the output is held to a shape
    });

    test('the first try uses no randomness, a retry a little', () async {
      final rt = _Runtime(['not json', _concepts([_c1, _c2])]);
      expect(await _engine(rt).topicConcepts(_slides), hasLength(2));
      expect(rt.temperatures, [0, 0.3]);
    });

    test('too few usable ideas, or only unusable output, gives none', () async {
      expect(await _engine(_Runtime([_concepts([_c1]), _concepts([_c1]), _concepts([_c1])])).topicConcepts(_slides), isEmpty);
      expect(await _engine(_Runtime(['nope', 'nope', 'nope'])).topicConcepts(_slides), isEmpty);
      expect(
          await _engine(_Runtime([
            _concepts(['Volcanoes erupt when magma rises through cracks in the crust of the planet.', 'Whales sing songs that travel across the whole ocean for miles.']),
            _concepts([]),
            _concepts([]),
          ])).topicConcepts(_slides),
          isEmpty);
    });

    test('a model that cannot run is not retried, and says so', () async {
      final rt = _Runtime([ModelUnavailableException('oom')]);
      await expectLater(_engine(rt).topicConcepts(_slides), throwsA(isA<ModelUnavailableException>()));
      expect(rt.prompts, hasLength(1));
    });

    test('a very long topic is cut down to its most central lines for the prompt', () async {
      final long = [for (var i = 0; i < 80; i++) 'Sentence number $i says something about patents and the invention that is protected by them.'].join('\n');
      final rt = _Runtime([_concepts([_c1, _c2])]);
      await _engine(rt).topicConcepts('$_slides\n$long');
      expect(rt.prompts.single.length, lessThan(4200));
    });
  });

  group('judgeExplanation', () {
    test('gives the model\'s verdicts, each checked against what the student wrote', () async {
      final rt = _Runtime([
        _judged([
          ('yes', 'stop other people from making, using or selling their invention'),
          ('yes', 'a quote that the student never wrote at all, so it is no proof'),
        ]),
      ]);
      final j = await _engine(rt).judgeExplanation(concepts: const [_c1, _c2], answer: _answer, slideText: _slides);
      expect(j.concepts.map((c) => c.verdict), [Verdict.yes, null]);
      expect(rt.prompts.single, contains('1. $_c1'));
      expect(rt.prompts.single, contains(_answer));
      expect(rt.temperatures.single, 0);
    });

    test('a malformed answer is asked again, a little less strictly', () async {
      final rt = _Runtime([
        'not json',
        _judged([('no', ''), ('no', '')]),
      ]);
      final j = await _engine(rt).judgeExplanation(concepts: const [_c1, _c2], answer: _answer, slideText: _slides);
      expect(j.concepts, hasLength(2));
      expect(rt.temperatures, [0, 0.3]);
    });

    test('the wrong number of verdicts counts as malformed', () async {
      final rt = _Runtime([_judged([('no', '')]), _judged([('no', '')]), _judged([('no', '')])]);
      await expectLater(
          _engine(rt).judgeExplanation(concepts: const [_c1, _c2], answer: _answer, slideText: _slides),
          throwsA(isA<GenerationFailed>()));
    });

    test('nothing usable after the tries is a failure, and a model that cannot run is passed on', () async {
      await expectLater(
          _engine(_Runtime(['x', 'y', 'z'])).judgeExplanation(concepts: const [_c1], answer: _answer, slideText: _slides),
          throwsA(isA<GenerationFailed>()));
      await expectLater(
          _engine(_Runtime([ModelUnavailableException('oom')])).judgeExplanation(concepts: const [_c1], answer: _answer, slideText: _slides),
          throwsA(isA<ModelUnavailableException>()));
    });

    test('a very long explanation is cut for the prompt, but its evidence is checked against all of it', () async {
      final late = 'And finally the student says that a patent owner can sue anyone who sells the invention without asking.';
      final answer = '${'Filler words about a patent and its owner go here. ' * 40}$late';
      final rt = _Runtime([
        _judged([('yes', 'a patent owner can sue anyone who sells the invention without asking'), ('no', '')]),
      ]);
      final j = await _engine(rt).judgeExplanation(concepts: const [_c1, _c2], answer: answer, slideText: _slides);
      expect(rt.prompts.single.length, lessThan(5200));
      expect(j.concepts.first.verdict, Verdict.yes);
    });
  });

  test('an engine that does not support Teach-Back gives no ideas and cannot judge', () async {
    final e = _Plain();
    expect(await e.topicConcepts('slides'), isEmpty);
    await expectLater(e.judgeExplanation(concepts: const ['x'], answer: 'a', slideText: 's'), throwsA(isA<GenerationFailed>()));
  });
}

class _Plain extends AiEngine {
  @override
  Future<GeneratedSet> generate(String notes, {String? verifyIn, void Function(double fraction)? onProgress}) => throw UnimplementedError();
  @override
  Future<LessonSummary> summarize(String notes, {void Function(double fraction)? onProgress}) => throw UnimplementedError();
  @override
  Future<String> ask(String notes, List<ChatTurn> history) => throw UnimplementedError();
  @override
  Future<void> dispose() async {}
}
