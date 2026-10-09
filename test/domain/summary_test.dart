import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/domain/summary.dart';

void main() {
  test('parseSection reads the heading, explanation and key points', () {
    final s = parseSection(
        'Sure! {"heading":"The cell","explanation":"Cells are the units of life.","keyPoints":["Cells divide","  "]}');
    expect(s.heading, 'The cell');
    expect(s.explanation, 'Cells are the units of life.');
    expect(s.keyPoints, ['Cells divide']);
  });

  test('parseSection strips echoed placeholders and rejects empty sections', () {
    final s = parseSection('{"heading":"<heading> The cell","explanation":"It lives.","keyPoints":[]}');
    expect(s.heading, 'The cell');
    expect(() => parseSection('{"heading":"","explanation":"x"}'), throwsFormatException);
    expect(() => parseSection('{"heading":"x"}'), throwsFormatException);
    expect(() => parseSection('no json'), throwsFormatException);
  });

  test('parseOverview needs an overview but not takeaways', () {
    final (o, t) = parseOverview('{"overview":"The big idea.","takeaways":["One.","","Two."]}');
    expect(o, 'The big idea.');
    expect(t, ['One.', 'Two.']);
    expect(parseOverview('{"overview":"Only this."}').$2, isEmpty);
    expect(() => parseOverview('{"takeaways":["x"]}'), throwsFormatException);
  });

  test('isCopy ignores case and spacing', () {
    expect(isCopy('plants make  sugar', 'Plants make\nsugar from light.'), isTrue);
    expect(isCopy('Plants build their own food', 'Plants make sugar from light.'), isFalse);
    expect(isCopy('', 'anything'), isFalse);
  });

  test('prompts carry the notes and the section list', () {
    expect(buildSectionPrompt('MY NOTES'), contains('MY NOTES'));
    final p = buildOverviewPrompt(const [
      SummarySection(heading: 'The cell', explanation: 'Cells are the units of life.'),
      SummarySection(heading: 'DNA', explanation: 'DNA stores instructions.'),
    ]);
    expect(p, contains('1. The cell: Cells are the units of life.'));
    expect(p, contains('2. DNA: DNA stores instructions.'));
  });

  test('toText writes the lesson as Markdown', () {
    const lesson = LessonSummary(
      overview: 'About cells.',
      sections: [
        SummarySection(heading: 'The cell', explanation: 'Cells are the units of life.', keyPoints: ['Cells divide']),
      ],
      takeaways: ['Cells make up every organism.'],
    );
    expect(lesson.toText(), '''
## Overview
About cells.

## The cell
Cells are the units of life.
- Cells divide

## Remember
- Cells make up every organism.'''
        .trim());
  });

  test('toText leaves out empty parts', () {
    const lesson = LessonSummary(sections: [
      SummarySection(heading: 'A', explanation: 'B'),
    ]);
    expect(lesson.toText(), '## A\nB');
  });

  test('a lesson is saved and read back whole, and bad saves read as none', () {
    const lesson = LessonSummary(
      overview: 'About cells.',
      sections: [
        SummarySection(
            heading: 'The cell',
            explanation: 'Cells are the units of life.',
            keyPoints: ['Cells divide'],
            facts: ['Built in 1859.', 'Year Exports\n1825 1,000,000']),
      ],
      takeaways: ['Cells make up every organism.'],
      keyTerms: ['cell', 'organism'],
    );
    final back = LessonSummary.decode(lesson.encode())!;
    expect(back.encode(), lesson.encode());
    expect(back.sections.single.facts.last, 'Year Exports\n1825 1,000,000');
    expect(back.keyTerms, ['cell', 'organism']);
    expect(LessonSummary.decode(''), isNull);
    expect(LessonSummary.decode('not json'), isNull);
    expect(LessonSummary.decode('{"sections": []}'), isNull);
    expect(LessonSummary.decode('{"sections": "oops"}'), isNull);
  });

  test('toStudyText gives each section as plain notes, blank line between', () {
    const lesson = LessonSummary(sections: [
      SummarySection(heading: 'A', explanation: 'Because B.', keyPoints: ['P1'], facts: ['F1']),
      SummarySection(heading: 'C', explanation: '', facts: ['F2']),
    ]);
    expect(lesson.toStudyText(), 'A\nBecause B.\nP1\nF1\n\nC\nF2');
  });

  test('toText lists the key facts, tables on indented lines', () {
    const lesson = LessonSummary(sections: [
      SummarySection(heading: 'A', explanation: 'B', facts: ['Built in 1859.', 'Year Exports\n1825 1,000,000']),
    ]);
    expect(lesson.toText(), '## A\nB\nKey facts:\n- Built in 1859.\n- Year Exports\n  1825 1,000,000');
  });

  test('figuresInSource catches years and amounts the notes never gave', () {
    const notes = 'In 1830 exports grew.\nYear Exports\n1825 1, 000, 000 1, 800, 000\nCopyright lasts 28 years.';
    expect(figuresInSource('Exports grew in 1830.', notes), isTrue);
    expect(figuresInSource('Exports were 1,000,000 pesos in 1825.', notes), isTrue);
    expect(figuresInSource('The war of 1898 changed things.', notes), isFalse);
    expect(figuresInSource('Exports rose from 2 million to 36 million.', notes), isFalse);
    expect(figuresInSource('Copyright lasts 28 years.', notes), isTrue);
    expect(figuresInSource('Copyright was extended to 40 years.', notes), isFalse);
    expect(figuresInSource('Three groups, not a number.', notes), isTrue);
  });

  test('groundedSentences drops sentences with invented figures and cut-off ones', () {
    const notes = 'Exports grew in 1830 and prosperity spread among the Filipino middle class.';
    expect(
        groundedSentences('Exports grew in 1830. Exports grew again in 1898. Prosperity spread among the Filipino middle', notes),
        'Exports grew in 1830.');
  });

  test('dropSlideTalk removes sentences about the slides, keeps the ones about the subject', () {
    expect(
        dropSlideTalk('This part introduces trade secrets. A trade secret is private business information. In this section we focus on law.'),
        'A trade secret is private business information.');
    expect(dropSlideTalk('The slides explain it. The lesson covers it.'), '');
    expect(dropSlideTalk('The Code guides professionals.'), 'The Code guides professionals.');
  });

  test('namesInSource catches places and people the notes never mention', () {
    const notes = 'The Cavite Mutiny of 1872 led to the execution of Gomburza. GATT was replaced by the WTO.';
    expect(namesInSource('The movement grew after the Cavite Mutiny.', notes), isTrue);
    expect(namesInSource('The Nationalist Movement in China grew.', notes), isFalse);
    expect(namesInSource('Nationalism spread across Mindanao.', notes), isFalse);
    expect(namesInSource('The WTO replaced GATT.', notes), isTrue);
    expect(namesInSource('The OECD replaced GATT.', notes), isFalse);
    expect(namesInSource('Plants make sugar.', notes), isTrue);
    expect(groundedSentences('The Cavite Mutiny of 1872 mattered. The Mutiny spread to China.', notes), 'The Cavite Mutiny of 1872 mattered.');
  });

  test('dropSlideTalk also removes "It explains that..." sentences', () {
    expect(dropSlideTalk('It explains that GATT was a trade deal. GATT reduced tariffs between countries.'),
        'GATT reduced tariffs between countries.');
    expect(dropSlideTalk('It was replaced by the WTO in 1995.'), 'It was replaced by the WTO in 1995.');
  });

  test('groundedSentences drops the tail of a cut sentence', () {
    const notes = 'The Philippines has its own Intellectual Property Code, Republic Act No. 8293, and an office that enforces it.';
    expect(groundedSentences('8293). The Philippines has its own Intellectual Property Code and an office that enforces it.', notes),
        'The Philippines has its own Intellectual Property Code and an office that enforces it.');
  });

  test('dropContradictions removes a sentence that says the opposite of the slide', () {
    final items = [
      'IT workers are not recognized as professionals because they are not licensed by the state.',
      'Employees must follow a code of ethics in their work.',
    ];
    expect(
        dropContradictions(
            'IT workers are recognized as professionals because they are licensed by the state. Employees must follow a code of ethics.',
            items),
        'Employees must follow a code of ethics.');
    expect(dropContradictions('IT workers are not recognized as professionals by the state.', items),
        'IT workers are not recognized as professionals by the state.');
  });

  group('sources of a lesson', () {
    final locator = SourceLocator(parsePages([
      pageMarker(5),
      'Patents\n- A patent permits its owner to exclude the public from making, using, or selling a protected invention.\n'
          '- Utility patents last up to twenty years from the date of filing.',
      '',
      pageMarker(9),
      'Copyrights\n- A copyright is the exclusive right to distribute, display, perform, or reproduce an original work.',
    ].join('\n')));
    const copied = 'A patent permits its owner to exclude the public from making, using, or selling a protected invention.';
    const explained = 'A patent lets the owner stop the public from making or selling the invention.';
    const fact = 'Utility patents last up to twenty years from the date of filing.';
    const invented = 'Volcanoes erupt when magma rises through cracks in the crust of the planet.';
    final lesson = const LessonSummary(
      overview: 'About patents.',
      sections: [
        SummarySection(heading: 'Patents', explanation: explained, keyPoints: [copied], facts: [fact]),
      ],
      takeaways: [invented],
    ).withSources(locator);

    test('every explanation, point, fact and takeaway is traced to a page, or flagged', () {
      expect(lesson.sourceOf(explained)!.kind, SourceKind.explained);
      expect(lesson.sourceOf(explained)!.page, 5);
      expect(lesson.sourceOf(copied)!.kind, SourceKind.copied);
      expect(lesson.sourceOf(fact)!.kind, SourceKind.copied);
      expect(lesson.sourceOf(fact)!.page, 5);
      expect(lesson.sourceOf(invented)!.kind, SourceKind.unmatched); // flagged, not hidden
      expect(lesson.sourceOf('never looked up'), isNull);
      expect(lesson.sections.single.keyPoints, [copied]); // the lesson itself is unchanged
    });

    test('the sources are saved with the lesson and read back', () {
      final back = LessonSummary.decode(lesson.encode())!;
      expect(back.sourceOf(explained)!.kind, SourceKind.explained);
      expect(back.sourceOf(explained)!.pages, lesson.sourceOf(explained)!.pages);
      expect(back.sourceOf(copied)!.quote, startsWith('A patent permits'));
      expect(back.sourceOf(invented)!.kind, SourceKind.unmatched);
    });

    test('a lesson saved before sources existed reads with none, and no locator changes nothing', () {
      final old = LessonSummary.decode('{"overview":"x","sections":[{"heading":"H","explanation":"E"}]}')!;
      expect(old.sources, isEmpty);
      expect(old.sourceOf('E'), isNull);
      expect(identical(old.withSources(null), old), isTrue);
    });
  });

  group('keyFacts', () {
    test('keeps years, figures and tables word for word', () {
      const slide = 'The growth of an export economy in 1830 brought increasing prosperity to the Filipino middle and upper classes.\n'
          'Year Exports \n(in pesos)\nImports \n(in pesos)\n'
          '1825 1, 000, 000 1, 800, 000\n1875 18, 900,000 12, 200, 000\n\n'
          '\u2022 The Rizal Family in the 1890\u2019s rented \nfrom the hacienda over 390 hectares.\nFRIAR HACIENDAS';
      final facts = keyFacts(slide);
      expect(facts, contains('Year Exports (in pesos) Imports (in pesos)\n1825 1,000,000 1,800,000\n1875 18,900,000 12,200,000'));
      expect(facts, contains('The growth of an export economy in 1830 brought increasing prosperity to the Filipino middle and upper classes.'));
      expect(facts, contains('The Rizal Family in the 1890\u2019s rented from the hacienda over 390 hectares.'));
      expect(facts, hasLength(3));
    });

    test('ignores a line that carries a source note', () {
      expect(keyFacts('Ieee Annual Report Source: 2024 IEEE Annual Report | Home'), isEmpty);
    });

    test('ignores centuries, list numbers and source lines', () {
      expect(keyFacts('1. Discuss the status of the world in the 19th century\n2. Single out some developments of the 19th century'), isEmpty);
      expect(keyFacts('1.1 Contribute to society and to human well-being.\n1.2 Avoid harm and be honest.'), isEmpty);
      expect(keyFacts('Source: 2024 IEEE Annual Report | Home'), isEmpty);
    });

    test('an empty line is the start of the next slide, so lines do not run together', () {
      expect(keyFacts('Cabezas de baranggay- head of the barangay\n\nThe Opening of Suez Canal in\n1869'),
          ['The Opening of Suez Canal in 1869']);
    });
  });
}
