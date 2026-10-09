import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/study/diagnosis.dart';

// Slides as the notes hold them: a marker line starts each page.
final _pages = parsePages([
  pageMarker(3),
  'Intended Learning Outcomes\n- Understand how to protect intellectual property and the limits of copyright.',
  '',
  pageMarker(14),
  'Fraud\n- Crime of obtaining goods, services, or property through deception or trickery.\n'
      'Misrepresentation\n- The misstatement or incomplete statement of a material fact.',
  '',
  pageMarker(15),
  'Fraudulent claims\n- A claim is fraudulent when it is knowingly false.',
  '',
  pageMarker(16),
  'Breach of contract\n- One party fails to meet the terms of a contract.',
  '',
  pageMarker(30),
  'Whistle-blowing\n- Attracts attention to a negligent, illegal, unethical, abusive, or dangerous act that threatens the public interest.',
  '',
  pageMarker(31),
  'Trade secret\n- Information used in business and generally unknown to the public. Law is the subject of this law slide.',
].join('\n'));

final _index = PageIndex(_pages);

Diagnosis? _d(List<String> choices, int answer, int chosen, {SourceRef? source, int earlier = 0, PageIndex? index}) =>
    diagnose(
        choices: choices,
        answerIndex: answer,
        chosen: chosen,
        pages: index ?? _index,
        questionSource: source,
        earlierPicks: earlier);

void main() {
  group('where a wrong choice comes from', () {
    test('on the same slide as the right answer', () {
      final d = _d(['Fraud', 'Misrepresentation', 'Bribery'], 0, 1)!;
      expect(d.kind, MixUp.sameSlide);
      expect(d.pickedPage, 14);
      expect(d.answerPage, 14);
      expect(d.message, 'You picked "Misrepresentation", which is on the same slide as the answer (slide 14). They are easy to mix up.');
    });

    test('a few slides away', () {
      final d = _d(['Breach of contract', 'Fraud', 'Bribery'], 0, 1)!;
      expect(d.kind, MixUp.nearby);
      expect(d.pickedPage, 14);
      expect(d.answerPage, 16);
      expect(d.message, 'You picked "Fraud" (slide 14). The answer, "Breach of contract", is on slide 16, close by.');
    });

    test('in a different part of the lesson', () {
      final d = _d(['Breach of contract', 'Whistle-blowing', 'Bribery'], 0, 1)!;
      expect(d.kind, MixUp.farAway);
      expect(d.pickedPage, 30);
      expect(d.answerPage, 16);
      expect(d.message, contains('a different part of the lesson'));
      expect(d.message, contains('reviewing slide 30'));
    });

    test('not in the slides at all: it may have been a guess', () {
      final d = _d(['Breach of contract', 'Vandalism', 'Bribery'], 0, 1)!;
      expect(d.kind, MixUp.notInSlides);
      expect(d.pickedRef, isNull);
      expect(d.answerPage, 16);
      expect(d.message, 'You picked "Vandalism", which is not in your slides, so it may have been a guess.');
    });

    test('the borders: 3 pages apart is close, 4 is not', () {
      final p = PageIndex(parsePages('${pageMarker(1)}\nAlpha topic text here.\n\n${pageMarker(4)}\nBravo topic text here.\n\n${pageMarker(8)}\nCharlie topic text here.'));
      expect(_d(['Alpha', 'Bravo', 'x'], 0, 1, index: p)!.kind, MixUp.nearby); // 1 and 4
      expect(_d(['Bravo', 'Charlie', 'x'], 0, 1, index: p)!.kind, MixUp.farAway); // 4 and 8
    });
  });

  group('picking it before', () {
    test('says so, in every kind of message', () {
      expect(_d(['Fraud', 'Misrepresentation', 'x'], 0, 1, earlier: 2)!.message, endsWith(' You picked it before, too.'));
      expect(_d(['Breach of contract', 'Fraud', 'x'], 0, 1, earlier: 1)!.message, endsWith('You picked it before, too.'));
      expect(_d(['Breach of contract', 'Vandalism', 'x'], 0, 1, earlier: 1)!.message, endsWith('You picked it before, too.'));
      expect(_d(['Fraud', 'Misrepresentation', 'x'], 0, 1, earlier: 1)!.repeated, isTrue);
      expect(_d(['Fraud', 'Misrepresentation', 'x'], 0, 1)!.repeated, isFalse);
      expect(_d(['Fraud', 'Misrepresentation', 'x'], 0, 1)!.message, isNot(contains('before')));
    });
  });

  group('when the pages cannot say', () {
    test('no pages: nothing to say, except that it was picked before', () {
      final empty = PageIndex(const []);
      expect(_d(['a', 'b'], 0, 1, index: empty)!.kind, MixUp.unknown);
      expect(_d(['a', 'b'], 0, 1, index: empty)!.message, '');
      expect(_d(['a', 'b'], 0, 1, index: empty, earlier: 1)!.message, 'You picked this one before, too.');
    });

    test('the right answer cannot be placed: say where the pick is', () {
      final d = _d(['Something the slides never say', 'Fraud', 'x'], 0, 1)!;
      expect(d.kind, MixUp.unknown);
      expect(d.message, 'You picked "Fraud" (slide 14).');
    });

    test('the right answer is placed by the question\'s own source when its words are not on a page', () {
      const source = SourceRef(kind: SourceKind.explained, pages: [16], score: 0.6);
      final d = _d(['Failing to meet an agreement', 'Fraud', 'x'], 0, 1, source: source)!;
      expect(d.kind, MixUp.nearby);
      expect(d.answerPage, 16);
    });

    test('an unmatched source does not place anything', () {
      const source = SourceRef(kind: SourceKind.unmatched, pages: [16], score: 0.1);
      expect(_d(['Failing to meet an agreement', 'Fraud', 'x'], 0, 1, source: source)!.kind, MixUp.unknown);
    });
  });

  group('how a choice is found', () {
    test('whole words only: Fraud is not found inside Fraudulent', () {
      final p = PageIndex(parsePages('${pageMarker(15)}\nFraudulent claims\n- A claim is fraudulent when it is knowingly false.'));
      expect(p.find('Fraud'), isNull);
      expect(p.find('fraudulent'), isNotNull);
    });

    test('capitals, punctuation and line breaks do not matter', () {
      final r = _index.find('BREACH of  contract!');
      expect(r!.pages, [16]);
      expect(r.kind, SourceKind.copied);
      expect(r.quote, 'BREACH of  contract!');
    });

    test('a word that is on many pages says nothing about one slide', () {
      final many = PageIndex(parsePages([for (var i = 1; i <= 8; i++) '${pageMarker(i)}\nThe law matters on slide $i of the notes about topic $i.'].join('\n')));
      expect(many.find('law'), isNull);
      expect(many.find('topic 3'), isNotNull);
    });

    test('a very short phrase is not looked for', () {
      expect(_index.find('a'), isNull);
      expect(_index.find(''), isNull);
    });

    test('a longer phrase that is reworded is found by how alike the page is', () {
      final r = _index.find('Failing to meet the terms of a contract');
      expect(r, isNotNull);
      expect(r!.kind, SourceKind.explained);
      expect(r.pages.first, 16);
    });

    test('a longer phrase that no page resembles is not found', () {
      expect(_index.find('Volcanoes erupt when magma rises through the crust'), isNull);
    });
  });

  group('nothing to diagnose', () {
    test('a right answer, or an index out of range, is null', () {
      expect(_d(['Fraud', 'Bribery'], 0, 0), isNull);
      expect(_d(['Fraud', 'Bribery'], 0, 5), isNull);
      expect(_d(['Fraud', 'Bribery'], 0, -1), isNull);
      expect(_d(['Fraud', 'Bribery'], 9, 0), isNull);
      expect(_d(const [], 0, 0), isNull);
    });

    test('a long choice is shortened in the message', () {
      final long = 'Fraud ${'and a great many more words that go on and on ' * 3}';
      final d = _d(['Breach of contract', long, 'x'], 0, 1)!;
      expect(d.message, contains('...'));
      expect(d.message.length, lessThan(260));
    });
  });
}
