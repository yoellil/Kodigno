import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/study/confusions.dart';
import 'package:kodigno/study/diagnosis.dart';

WrongPick _p(int q, String picked, String answer, {int set = 1}) =>
    WrongPick(questionId: q, setId: set, picked: picked, answer: answer);

void main() {
  group('findConfusions', () {
    test('the same two things mixed up twice or more is a pattern, in either direction', () {
      final c = findConfusions([
        _p(1, 'Fraud', 'Breach of contract'),
        _p(2, 'Breach of contract', 'Fraud'), // the other way round
        _p(3, 'Bribery', 'Gifts'),
      ]);
      expect(c, hasLength(1));
      expect(c.single.times, 2);
      expect(c.single.a, 'Fraud'); // the most recent question's answer
      expect(c.single.b, 'Breach of contract');
      expect(c.single.questionId, 2);
      expect(c.single.message, 'You have mixed up "Fraud" and "Breach of contract" 2 times.');
    });

    test('once is not a pattern, and the number can be changed', () {
      expect(findConfusions([_p(1, 'Fraud', 'Breach of contract')]), isEmpty);
      expect(findConfusions([_p(1, 'Fraud', 'Breach of contract')], minTimes: 1), hasLength(1));
      expect(findConfusions([_p(1, 'Fraud', 'Breach of contract'), _p(2, 'Fraud', 'Breach of contract')], minTimes: 3), isEmpty);
    });

    test('capitals and punctuation do not make two things different', () {
      final c = findConfusions([_p(1, 'Trade secret', 'Patents'), _p(2, 'PATENTS!', 'trade   secret')]);
      expect(c.single.times, 2);
    });

    test('a pair settles once every question it came up in has been answered right twice in a row', () {
      final picks = [_p(1, 'Fraud', 'Breach of contract'), _p(2, 'Fraud', 'Breach of contract')];
      expect(findConfusions(picks, streakByQuestion: {1: 2, 2: 3}), isEmpty);
      expect(findConfusions(picks, streakByQuestion: {1: 2, 2: 1}), hasLength(1)); // one still not settled
      expect(findConfusions(picks, streakByQuestion: {1: 1, 2: 1}), hasLength(1));
      expect(findConfusions(picks), hasLength(1)); // no history of right answers
    });

    test('long choices are sentences, not things to mix up', () {
      const long = 'The failure of one party to meet the terms of the agreement that was made between the two parties';
      expect(findConfusions([_p(1, long, 'Breach of contract'), _p(2, long, 'Breach of contract')]), isEmpty);
    });

    test('empty choices and a choice picked for itself are ignored', () {
      expect(findConfusions([_p(1, '', 'Fraud'), _p(2, '', 'Fraud')]), isEmpty);
      expect(findConfusions([_p(1, 'Fraud', 'fraud'), _p(2, 'Fraud', 'FRAUD')]), isEmpty);
    });

    test('the most often first, then the most recent', () {
      final c = findConfusions([
        _p(1, 'A', 'B'), _p(2, 'A', 'B'),
        _p(3, 'C', 'D'), _p(4, 'C', 'D'), _p(5, 'C', 'D'),
        _p(6, 'E', 'F'), _p(7, 'E', 'F'),
      ]);
      expect(c.map((x) => x.times), [3, 2, 2]);
      expect(c.map((x) => x.questionId), [5, 7, 2]);
    });

    test('different sets keep their own set for the question to ask again', () {
      final c = findConfusions([_p(1, 'Fraud', 'Breach', set: 4), _p(2, 'Fraud', 'Breach', set: 9)]);
      expect(c.single.setId, 9);
      expect(c.single.questionId, 2);
    });

    test('nothing in, nothing out', () {
      expect(findConfusions(const []), isEmpty);
    });
  });

  group('whatSlidesSay', () {
    final pages = parsePages([
      pageMarker(14),
      'Fraud\n- Crime of obtaining goods, services, or property through deception or trickery.',
      '',
      pageMarker(16),
      'Contracts\n- Breach of contract happens when one party fails to meet the terms of a contract that was agreed.',
      '',
      pageMarker(20),
      'Bribery\n- Providing money, property, or favors to someone in business or government to obtain a business advantage that is not deserved or earned at all and goes on and on for a long time afterwards, which makes this line long enough to need cutting short somewhere. More follows.',
    ].join('\n'));
    final index = PageIndex(pages);

    test('a heading on its own is described by the line under it', () {
      final r = whatSlidesSay('Fraud', index, pages)!;
      expect(r.page, 14);
      expect(r.text, 'Crime of obtaining goods, services, or property through deception or trickery.');
    });

    test('a term inside a sentence is described by that sentence', () {
      final r = whatSlidesSay('Breach of contract', index, pages)!;
      expect(r.page, 16);
      expect(r.text, startsWith('Breach of contract happens when'));
    });

    test('a long line is cut at a sentence end or shortened', () {
      final r = whatSlidesSay('Bribery', index, pages)!;
      expect(r.text.length, lessThanOrEqualTo(224));
      expect(r.text, endsWith('...'));
    });

    test('a definition beats a passing mention, and a course page is never used', () {
      final mixed = parsePages([
        pageMarker(3),
        'Intended Learning Outcomes\n- Understand the strength and limitations of using copyright, patent, trade secret laws to protect property.',
        '',
        pageMarker(7),
        'Overview\n- Companies keep a trade secret, such as a recipe, away from competitors and the public at large.',
        '',
        pageMarker(18),
        'Trade secret\n- Business information that is generally unknown to the public and kept confidential by its owner.',
      ].join('\n'));
      final r = whatSlidesSay('Trade secret', PageIndex(mixed), mixed)!;
      expect(r.page, 18);
      expect(r.text, startsWith('Business information'));
    });

    test('short bullets under a heading are joined, and stop at the next heading', () {
      final shortBullets = parsePages([
        pageMarker(18),
        'Trade secret\n- Business Information\n- It has required effort or cost to develop,\n'
            '- It has some degree of uniqueness or novelty, is generally unknown to the public, and is kept confidential.\n'
            'Trade Secret Laws\n- Protection laws vary greatly from country to country.',
      ].join('\n'));
      final r = whatSlidesSay('Trade secret', PageIndex(shortBullets), shortBullets)!;
      expect(r.page, 18);
      expect(r.text, startsWith('Business Information. It has required effort or cost to develop'));
      expect(r.text, isNot(contains('Protection laws')));
    });

    test('a heading whose first line already says enough is not padded', () {
      final one = parsePages('${pageMarker(14)}\nFraud\n- Crime of obtaining goods, services, or property through deception or trickery.\n- Another bullet that must not be added.');
      final r = whatSlidesSay('Fraud', PageIndex(one), one)!;
      expect(r.text, 'Crime of obtaining goods, services, or property through deception or trickery.');
    });

    test('a sentence that starts with the term beats one that only mentions it', () {
      final two = parsePages([
        pageMarker(2),
        'Overview\n- Many companies protect a patent with great care and then sue anyone who copies the invention.',
        '',
        pageMarker(9),
        'Details\n- A patent permits its owner to exclude the public from making, using, or selling an invention.',
      ].join('\n'));
      final r = whatSlidesSay('patent', PageIndex(two), two)!;
      expect(r.page, 9);
    });

    test('when only a course page has the term, there is nothing to show', () {
      final only = parsePages('${pageMarker(3)}\nIntended Learning Outcomes\n- Understand the strength and limitations of using copyright, patent, trade secret laws.');
      expect(whatSlidesSay('trade secret', PageIndex(only), only), isNull);
    });

    test('a term that is not on a page says nothing', () {
      expect(whatSlidesSay('Vandalism', index, pages), isNull);
    });

    test('a term the slides say nothing more about says nothing', () {
      final bare = parsePages('${pageMarker(1)}\nTrade secret\n\n${pageMarker(2)}\nOther unrelated words about something else entirely here.');
      expect(whatSlidesSay('Trade secret', PageIndex(bare), bare), isNull);
    });

    test('capitals do not matter, and a longer word does not stand for a shorter one', () {
      expect(whatSlidesSay('FRAUD', index, pages)!.page, 14);
      final p = parsePages('${pageMarker(3)}\nFraudulent claims\n- A claim is fraudulent when it is knowingly false and made to deceive.');
      expect(whatSlidesSay('Fraud', PageIndex(p), p), isNull);
    });
  });
}
