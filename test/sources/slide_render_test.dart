import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/sources/slide_render.dart';

void main() {
  group('findQuoteRange', () {
    const page = 'Patents\n- A patent permits its owner to exclude the public from making,\n'
        'using, or selling a protected invention.\n- Year Exports\n1825 1, 000, 000 1, 800, 000';

    test('finds a quote across line breaks, bullets and punctuation', () {
      final r = findQuoteRange(page, 'A patent permits its owner to exclude the public from making, using, or selling a protected invention.')!;
      expect(page.substring(r.$1, r.$2 + 1), startsWith('A patent permits'));
      expect(page.substring(r.$1, r.$2 + 1), endsWith('protected invention'));
    });

    test('is not thrown by capitals or the spaced-out numbers PDFs leave', () {
      final r = findQuoteRange(page, 'YEAR EXPORTS\n1825 1,000,000 1,800,000')!;
      expect(page.substring(r.$1, r.$2 + 1), endsWith('1, 800, 000'));
    });

    test('falls back to the start or the end of a quote that has been shortened or extended', () {
      // the page has the first part only
      final start = findQuoteRange(page, 'A patent permits its owner to exclude the public from making, using, or selling a protected invention and much more that the slide never says at all.');
      expect(start, isNotNull);
      expect(page.substring(start!.$1, start.$2 + 1), startsWith('A patent permits'));
    });

    test('says null when the quote is not on the page or is too short to trust', () {
      expect(findQuoteRange(page, 'Volcanoes erupt when magma rises through the crust.'), isNull);
      expect(findQuoteRange(page, 'patent'), isNull);
      expect(findQuoteRange(page, ''), isNull);
      expect(findQuoteRange('', 'Anything long enough to count as a quote.'), isNull);
    });
  });

  group('mergeLines', () {
    test('letters on one line become one box, and two lines become two', () {
      final boxes = mergeLines([
        const Rect.fromLTRB(10, 100, 20, 120), const Rect.fromLTRB(20, 101, 30, 121), const Rect.fromLTRB(30, 99, 45, 119),
        const Rect.fromLTRB(10, 130, 22, 150), const Rect.fromLTRB(22, 131, 40, 151),
      ]);
      expect(boxes, hasLength(2));
      expect(boxes[0].left, 10);
      expect(boxes[0].right, 45);
      expect(boxes[1].top, 130);
    });

    test('empty boxes (spaces) and thin ones (a comma, a hyphen) are left out', () {
      final boxes = mergeLines([
        const Rect.fromLTRB(10, 100, 20, 120),
        const Rect.fromLTRB(20, 100, 20, 120), // a space: no width
        const Rect.fromLTRB(21, 115, 24, 124), // a comma: short
        const Rect.fromLTRB(25, 100, 35, 120),
      ]);
      expect(boxes, hasLength(1));
      expect(boxes.single.right, 35);
      expect(boxes.single.bottom, 120); // the comma did not stretch the line
    });

    test('nothing in, nothing out', () {
      expect(mergeLines(const []), isEmpty);
      expect(mergeLines(const [Rect.fromLTRB(5, 5, 5, 5)]), isEmpty);
    });
  });

  test('renderSlide says null for a file that is not there, instead of failing', () async {
    expect(await renderSlide('C:/no/such/file.pdf', 1), isNull);
  });
}
