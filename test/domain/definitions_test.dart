import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/definitions.dart';

// Text as it comes out of a lecture-slide PDF: bullets, lines wrapped mid-sentence.
const _slides = '''
Cybersecurity Criminals (Cont.)
Criminals come in many different forms. Each have their own motives:
▪ Script Kiddies - Teenagers or hobbyists mostly limited to pranks
and vandalism, have little or no skill, often using existing tools or
instructions found on the Internet to launch attacks.
▪ Hacktivists - Grey hat hackers who rally and protest against
different political and social ideas. Hacktivists publicly protest
against organizations or governments by posting articles.
▪ A cybersecurity threat is the possibility that a harmful event,
such as an attack, will occur
▪ Cyber threats are particularly dangerous to certain industries
▪ There are many national cybersecurity skills competitions available.
Advanced Weapons
▪ Advanced persistent threat (APT) is a continuous computer hack that occurs under the
radar against a specific object. Criminals usually choose an APT for business motives.
▪ EC-Council Certified Ethical Hacker (CEH) – CEH is an intermediate-level certification
for various hacking practices.
▪ At the corporate level, it is the employees’ responsibility to protect the organization.
▪ Join Professional Organizations - Join computer security organizations, attend 
meetings and conferences. 1.6 Chapter Summary
Chapter 1 - Sections & Objectives
Cybersecurity - A World of Experts and Criminals Cybersecurity Essentials v1.1
''';

void main() {
  final defs = {for (final d in extractDefinitions(_slides)) d.term: d.definition};

  test('"Term - definition" bullets, joined across wrapped lines, first sentence only', () {
    expect(defs['Script Kiddies'],
        'Teenagers or hobbyists mostly limited to pranks and vandalism, have little or no skill, '
        'often using existing tools or instructions found on the Internet to launch attacks.');
    expect(defs['Hacktivists'],
        'Grey hat hackers who rally and protest against different political and social ideas.');
    expect(defs['EC-Council Certified Ethical Hacker (CEH)'],
        'CEH is an intermediate-level certification for various hacking practices.');
  });

  test('"Term is a/the ..." sentences, leading article dropped from the term', () {
    expect(defs['Cybersecurity threat'],
        'The possibility that a harmful event, such as an attack, will occur');
    expect(defs['Advanced persistent threat (APT)'],
        'A continuous computer hack that occurs under the radar against a specific object.');
  });

  test('statements, headings and titles are not definitions', () {
    expect(defs.keys, unorderedEquals([
      'Script Kiddies',
      'Hacktivists',
      'Cybersecurity threat',
      'Advanced persistent threat (APT)',
      'EC-Council Certified Ethical Hacker (CEH)',
      'Join Professional Organizations',
    ]));
    expect(defs['Join Professional Organizations'],
        'Join computer security organizations, attend meetings and conferences.');
  });

  test('relatedTerms ranks terms whose definitions share the most words', () {
    const all = <Definition>[
      (term: 'Hacktivists', definition: 'Grey hat hackers who protest against political ideas.'),
      (term: 'Study', definition: 'Learn the basics by completing courses in IT.'),
      (term: 'Vulnerability Brokers', definition: 'Grey hat hackers who report exploits to vendors.'),
      (term: 'Cyber Criminals', definition: 'Black hat hackers working for cybercrime groups.'),
    ];
    expect(relatedTerms(all.first, all), ['Vulnerability Brokers', 'Cyber Criminals']);
  });

  test('maskTerm hides the term, its parts in brackets and its short form', () {
    expect(maskTerm('CEH is an intermediate-level certification.', 'EC-Council Certified Ethical Hacker (CEH)'),
        '____ is an intermediate-level certification.');
    expect(maskTerm('Hacktivists protest. hacktivists post.', 'Hacktivists'), '____ protest. ____ post.');
    expect(maskTerm('A weakness in a target.', 'Cyber vulnerability'), 'A weakness in a target.');
  });

  group('slide headings with dash bullets', () {
    const notes = '''
Professionals and Employers
- In relationships between IT workers and clients, each party agrees to
provide something of value to the other.
- This relationship is usually documented in contractual terms.
- The client makes decisions about a project on the basis of information,
alternatives, and recommendations provided by the IT worker.
Problems in the Relationship
- Misunderstandings arise when the client does not know the technology.
''';
    final found = {for (final d in extractDefinitions(notes)) d.term: d.definition};

    test('the heading is the term and only the first bullet its definition', () {
      expect(found['Professionals and Employers'],
          'In relationships between IT workers and clients, each party agrees to provide something of value to the other.');
      expect(found['Problems in the Relationship'],
          'Misunderstandings arise when the client does not know the technology.');
      expect(found.values.any((v) => v.contains(' - ')), isFalse);
    });
  });

  group('shortenDefinition', () {
    test('keeps short text as is', () {
      expect(shortenDefinition('A short one.'), 'A short one.');
    });

    test('cuts at the last clause break that fits', () {
      expect(
          shortenDefinition(
              'Teenagers or hobbyists mostly limited to pranks and vandalism, have little or no skill, often using existing tools or instructions found on the Internet.'),
          'Teenagers or hobbyists mostly limited to pranks and vandalism, have little or no skill.');
    });

    test('with no clause break it cuts at a word and adds an ellipsis', () {
      final s = shortenDefinition('word ' * 40, max: 50);
      expect(s.length, lessThanOrEqualTo(51));
      expect(s, endsWith('…'));
    });

    test('brackets are dropped before anything is cut, and never cut in half', () {
      const s = 'The Prioritizing Resources and Organization for Intellectual Property (PRO-IP) Act of 2008 (Public Law 110-403) created the position of Intellectual Property Enforcement Coordinator.';
      final r = shortenDefinition(s, max: 130);
      expect(r, isNot(contains('(Public')));
      expect(r.length, lessThanOrEqualTo(131));
      expect('('.allMatches(r).length, ')'.allMatches(r).length);
    });

    test('an introduction is dropped when the sentence is too long', () {
      expect(
          shortenDefinition(
              'In relationships between IT workers and clients, each party agrees to provide something of value to the other, which is documented in contractual terms.',
              max: 100),
          'Each party agrees to provide something of value to the other.');
    });
  });

  group('headings in slides exported from PDF', () {
    const text = '''
Prioritizing Resources and Organization
for Intellectual Property Act of 2008
- The Prioritizing Resources and Organization for Intellectual Property (PRO-IP) Act of 2008
(Public Law 110-403) created the position of Intellectual Property Enforcement Coordinator
within the Executive Office of the President.
- One of its programs, called Computer Hacking and Intellectual Property (CHIP), is a network
of over 150 experienced and specially trained federal prosecutors.
Intellectual Property Code of the Philippines
(Republic Act No. 8293)
- The Prioritizing Resources and Organization for Intellectual Property (PRO-IP) Act of 2008
(Public Law 110-403) does not directly apply to the Philippines.
- The Philippines has its own similar law which is called Intellectual Property Code of the
Philippines (Republic Act No. 8293). This law outlines the protection of IP rights in the
country, including patents, trademarks, copyrights, and trade secrets. It also establishes the
Intellectual Property Office of the Philippines (IPOPHL) as the primary agency.
''';
    final found = {for (final d in extractDefinitions(text)) d.term: d.definition};

    test('each heading gets the bullet about it, not just the first bullet', () {
      expect(found.keys, [
        'Prioritizing Resources and Organization for Intellectual Property Act of 2008',
        'Intellectual Property Code of the Philippines (Republic Act No. 8293)',
      ]);
      expect(found['Intellectual Property Code of the Philippines (Republic Act No. 8293)'],
          startsWith('This law outlines the protection of IP rights'));
    });

    test('the answer does not repeat the term', () {
      expect(found.values.first,
          'Created the position of Intellectual Property Enforcement Coordinator within the Executive Office of the President.');
    });
  });

  group('withoutTerm', () {
    test('drops the restated term and the "is" after it', () {
      expect(withoutTerm('CEH is an intermediate-level certification for various hacking practices.',
              'EC-Council Certified Ethical Hacker (CEH)'),
          'An intermediate-level certification for various hacking practices.');
    });
    test('leaves a sentence that does not start with the term', () {
      const s = 'This law outlines the protection of IP rights in the country.';
      expect(withoutTerm(s, 'Intellectual Property Code'), s);
    });
  });

  test('a heading over a few short bullets becomes one numbered list card', () {
    const text = 'Types of Hackers\n- White hat\n- Black hat hackers\n- Grey hat hackers\n';
    final d = extractDefinitions(text).single;
    expect(d.term, 'Types of Hackers');
    expect(d.definition, '1. White hat\n2. Black hat hackers\n3. Grey hat hackers');
  });
}
