import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
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
  chunkChars: 200,
  questionsPerChunk: 3,
  cardsPerChunk: 3,
);

const _notes = 'Rizal was born in Calamba in 1861. '
    'He wrote the novel Noli Me Tangere in Berlin in 1887. '
    'He was executed at Bagumbayan in 1896.';

String _facts(List<String> f) => '{"facts":[${f.map((x) => '"$x"').join(',')}]}';
String _qa(List<List<String>> p) =>
    '{"items":[${p.map((x) => '{"question":"${x[0]}","answer":"${x[1]}"}').join(',')}]}';

final _goodFacts = _facts([
  'Rizal was born in Calamba in 1861.',
  'Rizal wrote Noli Me Tangere in Berlin in 1887.',
  'Rizal was executed at Bagumbayan in 1896.',
]);
final _goodQa = _qa([
  ['In which town was Rizal born?', 'Calamba'],
  ['In which city did Rizal write Noli Me Tangere?', 'Berlin'],
  ['Where was Rizal executed?', 'Bagumbayan'],
]);

String _wrong(List<List<String>> w) =>
    '{"items":[${w.map((x) => '{"wrong":[${x.map((y) => '"$y"').join(',')}]}').join(',')}]}';

final _goodWrong = _wrong([
  ['Manila', 'Cebu', 'Davao'],
  ['Madrid', 'Paris', 'London'],
  ['Fort Santiago', 'Intramuros', 'Cavite'],
]);

/// One section that works first time: facts, questions, wrong answers.
final _ok = [_goodFacts, _goodQa, _goodWrong];

LlmAiEngine _engine(FakeLlmRuntime rt, {int maxChunks = 12, int seed = 1}) =>
    LlmAiEngine(rt, _tier, maxChunks: maxChunks, random: Random(seed));

void main() {
  test('facts, then questions, then wrong answers of the same kind for the quiz', () async {
    final rt = FakeLlmRuntime([..._ok]);
    final set = await _engine(rt).generate(_notes);
    expect(set.flashcards.map((c) => c.back), ['Calamba', 'Berlin', 'Bagumbayan']);
    expect(set.flashcards.first.front, 'In which town was Rizal born?');
    final q = set.questions.first;
    expect(q.choices.toSet(), {'Calamba', 'Manila', 'Cebu', 'Davao'});
    expect(q.choices[q.answerIndex], 'Calamba');
    expect(q.explanation, contains('Calamba'));
    expect(rt.prompts, hasLength(3));
    expect(rt.prompts.last, contains('Correct answer: Calamba'));
  });

  test('term - definition lines become cards and quiz questions, even if the model fails', () async {
    const notes = '▪ Hacktivists - Grey hat hackers who rally and protest against political ideas.\n'
        '▪ Script Kiddies - Teenagers or hobbyists mostly limited to pranks and vandalism.\n'
        '▪ Vulnerability Brokers - Grey hat hackers who report exploits to vendors for prizes.\n'
        '▪ Cyber Criminals - Black hat hackers working for large cybercrime organizations.';
    final rt = FakeLlmRuntime(['x', 'x', 'x']); // facts fail 3 times
    final set = await _engine(rt, maxChunks: 1).generate(notes);
    expect(set.flashcards.map((c) => c.front),
        ['Hacktivists', 'Script Kiddies', 'Vulnerability Brokers', 'Cyber Criminals']);
    expect(set.flashcards.first.back, 'Grey hat hackers who rally and protest against political ideas.');
    final q = set.questions.first;
    expect(q.prompt, contains('Grey hat hackers who rally'));
    expect(q.choices[q.answerIndex], 'Hacktivists');
    expect(q.choices.toSet(),
        {'Hacktivists', 'Script Kiddies', 'Vulnerability Brokers', 'Cyber Criminals'});
  });

  test('without usable wrong answers the quiz falls back to other answers', () async {
    final rt = FakeLlmRuntime([_goodFacts, _goodQa, 'garbage']);
    final q = (await _engine(rt).generate(_notes)).questions.first;
    expect(q.choices, hasLength(3)); // only 3 distinct answers in the whole set
    expect(q.choices[q.answerIndex], 'Calamba');
    expect(rt.prompts, hasLength(3)); // wrong answers are asked for once only
  });

  test('fallback choices: people only for "who" questions, never for the rest', () async {
    final qa = _qa([
      ['In which town was Rizal born?', 'Calamba'],
      ['Who wrote Noli Me Tangere in Berlin?', 'Rizal'],
      ['Where was Rizal executed?', 'Bagumbayan'],
    ]);
    final rt = FakeLlmRuntime([_goodFacts, qa, 'garbage']);
    final set = await _engine(rt).generate(_notes);
    expect(set.flashcards, hasLength(3));
    for (final q in set.questions) {
      expect(q.choices, isNot(contains('Rizal')));
    }
  });

  test('a question that gives its answer away is fixed or dropped', () async {
    final qa = _qa([
      ['In what year was Rizal born in Calamba in 1861?', '1861'],
      ['Where was Rizal executed at Bagumbayan?', 'Bagumbayan'],
      ['In which city did Rizal write Noli Me Tangere?', 'Berlin'],
    ]);
    final rt = FakeLlmRuntime([_goodFacts, qa, 'x', 'x', 'x']);
    final set = await _engine(rt).generate(_notes);
    expect(set.flashcards.map((c) => c.front), [
      'In what year was Rizal born in Calamba?',
      'In which city did Rizal write Noli Me Tangere?',
    ]);
  });

  test('facts left without a usable question are asked again, alone', () async {
    final first = _qa([
      ['In which town was Rizal born?', 'Calamba'],
      ['In which city did Rizal write Noli Me Tangere?', 'Berlin'],
    ]);
    final again = _qa([
      ['Where was Rizal executed?', 'Bagumbayan'],
    ]);
    final rt = FakeLlmRuntime([_goodFacts, first, again, _goodWrong]);
    final set = await _engine(rt).generate(_notes);
    expect(set.flashcards.map((c) => c.back), ['Calamba', 'Berlin', 'Bagumbayan']);
    expect(rt.prompts[2], contains('1. Rizal was executed at Bagumbayan in 1896.'));
    expect(rt.prompts[2], isNot(contains('Calamba')));
  });

  test('answers not stated in the notes are dropped', () async {
    final qa = _qa([
      ['In which town was Rizal born?', 'Calamba'],
      ['Where was Rizal executed?', 'Paris'], // made up
    ]);
    final set = await _engine(FakeLlmRuntime([_goodFacts, qa, 'x', 'x', 'x'])).generate(_notes);
    expect(set.flashcards.map((c) => c.back), ['Calamba']);
  });

  test('vague topic labels and placeholders are dropped', () async {
    final qa = _qa([
      ['The importance of Rizal in the Philippines', 'Calamba'],
      ['<question>', '<answer>'],
      ['In which town was Rizal born?', 'Calamba'],
    ]);
    final set = await _engine(FakeLlmRuntime([_goodFacts, qa, 'x', 'x', 'x'])).generate(_notes);
    expect(set.flashcards.map((c) => c.front), ['In which town was Rizal born?']);
  });

  test('facts that are not in the notes are dropped; none left means retry', () async {
    final madeUp = _facts(['Quibs graze on moss on the planet Zorblax.']);
    final rt = FakeLlmRuntime([madeUp, ..._ok]);
    final set = await _engine(rt).generate(_notes);
    expect(set.flashcards, hasLength(3));
    expect(rt.prompts, hasLength(4));
  });

  test('retries malformed output, then fails after 3 bad attempts', () async {
    final ok = await _engine(FakeLlmRuntime(['garbage', _goodFacts, 'x', _goodQa, _goodWrong]))
        .generate(_notes);
    expect(ok.flashcards, hasLength(3));
    await expectLater(
      _engine(FakeLlmRuntime(['x', 'y', 'z'])).generate(_notes),
      throwsA(isA<GenerationFailed>()),
    );
  });

  test('empty notes throw GenerationFailed without calling the model', () async {
    final rt = FakeLlmRuntime([]);
    await expectLater(_engine(rt).generate('   '), throwsA(isA<GenerationFailed>()));
    expect(rt.prompts, isEmpty);
  });

  test('a failed section is skipped if another succeeds', () async {
    final notes = '${'a' * 150}\n$_notes'; // 2 sections at chunkChars 200
    final rt = FakeLlmRuntime(['x', 'y', 'z', ..._ok]);
    final set = await _engine(rt).generate(notes);
    expect(set.flashcards, hasLength(3));
  });

  test('duplicate questions across sections are removed', () async {
    final notes = '$_notes\n${'b' * 150}\n$_notes';
    final rt = FakeLlmRuntime([..._ok, 'x', 'x', 'x', ..._ok]);
    final set = await _engine(rt).generate(notes);
    expect(set.flashcards, hasLength(3));
  });

  test('section count is capped and spread over the whole document', () async {
    // each section's text differs (lines differing only by a number are footers)
    final notes = List.generate(10, (i) => '${String.fromCharCode(65 + i) * 150}$i').join('\n');
    final rt = FakeLlmRuntime(List.generate(12, (_) => 'x'));
    try {
      await _engine(rt, maxChunks: 2).generate(notes);
    } on GenerationFailed {
      // the fake only returns junk; only the prompts matter here
    }
    expect(rt.prompts, hasLength(6)); // 2 sections x 3 attempts
    expect(rt.prompts.first, contains('0'));
    expect(rt.prompts.last, contains('5'));
  });

  test('reports progress after each section, ending at 1.0', () async {
    final notes = '$_notes\n${'b' * 150}';
    final rt = FakeLlmRuntime([..._ok, 'x', 'x', 'x']);
    final seen = <double>[];
    await _engine(rt).generate(notes, onProgress: seen.add);
    expect(seen, [0.5, 1.0]);
  });

  test('ModelUnavailableException propagates without retry', () async {
    final rt = FakeLlmRuntime([ModelUnavailableException('oom'), _goodFacts]);
    await expectLater(
      _engine(rt).generate(_notes),
      throwsA(isA<ModelUnavailableException>()),
    );
    expect(rt.prompts, hasLength(1));
  });

  test('answer order is shuffled but the correct answer follows', () async {
    final orders = <String>{};
    for (var seed = 0; seed < 20; seed++) {
      final set = await _engine(FakeLlmRuntime([..._ok]), seed: seed)
          .generate(_notes);
      final q = set.questions.first;
      expect(q.choices[q.answerIndex], 'Calamba');
      orders.add(q.choices.join());
    }
    expect(orders.length, greaterThan(1));
  });

  test('ask() answers from the lesson and sends recent history', () async {
    final rt = FakeLlmRuntime(['  Because of the cell.  ']);
    final reply = await _engine(rt).ask(
      'Mitochondria produce energy.',
      const [ChatTurn('user', 'Why?')],
    );
    expect(reply, 'Because of the cell.');
    expect(rt.prompts.single, 'Why?');
  });
}
