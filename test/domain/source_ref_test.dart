import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/source_ref.dart';

String get _notes => [
      pageMarker(3),
      'Copyrights\n- A copyright is the exclusive right to distribute, display, perform, or reproduce an original work.',
      '',
      pageMarker(5),
      'Patents\n- A patent permits its owner to exclude the public from making, using, or selling a protected invention.\n'
          '- Utility patents last up to twenty years from the date of filing.',
      '',
      pageMarker(8),
      'Year Exports \n(in pesos)\nImports \n(in pesos)\n1825 1, 000, 000 1, 800, 000',
    ].join('\n');

void main() {
  group('page markers', () {
    test('parsePages gives each page its true number and text', () {
      final pages = parsePages(_notes);
      expect(pages.map((p) => p.number), [3, 5, 8]);
      expect(pages.first.text, startsWith('Copyrights'));
      expect(pages[1].text, contains('Utility patents'));
      expect(pages[1].text, isNot(contains('Page'))); // the marker is not part of the page
    });

    test('a page with no text is skipped, so numbers can have gaps', () {
      final pages = parsePages('${pageMarker(1)}\nFirst page text.\n\n${pageMarker(2)}\n\n${pageMarker(3)}\nThird page text.');
      expect(pages.map((p) => p.number), [1, 3]);
    });

    test('Windows line endings and spaces around the marker are fine', () {
      final pages = parsePages('  --- Page 4 ---  \r\nText on four.\r\n\r\n--- Page 5 ---\r\nText on five.');
      expect(pages.map((p) => p.number), [4, 5]);
      expect(pages.first.text, 'Text on four.');
    });

    test('notes without markers have no pages, and the words "Page 3" in a sentence are not a marker', () {
      expect(parsePages('Plain notes.\n\nSee Page 3 for details.\nAnd --- Page 9 --- inside a line.'), isEmpty);
      expect(stripPageMarkers('See Page 3 for details.'), 'See Page 3 for details.');
    });

    test('stripPageMarkers leaves the text, a blank line between pages', () {
      final stripped = stripPageMarkers(_notes);
      expect(stripped, isNot(contains('--- Page')));
      expect(stripped.split(RegExp(r'\n[ \t]*\n')).length, 3);
      expect(stripped, startsWith('Copyrights'));
    });

    test('the marker the app writes is the marker it reads', () {
      expect(parsePages('${pageMarker(12)}\nHello there.').single.number, 12);
    });
  });

  group('SourceRef', () {
    test('is saved and read back, and bad saves read as none', () {
      const ref = SourceRef(kind: SourceKind.explained, pages: [5, 6], score: 0.4567, quote: 'A line.', file: 1);
      final back = SourceRef.decode(ref.encode())!;
      expect(back.kind, SourceKind.explained);
      expect(back.pages, [5, 6]);
      expect(back.score, closeTo(0.457, 0.001));
      expect(back.quote, 'A line.');
      expect(back.file, 1);
      expect(back.page, 5);
      expect(SourceRef.decode(''), isNull);
      expect(SourceRef.decode('nope'), isNull);
      expect(SourceRef.decode('[1,2]'), isNull);
      expect(const SourceRef(kind: SourceKind.unmatched).page, isNull);
    });
  });

  group('SourceLocator', () {
    final loc = SourceLocator(parsePages(_notes));

    test('text taken word for word is found by quote, whatever the bullets and line breaks', () {
      final r = loc.locate('A copyright is the exclusive right to distribute, display, perform, or reproduce an original work.');
      expect(r.kind, SourceKind.copied);
      expect(r.pages, [3]);
      expect(r.score, 1);
      expect(r.quote, startsWith('A copyright'));
    });

    test('a table row with the PDF\'s spaced-out numbers is found too', () {
      final r = loc.locate('Year Exports (in pesos) Imports (in pesos)\n1825 1,000,000 1,800,000');
      expect(r.kind, SourceKind.copied);
      expect(r.pages, [8]);
    });

    test('AI-written text is matched to the page it rests on, with the line to point at', () {
      final r = loc.locate('A patent lets the owner stop the public from making or selling the invention.');
      expect(r.kind, SourceKind.explained);
      expect(r.pages.first, 5);
      expect(r.quote, contains('patent permits'));
      expect(r.score, greaterThan(0.2));
      expect(r.score, lessThan(1));
    });

    test('text that no page supports is flagged unmatched', () {
      final r = loc.locate('Volcanoes erupt when magma rises through cracks in the crust of the planet.');
      expect(r.kind, SourceKind.unmatched);
    });

    test('a weak match is unmatched but still points at the closest page', () {
      final strict = SourceLocator(parsePages(_notes), minScore: 0.95);
      final r = strict.locate('A patent lets the owner stop the public from making or selling the invention.');
      expect(r.kind, SourceKind.unmatched);
      expect(r.pages.first, 5); // shown as the closest, not as proof
    });

    test('no pages, or no text, is unmatched', () {
      expect(SourceLocator(const []).locate('Anything at all about patents.').kind, SourceKind.unmatched);
      expect(loc.locate('   ').kind, SourceKind.unmatched);
    });

    test('the file number is carried into each reference', () {
      final two = SourceLocator(parsePages(_notes), file: 1);
      expect(two.locate('A patent lets the owner stop the public from making or selling the invention.').file, 1);
      expect(two.locate('Volcanoes erupt when magma rises through cracks.').file, 1);
    });
  });
}
