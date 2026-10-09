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
}
