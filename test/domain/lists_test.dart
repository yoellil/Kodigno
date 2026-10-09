import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/definitions.dart';
import 'package:kodigno/domain/lists.dart';

void main() {
  test('expectedCount reads how many things a question asks for', () {
    expect(expectedCount('What are the three key principles that contribute to society?'), 3);
    expect(expectedCount('List the 4 phases of the cycle.'), 4);
    expect(expectedCount('Name two kinds of malware.'), 2);
    expect(expectedCount('Where was Rizal born?'), isNull);
    expect(expectedCount('In which of the three cities was he born?'), isNull);
    expect(expectedCount('What are the effects of the 1990s boom?'), isNull);
    expect(expectedCount('What is the name of the first code adopted by the IEEE after a 6-year effort?'), isNull);
    expect(expectedCount('What are the results of the 6-year effort?'), isNull);
  });

  test('numberedItems splits a run-in list and needs it to count up from 1', () {
    expect(numberedItems('1. Contribute to society 2. Avoid harm, be honest. 3. Respect privacy;'),
        ['Contribute to society', 'Avoid harm, be honest', 'Respect privacy']);
    expect(numberedItems('Contribute to society'), isNull);
    expect(numberedItems('2. B 3. C'), isNull);
    expect(numberedItems('Version 2. Then it ran'), isNull);
  });

  group('listFromNotes', () {
    test('finds a bulleted or numbered list of exactly n items', () {
      const notes = 'ACM principles:\n1. Contribute to society and to\nhuman well-being\n2. Avoid harm\n3. Be honest and trustworthy\nMore text.';
      expect(listFromNotes(notes, 3, 'principles society'),
          ['Contribute to society and to human well-being', 'Avoid harm', 'Be honest and trustworthy']);
      expect(listFromNotes(notes, 4, ''), isNull);
    });

    test('also reads a numbered list run together in one line', () {
      expect(listFromNotes('Principles: 1. Be fair 2. Be kind 3. Be honest', 3, ''),
          ['Be fair', 'Be kind', 'Be honest']);
    });

    test('picks the list that fits the question when there are several', () {
      const notes = '- apples\n- pears\n- plums\n\n- Contribute to society\n- Avoid harm\n- Be honest';
      expect(listFromNotes(notes, 3, 'which principles contribute to society'),
          ['Contribute to society', 'Avoid harm', 'Be honest']);
    });
  });

  test('formatList numbers the items one per line and keeps each brief', () {
    expect(formatList(['Contribute to society and to human well-being.', 'Avoid harm', 'Be honest']),
        '1. Contribute to society and to human well-being\n2. Avoid harm\n3. Be honest');
    final long = formatList(['Avoid harm, be honest and trustworthy, respect privacy, honor confidentiality and more']);
    expect(long.length, lessThan(80));
    expect(long, isNot(contains('\n')));
  });

  test('items from a dotted 1.1, 1.2 list are found and kept brief', () {
    const notes = 'General Ethical Principles\nA computing professional should...\n'
        '1.1 Contribute to society and to human well-being, acknowledging that all people are stakeholders\nin computing.\n'
        '1.2 Avoid harm.\n1.3 Be honest and trustworthy.\n'
        '1.5 Respect the work required to produce new ideas, inventions, creative works, and computing artifacts.\n'
        'Professional Responsibilities\n2.1 2.2 2.3 2.4 2.5\n';
    final items = listFromNotes(notes, null, 'What are the main principles of computing professionals?')!;
    expect(items, hasLength(4));
    expect(formatList(items).split('\n'), [
      '1. Contribute to society and to human well-being',
      '2. Avoid harm',
      '3. Be honest and trustworthy',
      '4. Respect the work required to produce new ideas',
    ]);
  });

  test('"What are the main principles...?" asks for a list even without a number', () {
    expect(asksForList('What are the main principles of computing professionals?'), isTrue);
    expect(asksForList('What are the three key principles?'), isTrue);
    expect(asksForList('What are cookies?'), isFalse);
    expect(asksForList('Where was Rizal born?'), isFalse);
  });
}
