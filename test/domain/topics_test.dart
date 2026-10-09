import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/topics.dart';

String _pages(List<String> pages) => pages.join('\n\n');

const _longBody = 'This slide explains the idea in a sentence that is long enough to be a real slide of content.';

void main() {
  group('headings', () {
    test('isHeadingLine wants a short line of capitalised words, no full stop, no bullet', () {
      expect(isHeadingLine('Copyright Term'), isTrue);
      expect(isHeadingLine('Patents'), isTrue);
      expect(isHeadingLine('ECONOMIC DEVELOPMENT'), isTrue);
      expect(isHeadingLine('Are IT Workers Professionals?'), isTrue);
      expect(isHeadingLine('Relationships Between IT Professionals and Employers'), isTrue);
      expect(isHeadingLine('Profession is a calling that requires:'), isFalse);
      expect(isHeadingLine('Credit: Course Technology/Cengage Learning.'), isFalse);
      expect(isHeadingLine('- Specialized knowledge'), isFalse);
      expect(isHeadingLine('• Mobile Application Developers'), isFalse);
      expect(isHeadingLine('1.1 Avoid harm'), isFalse);
      expect(isHeadingLine('and IT Users'), isFalse);
      expect(isHeadingLine('and IT Users', continued: true), isTrue);
      expect(isHeadingLine('the relationship between workers and the client company'), isFalse);
    });

    test('tidyHeading puts run-together words right, using words the notes know', () {
      const vocab = {'tariffs', 'agreement', 'protection', 'trade', 'code', 'types', 'wto', 'privacy'};
      expect(tidyHeading('TheDigitalMillenniumCopyrightAct(1998)'), 'The Digital Millennium Copyright Act (1998)');
      expect(tidyHeading('GeneralAgreementonTariffsandTrade', vocab: vocab), 'General Agreement on Tariffs and Trade');
      expect(tidyHeading('Privacy Protectionandthe Law', vocab: vocab), 'Privacy Protection and the Law');
      expect(tidyHeading('TheWTOandtheWTOTRIPSAgreement(1994)', vocab: vocab), 'The WTO and the WTOTRIPS Agreement (1994)');
      expect(tidyHeading('Typesof Privacy Harm', vocab: vocab), 'Types of Privacy Harm');
      // a word that only looks glued is left alone
      expect(tidyHeading('Protection Law', vocab: vocab), 'Protection Law');
    });

    test('titleCase handles capitals, small words and ordinals', () {
      expect(titleCase('THE CAVITE MUTINY (1872)'), 'The Cavite Mutiny (1872)');
      expect(titleCase('LIFE AND WORKS OF RIZAL'), 'Life and Works of Rizal');
      expect(titleCase('OF THE 19th CENTURY'), 'Of the 19th Century');
      expect(tidyHeading('THE ECONOMIC CONTEXT OF THE 19th CENTURY'), 'The Economic Context of the 19th Century');
    });
  });

  test('looksLikeLabel tells a title from a statement, however long', () {
    expect(looksLikeLabel('Distinguishing the Difference Between Bribes and Gifts Relationships Between IT Professionals and Suppliers'), isTrue);
    expect(looksLikeLabel('Distinguish a Professional from Other Workers'), isTrue);
    expect(looksLikeLabel('Develop good relationships with suppliers'), isFalse);
    expect(looksLikeLabel('Copyrights protect original works.'), isFalse);
    expect(looksLikeLabel('Patents'), isFalse); // one word is not enough to say
  });

  group('groupSlides', () {
    test('credit and source lines are not slide content', () {
      final notes = _pages([
        'Copyrights\n- A copyright is the exclusive right to distribute, display, perform, or reproduce an original work.\nCredit: Course Technology/Cengage Learning.',
        'Patents\n- A patent permits its owner to exclude the public from making, using, or selling a protected invention.\nSource Line: Course Technology/Cengage Learning.',
        'Trade Secrets\n- Business information that is generally unknown to the public and kept confidential by the company.',
      ]);
      final g = groupSlides(notes, maxGroups: 14)!;
      expect(g.any((x) => x.text.contains('Cengage')), isFalse);
      expect(g.first.text, contains('exclusive right'));
    });

    test('pages with the same heading are one topic, headings first', () {
      final notes = _pages([
        'Copyrights\n- A copyright is the exclusive right to distribute, display, perform, or reproduce an original work.',
        'Copyrights\n- Copyright infringement is a violation of the rights secured by the owner of a copyright.',
        'Patents\n- A patent permits its owner to exclude the public from making, using, or selling a protected invention.',
        'Trade Secrets\n- Business information that is generally unknown to the public and kept confidential by the company.',
      ]);
      final g = groupSlides(notes, maxGroups: 14)!;
      expect(g.map((x) => x.title), ['Copyrights', 'Patents', 'Trade Secrets']);
      expect(g.first.text, contains('exclusive right'));
      expect(g.first.text, contains('infringement'));
      expect(g.first.text, isNot(contains('patent permits')));
    });

    test('a heading at the end of the page, wrapped over two lines, is found', () {
      final notes = _pages([
        '- The client makes decisions about a project on the basis of information from the IT worker.\n'
            '- Problems arise if the worker cannot give full and accurate reports of the status.\n'
            'Relationships Between IT \nProfessionals and Clients',
        '- Bribery is providing money, property, or favors to obtain a business advantage over others.\n'
            '- Deal fairly with suppliers and do not make unreasonable demands of them.\n'
            'Relationships Between IT \nProfessionals and Suppliers',
        '- Fraud is the crime of obtaining goods, services, or property through deception or trickery.\n'
            '- Misrepresentation is the misstatement or incomplete statement of a material fact.\n'
            'Fraud and Misrepresentation',
      ]);
      final g = groupSlides(notes, maxGroups: 14)!;
      expect(g.map((x) => x.title), [
        'Relationships Between IT Professionals and Clients',
        'Relationships Between IT Professionals and Suppliers',
        'Fraud and Misrepresentation',
      ]);
      expect(g.first.text, contains('client makes decisions'));
      expect(g.first.text, isNot(contains('Relationships Between')));
    });

    test('a heading is not joined to the line after it unless it wraps', () {
      final notes = _pages([
        'Current Intellectual Property Issues\nReverse Engineering\n- The process of taking something apart to understand it, build a copy of it, or improve it.',
        'Current Intellectual Property Issues\n- Using reverse engineering, a developer can recover the design of an application.',
        'Patents\n- A patent permits its owner to exclude the public from making, using, or selling an invention.',
      ]);
      final g = groupSlides(notes, maxGroups: 14)!;
      expect(g.map((x) => x.title), ['Current Intellectual Property Issues', 'Patents']);
      expect(g.first.text, contains('Reverse Engineering'));
    });

    test('module labels, learning outcomes, references and running titles are not topics', () {
      final notes = _pages([
        'Social and Professional Issues Module 3\nSubtopic 1',
        'Intended Learning Outcomes\n- Understand how to protect intellectual property and the limits of copyright law.',
        'Copyrights\n- A copyright is the exclusive right to distribute, display, perform, or reproduce an original work.',
        'Patents\n- A patent permits its owner to exclude the public from making, using, or selling a protected invention.',
        'References\n- Reynolds, G. Ethics in Information Technology, Cengage Learning, 2019 and later editions.',
        '- Another reference line that follows the references heading and lists a source for the module.',
      ]);
      final g = groupSlides(notes, maxGroups: 14)!;
      expect(g.map((x) => x.title), ['Copyrights', 'Patents']);
      expect(g.any((x) => x.text.contains('Reynolds')), isFalse);
      expect(g.first.text, contains('Understand how to protect')); // the aims stay with the first topic
    });

    test('a heading on most pages is a running title, and footer lines are dropped', () {
      final pages = [
        for (final t in ['Copyrights', 'Patents', 'Trade Secrets', 'Privacy', 'Plagiarism', 'Open Source', 'Reverse Engineering'])
          'Module Notes\n$t\n- A line about $t that is long enough to count as content of the slide.\nCredit: Cengage Learning 2019.',
      ];
      final g = groupSlides(_pages(pages), maxGroups: 14)!;
      expect(g.map((x) => x.title).whereType<String>(), isNot(contains('Module Notes')));
      expect(g.any((x) => x.text.contains('Credit: Cengage')), isFalse);
    });

    test('notes without pages or headings are not grouped', () {
      expect(groupSlides('Plain notes about plants and light.\nMore notes about water.', maxGroups: 14), isNull);
      expect(groupSlides(_pages(['- one $_longBody', '- two $_longBody', '- three $_longBody']), maxGroups: 14), isNull);
    });

    test('a cover and tiny labels do not become topics', () {
      final notes = _pages([
        'LIFE AND WORKS OF RIZAL\nGED0049',
        'ECONOMIC DEVELOPMENT\nThe growth of an export economy in 1830 brought increasing prosperity to the Filipino middle class.',
        'FRIAR HACIENDAS\nINQUILINOS',
        'POLITICAL DEVELOPMENT\nFilipinos were deprived of the few positions they had held in the bureaucracy of their own country.',
      ]);
      final g = groupSlides(notes, maxGroups: 14)!;
      expect(g.map((x) => x.title), ['Economic Development', 'Political Development']);
      expect(g.first.text, contains('INQUILINOS')); // the label stays with its topic
    });

    test('too many topics are joined, alike and small ones first, and the joined topic has no single title', () {
      final topics = {
        'Copyright': 'copyright protects authored works such as books, film and music for the life of the author',
        'Copyright Term': 'the term of copyright has been extended several times for authored works of the author',
        'Patents': 'a patent protects an invention and lets the owner exclude others from making or selling it',
        'Trade Secrets': 'a trade secret is business information kept confidential by the company that owns it',
        'Privacy': 'privacy is the right to be left alone and to keep personal information from being shared',
        'Plagiarism': 'plagiarism is passing off the words of another person as your own without citing the source',
      };
      final notes = _pages([for (final e in topics.entries) '${e.key}\n- ${e.value}.']);
      final g = groupSlides(notes, maxGroups: 5)!;
      expect(g.length, 5);
      final joined = g.firstWhere((x) => x.titles.length > 1);
      expect(joined.title, isNull);
      expect(joined.titles, ['Copyright', 'Copyright Term']); // the alike pair
    });

    test('a very long topic is split at page boundaries, when there is room', () {
      const acts = [
        'Fair Credit', 'Financial Privacy', 'Gramm Leach Bliley', 'Health Insurance', 'Family Educational',
        'Wiretap', 'Electronic Communications', 'Patriot', 'Freedom', 'Cable Communications', 'Video Privacy',
        'Driver Protection',
      ];
      final big = [
        for (final a in acts)
          'Privacy Law\n- The $a Act protects personal data and records. ${'It regulates collection and use of data by agencies. ' * 6}',
      ];
      final notes = _pages([...big, 'Patents\n- A patent permits its owner to exclude the public from making, using, or selling an invention.']);
      final g = groupSlides(notes, maxGroups: 5)!;
      final parts = g.where((x) => x.titles.contains('Privacy Law')).toList();
      expect(parts.length, greaterThan(1));
      expect(parts.first.title, 'Privacy Law (1 of ${parts.length})');
      expect(g.any((x) => x.title == 'Patents'), isTrue);
    });
  });
}
