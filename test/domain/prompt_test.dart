import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/prompt.dart';

void main() {
  _vague();
  test('empty or whitespace text gives no chunks', () {
    expect(chunkText('', 100), isEmpty);
    expect(chunkText('  \n\n  ', 100), isEmpty);
  });

  test('short text is one chunk', () {
    expect(chunkText('Cells are small.', 100), ['Cells are small.']);
  });

  test('chunks respect max size and lose no words', () {
    final text = List.generate(40, (i) => 'Sentence number $i is here.').join(' ');
    final chunks = chunkText(text, 120);
    expect(chunks.length, greaterThan(1));
    expect(chunks.every((c) => c.length <= 120), isTrue);
    final rejoined = chunks.join(' ').split(RegExp(r'\s+'));
    expect(rejoined, text.split(RegExp(r'\s+')));
  });

  test('a single unbroken string longer than max is hard-cut', () {
    final chunks = chunkText('a' * 250, 100);
    expect(chunks.map((c) => c.length), [100, 100, 50]);
  });

  test('facts prompt has the notes and the count', () {
    final p = buildFactsPrompt('Mitosis notes', facts: 4);
    expect(p, contains('Mitosis notes'));
    expect(p, contains('up to 4 key facts'));
    expect(p, contains('"facts"'));
  });

  test('qa prompt numbers the facts', () {
    final p = buildQaPrompt(['A is B.', 'C is D.']);
    expect(p, contains('1. A is B.'));
    expect(p, contains('2. C is D.'));
  });

  test('answerInNotes', () {
    const src = 'Rizal was born in Calamba, Laguna in 1861.';
    expect(answerInNotes('1861', src), isTrue);
    expect(answerInNotes('Calamba, Laguna', src), isTrue);
    expect(answerInNotes('Paris', src), isFalse);
  });

  test('bestFact picks the fact sharing the most words', () {
    expect(
        bestFact(['Water boils at sea level.', 'Rizal was born in Calamba.'],
            'Where was Rizal born? Calamba'),
        'Rizal was born in Calamba.');
  });

  test('pickDistractors: distinct, never the answer, never a different kind', () {
    final d = pickDistractors('1861', ['1861', '1896', 'Calamba', '1887', '1861'], Random(1));
    expect(d, hasLength(3));
    expect(d, isNot(contains('1861')));
    expect(d, isNot(contains('Calamba')));
    expect(d.every((x) => RegExp(r'^\d{4}$').hasMatch(x)), isTrue);
    expect(pickDistractors('x', ['x', 'x'], Random(1)), isEmpty);
    expect(pickDistractors('Louis XVI', ['1789', 'ATP'], Random(1)), ['ATP']);
  });

  test('pickDistractors: the model\'s own wrong answers come first', () {
    final d = pickDistractors('Louis XVI', ['ATP', 'Mitochondria'], Random(1),
        preferred: ['Robespierre', 'louis xvi', 'Danton', 'Marat']);
    expect(d.toSet(), {'Robespierre', 'Danton', 'Marat'});
  });

  test('pickDistractors skips choices much longer than the answer', () {
    final d = pickDistractors('1789', [], Random(1),
        preferred: ['The American Revolution started in 1776', '1790']);
    expect(d.first, '1790');
    expect(d, isNot(contains('The American Revolution started in 1776')));
  });

  test('pickDistractors never offers a choice named in the question', () {
    final d = pickDistractors('Mitochondria', ['Cellular respiration', 'Nucleus'], Random(1),
        question: 'Where does cellular respiration take place?');
    expect(d, ['Nucleus']);
  });

  test('nearbyNumbers changes the last number and keeps the rest', () {
    final years = nearbyNumbers('1789', 3, Random(1));
    expect(years, hasLength(3));
    expect(years.toSet(), hasLength(3));
    for (final y in years) {
      expect((int.parse(y) - 1789).abs(), inInclusiveRange(1, 6));
    }
    expect(nearbyNumbers('14 July 1789', 3, Random(1)).every((x) => x.startsWith('14 July 17')), isTrue);
    expect(nearbyNumbers('about 17,000 people', 3, Random(1)).every((x) => RegExp(r'^about \d{1,2},000 people$').hasMatch(x)), isTrue);
    expect(nearbyNumbers('Calamba', 3, Random(1)), isEmpty);
    // digits inside a formula or name are not numbers to move
    expect(nearbyNumbers('Carbon dioxide (CO2) and water (H2O)', 3, Random(1)), isEmpty);
  });

  test('unleak removes a leaked number from the question', () {
    expect(unleak('What year did France declare a republic in 1792?', '1792'),
        'What year did France declare a republic?');
    expect(unleak('On which day in 1789 did a crowd storm the Bastille?', '14 July 1789'),
        'On which day did a crowd storm the Bastille?');
    expect(unleak('In 1861, where was Rizal born?', 'Calamba, 1861'), 'Where was Rizal born?');
  });

  test('unleak drops questions that give the answer away', () {
    expect(
        unleak('What event caused the financial crisis partly due to the American Revolution?',
            'The cost of supporting the American Revolution'),
        isNull);
    expect(unleak('What does ATP stand for?', 'ATP'), isNull);
    expect(unleak('Which prison, the Bastille, was stormed?', 'The Bastille'), isNull);
    expect(unleak('In 1792?', '1792'), isNull);
    expect(
        unleak('What happened to Robespierre after the Thermidorian Reaction?',
            'Robespierre was executed in July 1794 after the Thermidorian Reaction.'),
        isNull);
  });

  test('unleak keeps fair questions as they are', () {
    expect(unleak('Where does cellular respiration take place?', 'Mitochondria'),
        'Where does cellular respiration take place?');
    expect(unleak('Who was executed by guillotine on January 17, 1793?', 'Louis XVI'),
        'Who was executed by guillotine on January 17, 1793?');
    // units in the question are fine when the answer is a number
    expect(unleak('At what temperature in degrees Celsius does water boil?', '100 degrees Celsius'),
        'At what temperature in degrees Celsius does water boil?');
  });

  test('qa prompt forbids putting the answer in the question', () {
    expect(buildQaPrompt(['A is B.']), contains('must not contain the answer'));
  });

  test('wrong-answers prompt lists each question with its answer', () {
    final p = buildWrongPrompt([const QaItem('Who wrote Noli?', 'Rizal')]);
    expect(p, contains('1. Who wrote Noli? Correct answer: Rizal'));
    expect(p, contains('"wrong"'));
  });

  test('lines repeated 3+ times (slide footers) are dropped', () {
    const t = 'Life and Works\nFact A\nLife and Works\nFact B\nLife and Works';
    expect(dropRepeatedLines(t), 'Fact A\nFact B');
  });

  test('footers that differ only by page number are dropped too', () {
    const t = 'Presentation_ID © 2008 Cisco Systems, Inc. All rights reserved. Cisco Confidential 12\r\n'
        'Hacktivists protest against political ideas.\r\n'
        'Presentation_ID © 2008 Cisco Systems, Inc. All rights reserved. Cisco Confidential 13\r\n'
        'NIST created a workforce framework.\r\n'
        'Presentation_ID © 2008 Cisco Systems, Inc. All rights reserved. Cisco Confidential 14';
    expect(dropRepeatedLines(t),
        'Hacktivists protest against political ideas.\r\nNIST created a workforce framework.\r');
  });

  test('isGrounded', () {
    const src = 'Rizal was born in Calamba, Laguna in 1861.';
    expect(isGrounded('Where was Rizal born? Calamba', src), isTrue);
    expect(isGrounded('Which rock is common on Zorblax?', src), isFalse);
    expect(isGrounded('Why? a', src), isTrue); // nothing long enough to judge
  });

  test('pickContext keeps the chunks that match the question', () {
    final notes = [
      for (var i = 0; i < 30; i++) 'Filler paragraph number $i about nothing at all.',
      'Photosynthesis converts sunlight into chemical energy in chloroplasts.',
    ].join('\n');
    final ctx = pickContext(notes, 'how does photosynthesis work', maxChars: 300, chunkChars: 100);
    expect(ctx.length, lessThanOrEqualTo(300));
    expect(ctx, contains('Photosynthesis'));
  });
}

void _vague() {
  test('vague topic labels are detected', () {
    expect(isVague('The importance of freedom and nationalism'), isTrue);
    expect(isVague('The reasons behind freedom'), isTrue);
    expect(isVague('Why was Rizal executed?'), isFalse);
  });
}
