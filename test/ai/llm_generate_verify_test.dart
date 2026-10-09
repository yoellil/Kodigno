import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/llm_ai_engine.dart';
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
  chunkChars: 400,
  questionsPerChunk: 3,
  cardsPerChunk: 3,
);

// What a summary might say, with one detail that is wrong.
const _summaryText = 'Rizal was born in Calamba in 1861. Rizal wrote Noli Me Tangere in Manila in 1887.';

// What the slides say.
const _original = 'Rizal was born in Calamba in 1861. He wrote the novel Noli Me Tangere in Berlin in 1887.\n'
    'Trade secret - information used in business that is generally unknown to the public.';

String _qa(List<List<String>> p) =>
    '{"items":[${p.map((x) => '{"question":"${x[0]}","answer":"${x[1]}"}').join(',')}]}';
String _wrong(List<List<String>> w) =>
    '{"items":[${w.map((x) => '{"wrong":[${x.map((y) => '"$y"').join(',')}]}').join(',')}]}';


final _twoQa = _qa([
  ['In which town was Rizal born?', 'Calamba'],
  ['In which city did Rizal write Noli Me Tangere?', 'Manila'],
]);
final _wrongs = _wrong([
  ['Manila', 'Cebu', 'Davao'],
  ['Madrid', 'Paris', 'London'],
]);

void main() {
  test('cards made from a summary keep only answers that the original slides also state', () async {
    // The fact whose answer was refused is asked about again, up to three times in all.
    final rt = FakeLlmRuntime([_twoQa, _twoQa, _twoQa, _wrong([['Cebu', 'Davao', 'Iloilo']])]);
    final set = await LlmAiEngine(rt, _tier, random: Random(1)).generate(_summaryText, verifyIn: _original);

    final fronts = set.flashcards.map((c) => c.front).toList();
    expect(fronts, contains('In which town was Rizal born?'));
    expect(fronts, isNot(contains('In which city did Rizal write Noli Me Tangere?'))); // "Manila" is not in the slides
    expect(set.flashcards.map((c) => c.back), isNot(contains('Manila')));
  });

  test('without the original, the same answer is kept', () async {
    final rt = FakeLlmRuntime([_twoQa, _wrongs]);
    final set = await LlmAiEngine(rt, _tier, random: Random(1)).generate(_summaryText);
    expect(set.flashcards.map((c) => c.back), containsAll(['Calamba', 'Manila']));
  });

  test('"Term - definition" lines of the original become cards even if the summary left them out', () async {
    final rt = FakeLlmRuntime([_twoQa, _twoQa, _twoQa, _wrong([['Cebu', 'Davao', 'Iloilo']])]);
    final set = await LlmAiEngine(rt, _tier, random: Random(1)).generate(_summaryText, verifyIn: _original);
    expect(set.flashcards.map((c) => c.front), contains('Trade secret'));
    expect(set.flashcards.firstWhere((c) => c.front == 'Trade secret').back,
        'Information used in business that is generally unknown to the public.');
  });
}
