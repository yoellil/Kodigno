import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/ai/llm_ai_engine.dart';
import 'package:kodigno/domain/prompt.dart';
import 'package:kodigno/models/tier.dart';

import '../helpers/fake_llm_runtime.dart';

const _tier = Tier(
  id: 'low',
  label: 'Basic quality',
  model: 'm',
  url: 'u',
  sha256: 's',
  maxRamMb: 3500,
  sizeMb: 400,
  chunkChars: 50,
  questionsPerChunk: 1,
  cardsPerChunk: 1,
);

String _json(String q) =>
    '{"questions":[{"prompt":"$q","choices":["a","b"],"answer_index":0}],'
    '"flashcards":[{"front":"$q f","back":"b"}]}';

void main() {
  test('single chunk, valid output', () async {
    final rt = FakeLlmRuntime([_json('Q1')]);
    final set = await LlmAiEngine(rt, _tier).generate('short notes');
    expect(set.questions.single.prompt, 'Q1');
  });

  test('retries malformed output then succeeds (3 attempts total)', () async {
    final rt = FakeLlmRuntime(['garbage', 'still garbage', _json('Q1')]);
    final set = await LlmAiEngine(rt, _tier).generate('short notes');
    expect(set.questions, hasLength(1));
    expect(rt.prompts, hasLength(3));
  });

  test('throws GenerationFailed after 3 bad attempts', () async {
    final rt = FakeLlmRuntime(['x', 'y', 'z']);
    expect(
      LlmAiEngine(rt, _tier).generate('short notes'),
      throwsA(isA<GenerationFailed>()),
    );
  });

  test(
    'empty notes throws GenerationFailed without calling the model',
    () async {
      final rt = FakeLlmRuntime([]);
      await expectLater(
        LlmAiEngine(rt, _tier).generate('   '),
        throwsA(isA<GenerationFailed>()),
      );
      expect(rt.prompts, isEmpty);
    },
  );

  test('a failed chunk is skipped if another chunk succeeds', () async {
    final notes = '${'a' * 45}\n${'b' * 45}'; // 2 chunks at chunkChars 50
    final rt = FakeLlmRuntime(['x', 'y', 'z', _json('Q2')]);
    final set = await LlmAiEngine(rt, _tier).generate(notes);
    expect(set.questions.single.prompt, 'Q2');
  });

  test(
    'duplicate questions across chunks are removed (case-insensitive)',
    () async {
      final notes = '${'a' * 45}\n${'b' * 45}';
      final rt = FakeLlmRuntime([_json('Same?'), _json('same?')]);
      final set = await LlmAiEngine(rt, _tier).generate(notes);
      expect(set.questions, hasLength(1));
      expect(set.flashcards, hasLength(1));
    },
  );

  test('chunk count is capped at maxChunks', () async {
    final notes = List.generate(20, (i) => '${'x' * 45}$i').join('\n');
    final rt = FakeLlmRuntime(List.generate(20, (i) => _json('Q$i')));
    await LlmAiEngine(rt, _tier, maxChunks: 4).generate(notes);
    expect(rt.prompts, hasLength(4));
  });

  test('reports progress after each chunk, ending at 1.0', () async {
    final notes = '${'a' * 45}\n${'b' * 45}';
    final rt = FakeLlmRuntime([_json('Q1'), _json('Q2')]);
    final seen = <double>[];
    await LlmAiEngine(rt, _tier).generate(notes, onProgress: seen.add);
    expect(seen, [0.5, 1.0]);
  });

  test('ModelUnavailableException propagates without retry', () async {
    final rt = FakeLlmRuntime([ModelUnavailableException('oom'), _json('Q')]);
    await expectLater(
      LlmAiEngine(rt, _tier).generate('short notes'),
      throwsA(isA<ModelUnavailableException>()),
    );
    expect(rt.prompts, hasLength(1));
  });

  test('example items copied from the prompt are dropped', () async {
    final copied =
        '{"questions":[{"prompt":"$exampleQuestionPrompt","choices":["a","b"],"answer_index":0},'
        '{"prompt":"Real?","choices":["a","b"],"answer_index":1}],'
        '"flashcards":[{"front":"$exampleCardFront","back":"x"},{"front":"Real card","back":"y"}]}';
    final rt = FakeLlmRuntime([copied]);
    final set = await LlmAiEngine(rt, _tier).generate('short notes');
    expect(set.questions.map((q) => q.prompt), ['Real?']);
    expect(set.flashcards.map((c) => c.front), ['Real card']);
  });

  test('an answer that is only the copied example counts as a failed attempt and retries', () async {
    final onlyExample =
        '{"questions":[{"prompt":"$exampleQuestionPrompt","choices":["a","b"],"answer_index":0}],'
        '"flashcards":[]}';
    final rt = FakeLlmRuntime([onlyExample, _json('Real?')]);
    final set = await LlmAiEngine(rt, _tier).generate('short notes');
    expect(set.questions.single.prompt, 'Real?');
    expect(rt.prompts, hasLength(2));
  });
}
