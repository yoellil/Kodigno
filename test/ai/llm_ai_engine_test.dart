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
        '▪ Cyber Criminals - Black hat hackers working for large cybercrime organizations.\n'
        '▪ State Hackers - Employees of governments who attack other countries for political aims.';
    final rt = FakeLlmRuntime(['x', 'x', 'x']); // facts fail 3 times
    final set = await _engine(rt, maxChunks: 1).generate(notes);
    expect(set.flashcards.map((c) => c.front),
        ['Hacktivists', 'Script Kiddies', 'Vulnerability Brokers', 'Cyber Criminals', 'State Hackers']);
    expect(set.flashcards.first.back, 'Grey hat hackers who rally and protest against political ideas.');
    final q = set.questions.first;
    expect(q.prompt, contains('Grey hat hackers who rally'));
    expect(q.choices[q.answerIndex], 'Hacktivists');
    expect(q.choices.toSet().difference({'Hacktivists', 'Script Kiddies', 'Vulnerability Brokers', 'Cyber Criminals', 'State Hackers'}), isEmpty);
    expect(q.choices.length, greaterThanOrEqualTo(3));
  });

  test('with fewer than five real definitions there is no "which term" question (too little to choose from)', () async {
    const notes = '▪ Hacktivists - Grey hat hackers who rally and protest against political ideas.\n'
        '▪ Script Kiddies - Teenagers or hobbyists mostly limited to pranks and vandalism.';
    final set = await _engine(FakeLlmRuntime(['x', 'x', 'x']), maxChunks: 1).generate(notes);
    expect(set.flashcards, hasLength(2));
    expect(set.questions, isEmpty);
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

  test('reference lists and citations in the notes are never used', () async {
    const notes = 'Rizal was born in Calamba in 1861. '
        'He wrote the novel Noli Me Tangere in Berlin in 1887. '
        'He was executed at Bagumbayan in 1896.\n'
        'References\n'
        'Guerrero, L. (1963). The first Filipino. Journal of History, 4(2), 10-20.\n'
        'Retrieved from https://example.com/rizal';
    final rt = FakeLlmRuntime([..._ok]);
    await _engine(rt).generate(notes);
    expect(rt.prompts.first, isNot(contains('Guerrero')));
    expect(rt.prompts.first, isNot(contains('example.com')));
  });

  test('citation-like facts and answers from the model are dropped', () async {
    final facts = _facts([
      'Rizal was born in Calamba in 1861.',
      'Guerrero, L. (1963). The first Filipino. Journal of History, 4(2), 10-20.',
    ]);
    final qa = _qa([
      ['In which town was Rizal born?', 'Calamba'],
      ['Which journal published Guerrero in 1963?', 'Journal of History'],
    ]);
    const notes = 'Rizal was born in Calamba in 1861. Guerrero wrote about Rizal in 1963 in Journal of History.';
    final set = await _engine(FakeLlmRuntime([facts, qa, _goodWrong])).generate(notes);
    expect(set.flashcards.map((c) => c.front), ['In which town was Rizal born?']);
  });

  test('quiz choices share one style, so the right one does not stand out', () async {
    final qa = _qa([
      ['In which town was Rizal born?', 'calamba.'],
      ['In which city did Rizal write Noli Me Tangere?', 'Berlin'],
      ['Where was Rizal executed?', 'Bagumbayan'],
    ]);
    final wrong = _wrong([
      ["'Manila'", 'cebu', 'Davao.'],
      ['Madrid', 'Paris', 'London'],
      ['Fort Santiago', 'Intramuros', 'Cavite'],
    ]);
    final set = await _engine(FakeLlmRuntime([_goodFacts, qa, wrong])).generate(_notes);
    final q = set.questions.first;
    expect(q.choices.toSet(), {'Calamba', 'Manila', 'Cebu', 'Davao'});
    expect(q.choices[q.answerIndex], 'Calamba');
  });

  test('a long correct answer is not paired with one-word choices', () async {
    const notes = 'Photosynthesis lets plants turn sunlight, water and carbon dioxide into sugar and oxygen.';
    final facts = _facts(['Photosynthesis lets plants turn sunlight, water and carbon dioxide into sugar and oxygen.']);
    final qa = _qa([
      ['What does photosynthesis let plants do?', 'Turn sunlight water and carbon dioxide into sugar']
    ]);
    final wrong = _wrong([
      ['Rain', 'Wind', 'Soil']
    ]);
    final set = await _engine(FakeLlmRuntime([facts, qa, wrong])).generate(notes);
    expect(set.flashcards, hasLength(1));
    expect(set.questions, isEmpty); // no believable choices: better no question than a giveaway
  });

  test('a question asking for three things gets all three, numbered, one per line', () async {
    const notes = 'The ACM code has three principles:\n1. Contribute to society and to human well-being\n'
        '2. Avoid harm\n3. Be honest and trustworthy';
    final facts = _facts(['The ACM code has three principles: contribute to society, avoid harm, be honest.']);
    // the model gives only two, run together on one line
    final qa = _qa([
      ['What are the three key principles that contribute to society?', '1. Contribute to society and to human well-being 2. Avoid harm']
    ]);
    final set = await _engine(FakeLlmRuntime([facts, qa]), maxChunks: 1).generate(notes);
    expect(set.flashcards.single.back,
        '1. Contribute to society and to human well-being\n2. Avoid harm\n3. Be honest and trustworthy');
    expect(set.questions, isEmpty); // a list is for the card, not multiple choice
  });

  test('a list question whose items cannot be found is dropped, not shown incomplete', () async {
    const notes = 'The ACM code has three principles: contribute to society, avoid harm and be honest and trustworthy.';
    final facts = _facts(['The ACM code has three principles: contribute to society, avoid harm and be honest and trustworthy.']);
    final qa = _qa([
      ['What are the three key principles of the ACM code?', '1. Contribute to society 2. Avoid harm']
    ]);
    final rt = FakeLlmRuntime([facts, qa, qa, qa]);
    // the only card was dropped (no complete list in the notes), so nothing is left to study from
    await expectLater(_engine(rt, maxChunks: 1).generate(notes), throwsA(isA<GenerationFailed>()));
  });

  test('"What are the main principles" with a vague one-sentence answer gets the notes\' full list', () async {
    const notes = 'General Ethical Principles\nA computing professional should...\n'
        '1.1 Contribute to society and to human well-being.\n1.2 Avoid harm.\n1.3 Be honest and trustworthy.\n1.4 Respect privacy.\n';
    final facts = _facts(['A computing professional should contribute to society, avoid harm, be honest and respect privacy.']);
    final qa = _qa([
      ['What are the main principles of computing professionals?', 'The rules for computing professionals include guidelines.']
    ]);
    final set = await _engine(FakeLlmRuntime([facts, qa]), maxChunks: 1).generate(notes);
    // the list is one card under its own title; the model's vague card is not kept beside it
    expect(set.flashcards.where((c) => c.front.contains('main principles')), isEmpty);
    final card = set.flashcards.firstWhere((c) => c.front == 'What are the General Ethical Principles?');
    expect(card.back,
        '1. Contribute to society and to human well-being\n2. Avoid harm\n3. Be honest and trustworthy\n4. Respect privacy');
  });

  test('a list question with a vague answer and no list in the notes is dropped', () async {
    const notes = 'Computing professionals follow rules, and the rules include guidelines that explain how to apply them well.';
    final facts = _facts(['Computing professionals follow rules, and the rules include guidelines that explain them.']);
    final qa = _qa([
      ['What are the main principles of computing professionals?', 'The rules for computing professionals include guidelines.']
    ]);
    // the vague card is dropped, and with nothing else to study from, generation says so
    expect(_engine(FakeLlmRuntime([facts, qa, qa, qa]), maxChunks: 1).generate(notes),
        throwsA(isA<GenerationFailed>()));
  });

  test('a question that mixes a date from one fact with a rule from another is dropped', () async {
    const notes = '1974 - Revised after IEEE added Professional Activities to its Constitution. '
        'The IEEE Code of Ethics comprises 10 principles, adopted in 1990.';
    final facts = _facts([
      'The IEEE revised its Code after adding Professional Activities to its Constitution in 1974.',
      'The IEEE Code of Ethics comprises 10 principles, adopted in 1990.',
    ]);
    final qa = _qa([
      ['What is the first principle of the revised IEEE Constitution?', 'The first principle states that all members of the IEEE are professional.'],
      ['How many principles does the IEEE Code of Ethics comprise?', '10 principles'],
    ]);
    final set = await _engine(FakeLlmRuntime([facts, qa, qa, qa, 'x']), maxChunks: 1).generate(notes);
    final fronts = set.flashcards.map((c) => c.front).toList();
    expect(fronts.any((f) => f.contains('first principle')), isFalse);
    expect(fronts, contains('How many principles does the IEEE Code of Ethics comprise?'));
  });

  test('titled lists give "which belongs under" questions with points from other lists as wrong choices', () async {
    const notes = 'General Ethical Principles\n- Contribute to society and human well-being\n- Avoid harm to others\n- Be honest and trustworthy\n'
        'Professional Leadership Principles\n- Manage personnel and resources well\n- Support policies that reflect the Code\n- Create opportunities for members to grow\n'
        'Grades of Membership\n- Associate member grade\n- Senior member grade\n- Honorary member grade\n';
    final set = await _engine(FakeLlmRuntime(['x', 'x', 'x']), maxChunks: 1).generate(notes);
    expect(set.flashcards.map((c) => c.front),
        containsAll([
          'What are the General Ethical Principles?',
          'What are the Professional Leadership Principles?',
          'What are the Grades of Membership?',
        ]));
    final q = set.questions.firstWhere((q) => q.prompt == 'Which of these belongs under "General Ethical Principles"?');
    const own = ['Contribute to society and human well-being', 'Avoid harm to others', 'Be honest and trustworthy'];
    expect(own, contains(q.choices[q.answerIndex]));
    // exactly one choice is from the asked list
    expect(q.choices.where(own.contains), hasLength(1));
    expect(q.choices.length, greaterThanOrEqualTo(3));
  });

  group('reading the answer back', () {
    final facts = _facts(['Rizal was born in Calamba in 1861.']);
    final qa = _qa([
      ['In which town was Rizal born?', 'Calamba']
    ]);
    LlmAiEngine reading(FakeLlmRuntime rt, {Duration budget = const Duration(minutes: 3)}) =>
        LlmAiEngine(rt, _tier, random: Random(1), readBack: true, readBackBudget: budget);

    test('a card is kept when the model reads the same answer out of the notes', () async {
      final rt = FakeLlmRuntime([facts, qa, '{"answer":"Calamba"}', 'x']);
      final set = await reading(rt).generate(_notes);
      expect(set.flashcards.where((c) => c.back == 'Calamba'), hasLength(1));
      expect(rt.prompts.where((p) => p.contains('PASSAGE:')), hasLength(1));
    });

    test('a card is dropped when the model reads something else, nothing, or garbage', () async {
      for (final reply in ['{"answer":"Berlin"}', '{"answer":""}', 'garbage']) {
        final rt = FakeLlmRuntime([facts, qa, reply, qa, reply, qa, reply, 'x']);
        await expectLater(reading(rt).generate(_notes), throwsA(isA<GenerationFailed>()), reason: reply);
      }
    });

    test('an answer it invents from nowhere does not count', () async {
      final rt = FakeLlmRuntime([facts, qa, '{"answer":"Intramuros"}', qa, '{"answer":"Intramuros"}', qa, '{"answer":"Intramuros"}', 'x']);
      await expectLater(reading(rt).generate(_notes), throwsA(isA<GenerationFailed>()));
    });

    test('with no time left the cheap checks decide and the model is not asked', () async {
      final rt = FakeLlmRuntime([facts, qa, 'x']);
      final set = await reading(rt, budget: Duration.zero).generate(_notes);
      expect(set.flashcards.where((c) => c.back == 'Calamba'), hasLength(1));
      expect(rt.prompts.where((p) => p.contains('PASSAGE:')), isEmpty);
    });

    test('by default nothing is asked', () async {
      final rt = FakeLlmRuntime([facts, qa, 'x']);
      await _engine(rt).generate(_notes);
      expect(rt.prompts.where((p) => p.contains('PASSAGE:')), isEmpty);
    });
  });
}
