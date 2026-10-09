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

  test('a heading over a few short bullets becomes one bulleted list card', () {
    const text = 'Types of Hackers\n- White hat\n- Black hat hackers\n- Grey hat hackers\n';
    final d = extractDefinitions(text).single;
    expect(d.term, 'Types of Hackers');
    expect(d.definition, '\u2022 White hat\n\u2022 Black hat hackers\n\u2022 Grey hat hackers');
  });

  group('list cards ask a question', () {
    test('a title that names a group becomes "What are the ...?"', () {
      expect(questionForTitle('Extra-curricular activities in Ateneo'), 'What are the extra-curricular activities in Ateneo?');
      expect(questionForTitle('General Ethical Principles'), 'What are the General Ethical Principles?');
      expect(questionForTitle('Reasons why Rizal did not perform well in UST'),
          'What are the reasons why Rizal did not perform well in UST?');
      expect(questionForTitle('Why did Rizal shift to a medical course?'), 'Why did Rizal shift to a medical course?');
      expect(questionForTitle('IEEE GRADES OF MEMBERSHIP'), 'What are the "IEEE GRADES OF MEMBERSHIP"?');
    });

    test('only titles that name a group make list cards', () {
      for (final t in ['Extra-curricular activities in Ateneo', 'Logical Oppositions', 'Three Processes of Eduction', 'Why Philosophy & Letters?']) {
        expect(looksLikeCategory(t), isTrue, reason: t);
      }
      for (final t in ['Paciano went to Manila', 'June 1876', 'Spanish', 'Dr. Feodor Jagor', 'Sanchez', 'Santa Cruz in order to visit', 'Prayed at the college chapel']) {
        expect(looksLikeCategory(t), isFalse, reason: t);
      }
    });

    test('bullets unless the notes numbered the points', () {
      expect(formatList(['A one', 'B two'], bullets: true), '• A one\n• B two');
      expect(formatList(['A one', 'B two']), '1. A one\n2. B two');
    });

    test('a lone name, language or date with a line below is not a card', () {
      const t = 'Sanchez\nHe won five medals at the end of the school term and was proud of it.\nJune 1876\nHe obtained the highest grades in all subjects that year at school.\n';
      expect(extractDefinitions(t), isEmpty);
    });
  });

  group('usableTerms', () {
    Definition d(String term, String definition) => (term: term, definition: definition);

    // Slides as the app reads a PDF: a page is an empty line apart, bullets start with a dash.
    const slides = 'Intended Learning Outcomes\n- Understand how to protect Intellectual Property;\n- Explain the factors in fair use.\n\n'
        'Patents\n- A patent permits its owner to exclude the public from making, using, or selling a protected invention.\n\n'
        'CurrentIntellectualPropertyIssues\n- Plagiarism is the act of stealing someone\u2019s ideas or words and passing them off as one\u2019s own.\n\n'
        'GeneralAgreementonTariffsandTrade\n- The General Agreement on Tariffs and Trade (GATT) was a multilateral agreement governing international trade.\n\n'
        'Trade secret\n- Information used in business\n- Generally unknown to the public\n';

    test('keeps real terms', () {
      final kept = usableTerms([
        d('Trade secret', 'Information used in business - Generally unknown to the public'),
        d('Acceptable Use Policy (AUP)', 'A document that stipulates restrictions and practices that a user must agree to.'),
        d('COPPA', 'Was implemented in 1998 to give parents control over the information collected from children.'),
        d('Breach of the duty of care', 'The failure to act as a reasonable person would act.'),
        d('Negligence', 'Has been defined as not doing something that a reasonable person would do.'),
      ]);
      expect(kept.map((t) => t.term), ['Trade secret', 'Acceptable Use Policy (AUP)', 'COPPA', 'Breach of the duty of care', 'Negligence']);
    });

    test('drops course headings, tips and instructions', () {
      final kept = usableTerms([
        d('Intended Learning Outcomes', 'Understand how to protect Intellectual Property; explain the factors in fair use.'),
        d('Module 3', 'Intellectual property and privacy in the digital age for the course.'),
        d('Ask for feedback', 'If you carry out a presentation, ask yourself how you think it went.'),
        d('Try active listening', 'A good communicator listens before speaking to the other person.'),
        d('Enroll in a course', 'To really become a better communicator, you should consider a course.'),
        d('Learn from others', 'If you look up to someone who has good communication skills, watch them.'),
        d('Develop good relationships with suppliers', 'Deal fairly with them - do not make unreasonable demands.'),
        d('Your choices', 'As an individual you decide not to open email with the unpleasant header.'),
      ]);
      expect(kept, isEmpty);
    });

    test('drops websites, fragments, colons, list numbers and a bare year', () {
      final kept = usableTerms([
        d('ThomasNet.com', 'An excellent source for identifying suppliers and sources for products.'),
        d('CORI (http://cori.missouri.edu/pages/ksearch.htm)', 'An online database of more than 690,000 contract documents.'),
        d('Here', 'The skills that employers mostly seek in new hires, ranked in order.'),
        d('Law', 'The CAN-SPAM Act - illegal to send commercial email with a false header.'),
        d('Profession is a calling that requires:', 'Specialized knowledge and long and intensive academic preparation.'),
        d('PrivacyProtectionandtheLaw(US) 3. Health Information', 'The use of electronic medical records and the subsequent interest.'),
        d('IEEE Code of Ethics 1912', 'First code adopted by AIEE, after 6 years of effort and review.'),
      ]);
      expect(kept, isEmpty);
    });

    test('a heading the PDF ran together is put right, using the words of the notes', () {
      final kept = usableTerms([
        d('GeneralAgreementonTariffsandTrade', 'The General Agreement on Tariffs and Trade (GATT) was a multilateral agreement.'),
        d('TheDigitalMillenniumCopyrightAct(1998)', 'The DMCA (Public Law 105-304) was signed into law in 1998 and implements two treaties.'),
      ], text: slides);
      expect(kept.map((t) => t.term), ['General Agreement on Tariffs and Trade', 'The Digital Millennium Copyright Act (1998)']);
    });

    test('a slide title is a term only if its own bullet is about it', () {
      final kept = usableTerms([
        d('Patents', 'A patent permits its owner to exclude the public from making, using, or selling a protected invention.'),
        d('CurrentIntellectualPropertyIssues', 'Plagiarism is the act of stealing someone\u2019s ideas or words and passing them off as one\u2019s own.'),
        d('Intended Learning Outcomes', 'Understand how to protect Intellectual Property; Explain the factors in fair use.'),
      ], text: slides);
      expect(kept.map((t) => t.term), ['Patents']);
    });

    test('the same title is a term when it is not a slide title: a heading in the middle of a slide', () {
      final kept = usableTerms([
        d('Trade secret', 'Information used in business - Generally unknown to the public'),
      ], text: slides);
      expect(kept.map((t) => t.term), ['Trade secret']); // no bullet words in common, but it is not a page heading
    });

    test('the end of a slide title that wrapped onto two lines is still a title', () {
      const wrapped = 'TheWorldIntellectualPropertyOrganization \nCopyrightTreaty(1996)\n- The World Intellectual Property Organization (WIPO), headquartered in Geneva, is an agency of the United Nations.\n\n'
          'Patents\n- A patent permits its owner to exclude the public from making, using, or selling a protected invention.\n\n'
          'Trade Secrets\n- Business information that is generally unknown to the public and kept confidential.\n';
      final kept = usableTerms([
        d('Copyright Treaty (1996)', 'The World Intellectual Property Organization (WIPO), headquartered in Geneva, is an agency of the United Nations.'),
      ], text: wrapped);
      expect(kept, isEmpty);
    });

    test('the same term twice is kept once, and nothing in is nothing out', () {
      final kept = usableTerms([
        d('Bribery', 'Providing money, property, or favors to someone in business to obtain an advantage.'),
        d('bribery', 'Providing money to someone in business to get an advantage over others.'),
      ]);
      expect(kept, hasLength(1));
      expect(usableTerms(const []), isEmpty);
    });

    test('an all-capitals short word is an acronym and stays; a short plain word does not', () {
      expect(usableTerms([d('AUP', 'A document that stipulates restrictions on how users may use resources.')]), hasLength(1));
      expect(usableTerms([d('Law', 'A document that stipulates restrictions on how users may use resources.')]), isEmpty);
    });
  });
}
