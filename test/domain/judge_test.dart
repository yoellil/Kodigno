import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/judge.dart';

const _passage = 'He wrote the novel Noli Me Tangere in Berlin in 1887. He was executed at Bagumbayan in 1896.';

void main() {
  test('the prompt shows the passage and the question, not the card\'s answer', () {
    final p = buildReaderPrompt(passage: _passage, question: 'Where was he executed?');
    expect(p, allOf(contains(_passage), contains('QUESTION: Where was he executed?')));
  });

  test('what the model read is kept only if it is really in the passage', () {
    expect(parseReader('{"answer":"Bagumbayan"}', _passage), 'Bagumbayan');
    expect(parseReader('{"answer":"in Berlin in 1887"}', _passage), 'in Berlin in 1887');
    expect(parseReader('{"answer":"Intramuros"}', _passage), ''); // made up
    expect(parseReader('{"answer":""}', _passage), '');
  });

  test('reads JSON wrapped in prose and rejects anything else', () {
    expect(parseReader('Sure: {"answer":"Berlin"} ok', _passage), 'Berlin');
    expect(() => parseReader('no json', _passage), throwsFormatException);
    expect(() => parseReader('{"nope":1}', _passage), throwsFormatException);
  });

  group('answerWithin', () {
    test('the card\'s answer may be part of what the notes say', () {
      expect(answerWithin('1891', 'February 1891'), isTrue);
      expect(answerWithin('Laundering Council', 'Money Laundering Council'), isTrue);
      expect(answerWithin('Rizal', 'Rizal visited Oakland and ate supper in Sacramento.'), isTrue);
    });

    test('a title or one more word on top of what was read is fine; a long addition is not', () {
      expect(answerWithin('Dr. Miguel Morayta', 'Miguel Morayta'), isTrue);
      expect(answerWithin('Berlin, as announced in 1999 by the Ministry of Finance', 'Berlin'), isFalse);
    });

    test('a longer answer that rewords the notes counts when most of its words were read', () {
      expect(
          answerWithin('Inspire and guide the ethical conduct of computing professionals.',
              'inspire and guide the ethical conduct of all computing professionals, including students'),
          isTrue);
      expect(answerWithin('It leads to broader discussions about software impacts, announced in 1999',
          'more discussion about the broader impacts of the technical work'), isFalse);
    });

    test('a different, longer or part-word answer is not within it', () {
      expect(answerWithin('1998', 'February 1891'), isFalse);
      expect(answerWithin('Berlin, as announced in 1999 by the Ministry of Finance', 'Berlin'), isFalse);
      expect(answerWithin('19', 'February 1891'), isFalse);
      expect(answerWithin('', 'Berlin'), isFalse);
      expect(answerWithin('Berlin', ''), isFalse);
    });
  });
}
