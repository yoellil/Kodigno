import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/nlp.dart';

void main() {
  test('sameAnswer: the model\'s own answer matches the key, or not', () {
    expect(sameAnswer('Calamba', 'Calamba'), isTrue);
    expect(sameAnswer('at the bottom of the class', 'Placed at the bottom'), isTrue);
    expect(sameAnswer('the threat that data poses', 'The threat that data poses if used against people'), isTrue);
    expect(sameAnswer('his mother', "His father's classmate Leon Monroy"), isFalse);
    expect(sameAnswer('June 1874', 'June 1872'), isFalse); // every number of the key
    expect(sameAnswer('the', 'The atom'), isFalse); // holds it, but says nothing
    expect(sameAnswer('village', 'age'), isFalse);
  });

  test('terms are the meaningful words, stemmed, with no stop words', () {
    expect(terms('The copyrights of Developers are protected'), ['copyright', 'developer', 'protect']);
    expect(terms('It is to be in a of the'), isEmpty);
  });

  test('similarity is high for the same subject and low for another', () {
    final idf = idfOf([
      'Copyright protects authored works such as books and music.',
      'A copyright is the exclusive right to reproduce an original work.',
      'Reverse engineering takes a program apart to understand it.',
    ]);
    final a = similarity('Copyright protects authored works such as books and music.',
        'A copyright is the exclusive right to reproduce an original work.', idf);
    final b = similarity('Copyright protects authored works such as books and music.',
        'Reverse engineering takes a program apart to understand it.', idf);
    expect(a, greaterThan(b));
    expect(b, 0);
  });

  group('keyTerms', () {
    const slide = 'An Acceptable Use Policy (AUP) is a document that stipulates restrictions.\n'
        'The acceptable use policy is signed by employees before they get a user ID.\n'
        'Members of legal and human resources help to write the acceptable use policy.\n'
        'Each employee signs one on the first day.';

    test('picks the phrase the slide keeps coming back to', () {
      expect(keyTerms(slide, n: 3).first, 'acceptable use policy');
    });

    test('a phrase seen once ranks below one that repeats, and course words are left out', () {
      final t = keyTerms('$slide\nIntended Learning Outcomes\nSource Line: Course Technology/Cengage Learning.', n: 6);
      expect(t.any((p) => p.contains('learning outcome') || p.contains('cengage') || p.contains('source line')), isFalse);
      expect(t, contains('acceptable use policy'));
    });

    test('words from the headings count for more', () {
      const text = 'Fair dealing covers criticism and review of a work.\nThe fair use test weighs the purpose of the use.\nParody can be fair use.';
      final plain = keyTerms(text, n: 1);
      final boosted = keyTerms(text, n: 1, boost: 'Fair Use');
      expect(boosted.single, contains('fair use'));
      expect(plain, isNotEmpty);
    });

    test('phrases that contain each other are listed once', () {
      final t = keyTerms('Copyright infringement is a violation.\nCopyright infringement occurs when someone copies a work.\nA copyright is a right.', n: 5);
      expect(t.where((p) => p.contains('copyright')).length, 1);
    });
  });

  group('textItems', () {
    test('joins wrapped lines, starts a new item at each bullet, ends one at an empty line', () {
      const text = '- A trade secret is information used in business\n'
          'that is generally unknown to the public.\n'
          '• Whistle-blowing attracts attention to an illegal act.\n'
          '✓ Explain the purpose of the code.\n'
          '\n'
          'Another slide begins here without a bullet';
      expect(textItems(text), [
        'A trade secret is information used in business that is generally unknown to the public.',
        'Whistle-blowing attracts attention to an illegal act.',
        'Explain the purpose of the code.',
        'Another slide begins here without a bullet',
      ]);
    });

    test('a capital-letter heading stands alone', () {
      expect(textItems('FRIAR HACIENDAS\nINQUILINOS\nThe tenants rented land from the hacienda.'),
          ['FRIAR HACIENDAS', 'INQUILINOS', 'The tenants rented land from the hacienda.']);
    });

    test('a long item with several sentences becomes several items', () {
      final s = '${'First sentence about the subject goes here. ' * 4}Second Sentence starts with a capital. ${'More words follow here. ' * 6}';
      expect(textItems(s).length, greaterThan(1));
    });
  });

  group('condense', () {
    final items = [
      'Copyright protects authored works such as books, film and music.',
      'A copyright is the exclusive right to reproduce an original work.',
      'Copyright infringement is copying a copyrighted work without permission.',
      'The lecturer arrived late and the room was cold that morning.',
      'Eligible works for copyright include art, books, film and music.',
    ];

    test('returns everything when it fits', () {
      expect(condense(items, maxChars: 10000), items);
    });

    test('keeps the lines the others agree with, in their order, and drops the stray one', () {
      final picked = condense(items, maxChars: 200);
      expect(picked.join(' ').length, lessThanOrEqualTo(200));
      expect(picked, isNot(contains(items[3])));
      expect(picked.indexOf(items[0]), lessThan(picked.length));
      final order = [for (final p in picked) items.indexOf(p)];
      expect(order, [...order]..sort());
    });

    test('a line with a key term gets a lift', () {
      final picked = condense(items, maxChars: 75, keyTerms: ['infringement']);
      expect(picked, [items[2]]);
    });

    test('always returns at least one line', () {
      expect(condense(items, maxChars: 5), hasLength(1));
    });
  });

  test('copyRatio tells copying from rewording', () {
    const source = 'A trade secret is information used in business that is generally unknown to the public.';
    expect(copyRatio('A trade secret is information used in business that is generally unknown', source), 1);
    expect(copyRatio('Companies guard private know-how so rivals cannot learn it.', source), 0);
    expect(copyRatio('Too short', source), 0);
  });

  test('a list number such as 1.5 is removed whole, but a plain number stays', () {
    expect(textItems('1.5 Respect the work required to produce new ideas.\n2) Honor confidentiality.\n10 apples are in the box'),
        ['Respect the work required to produce new ideas.', 'Honor confidentiality.', '10 apples are in the box']);
  });

  test('contradicts also catches a flipped claim that adds words of its own', () {
    final src = ['IT workers are not recognized as professionals because they are not licensed by the state or federal government.'];
    expect(contradicts('IT workers are recognized as professionals because they meet specific criteria such as certification or licensing.', src), isTrue);
    // two shared words are not enough to say it is the same statement
    expect(contradicts('Workers are paid weekly.', src), isFalse);
  });

  test('contradicts spots a flipped claim but not a faithful one', () {
    final src = ['IT workers are not recognized as professionals because they are not licensed.'];
    expect(contradicts('IT workers are recognized as professionals because they are licensed.', src), isTrue);
    expect(contradicts('IT workers are not recognized as professionals.', src), isFalse);
    expect(contradicts('Dinosaurs are not extinct in this story.', src), isFalse); // nothing alike
  });
}
