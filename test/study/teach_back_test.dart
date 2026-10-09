import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/domain/summary.dart';
import 'package:kodigno/study/teach_back.dart';

const _patent = 'A patent permits its owner to exclude the public from making, using, or selling a protected invention, and it allows for legal action against violators.';
const _utility = 'A utility patent is issued for the invention of a new and useful process, machine, or composition of matter.';
const _twenty = 'It generally permits its owner to exclude others from making the invention for up to twenty years from the date of filing.';
const _secret = 'A trade secret is business information that is generally unknown to the public and kept confidential.';

final _notes = [
  pageMarker(14),
  'Copyrights\n- A copyright is the exclusive right to distribute, display, perform, or reproduce an original work.',
  '',
  pageMarker(16),
  'Patents\n- $_patent\n- $_utility',
  '',
  pageMarker(17),
  '- $_twenty\n- It has required effort or cost to develop,',
  '',
  pageMarker(18),
  'Trade Secrets\n- $_secret',
].join('\n');

final _pages = parsePages(_notes);

SummarySection _section({String heading = 'Patents', List<String> points = const [], List<String> terms = const ['exclude others', 'invention']}) =>
    SummarySection(heading: heading, explanation: 'A patent protects an invention.', keyPoints: points, terms: terms);

LessonSummary _lesson(SummarySection s) => LessonSummary(sections: [s]).withSources(SourceLocator(_pages));

List<Idea> _ideas() => ideasOf(_section(), _lesson(_section()), _pages);

TeachBackResult _check(String answer, {List<Idea>? ideas, List<String> terms = const ['exclude others', 'invention']}) =>
    checkTeachBack(answer: answer, ideas: ideas ?? _ideas(), sourceText: '$_patent\n$_utility\n$_twenty', terms: terms);

void main() {
  group('small helpers', () {
    test('wordCount counts words, numbers and contractions, not punctuation', () {
      expect(wordCount('A patent, for 20 years -- isn’t it?'), 7);
      expect(wordCount(''), 0);
      expect(wordCount('...'), 0);
    });

    test('splitSentences splits at full stops and line breaks, and keeps a last sentence with no stop', () {
      expect(splitSentences('One thing. Another thing! A third\nand a fourth without a stop'),
          ['One thing.', 'Another thing!', 'A third', 'and a fourth without a stop']);
      expect(splitSentences('   '), isEmpty);
      expect(splitSentences('Dr. Rizal wrote it.'), ['Dr.', 'Rizal wrote it.']); // a known limit, harmless here
    });
  });

  group('the ideas of a topic', () {
    test('come from the slides under the topic\'s heading, not from the summary\'s wording', () {
      final ideas = _ideas();
      expect(ideas.map((i) => i.text), containsAll([_patent, _utility]));
      expect(ideas.every((i) => i.source != null && i.source!.kind == SourceKind.copied), isTrue);
      expect(ideas.first.source!.page, 16);
    });

    test('a page that carries on the topic (no heading of its own) belongs to it, and the next heading ends it', () {
      final ideas = _ideas();
      expect(ideas.any((i) => i.text == _twenty && i.source!.page == 17), isTrue);
      expect(ideas.any((i) => i.text.contains('trade secret')), isFalse); // that is the next topic
    });

    test('a fragment that trails off with a comma is not an idea', () {
      expect(_ideas().any((i) => i.text.startsWith('It has required effort')), isFalse);
    });

    test('a heading the PDF stuck to the front of a line is taken off', () {
      final glued = parsePages([
        pageMarker(5),
        'Privacy Protection and the Law (US)',
        '',
        pageMarker(6),
        'PrivacyProtectionandtheLaw(US) In addition, the government must get a court order before it can read private messages.\n'
            '- The act protects the records of customers from unauthorized scrutiny by the government.',
      ].join('\n'));
      final s = _section(heading: 'Privacy Protection and the Law (US)', terms: const ['records']);
      final ideas = ideasOf(s, LessonSummary(sections: [s]), glued);
      expect(ideas.map((i) => i.text), contains('In addition, the government must get a court order before it can read private messages.'));
      expect(ideas.any((i) => i.text.contains('PrivacyProtection')), isFalse);
    });

    test('a topic that is one part of a long one uses only the pages its material came from', () {
      final deck = parsePages([
        for (var n = 1; n <= 6; n++)
          '${pageMarker(n)}\n${n == 1 ? 'Privacy Law\n' : ''}- Statute number $n protects a different kind of record held by the government agencies and banks.',
      ].join('\n'));
      final s = SummarySection(
        heading: 'Privacy Law (2 of 2)',
        explanation: 'Statute number 5 protects a different kind of record held by the government agencies and banks.',
        keyPoints: const ['Statute number 6 protects a different kind of record held by the government agencies and banks.'],
      );
      final lesson = LessonSummary(sections: [s]).withSources(SourceLocator(deck));
      expect(pagesOfTopic(s, lesson, deck), {5, 6});
    });

    test('a joined or model-named topic uses the pages its material came from', () {
      final s = _section(heading: 'Patents and trade secrets compared');
      final lesson = LessonSummary(sections: [SummarySection(heading: s.heading, explanation: _patent, keyPoints: [_secret])]).withSources(SourceLocator(_pages));
      expect(pagesOfTopic(lesson.sections.single, lesson, _pages), {16, 18});
    });

    test('with no pages (a Word file) they are the lesson\'s key points', () {
      final s = SummarySection(
        heading: 'Patents',
        explanation: 'A patent protects an invention for a number of years.',
        keyPoints: const ['A patent lets the owner stop others from selling the invention.', 'Patents last for up to twenty years.'],
      );
      final ideas = ideasOf(s, LessonSummary(sections: [s]));
      expect(ideas.map((i) => i.text), s.keyPoints);
      expect(ideas.every((i) => i.source == null), isTrue);
    });

    test('with too few key points, sentences of the explanation fill in; with nothing, there are none', () {
      const s = SummarySection(heading: 'X', explanation: 'First idea is explained here in full. Second idea follows right after it.');
      expect(ideasOf(s, const LessonSummary(sections: [s])), hasLength(2));
      const empty = SummarySection(heading: 'X', explanation: '');
      expect(ideasOf(empty, const LessonSummary(sections: [empty])), isEmpty);
    });

    test('there are never more than the maximum', () {
      final many = parsePages('${pageMarker(1)}\nTopic\n${[for (var i = 0; i < 12; i++) '- Sentence number $i is about the topic and says something quite different about item $i.'].join('\n')}');
      final s = SummarySection(heading: 'Topic', explanation: '', terms: const ['topic']);
      expect(ideasOf(s, LessonSummary(sections: [s]), many).length, lessThanOrEqualTo(maxIdeas));
    });

    test('the source text is the topic\'s pages, or the lesson\'s own text without pages', () {
      final s = _section();
      final text = sourceTextOf(s, _lesson(s), _pages);
      expect(text, contains(_patent));
      expect(text, contains(_twenty));
      expect(text, isNot(contains('trade secret')));
      const w = SummarySection(heading: 'X', explanation: 'An explanation here.', keyPoints: ['A point here.'], facts: ['A fact in 1999.']);
      expect(sourceTextOf(w, const LessonSummary(sections: [w]), const []), 'An explanation here.\nA point here.\nA fact in 1999.');
    });
  });

  group('checking an explanation', () {
    test('a good explanation in the student\'s own words covers the ideas, fully or partly', () {
      final r = _check(
          'A patent gives the owner the right to stop other people from making, using or selling their invention, and they can take legal action against violators. '
          'A utility patent covers new and useful processes, machines or compositions of matter. It usually lasts up to twenty years from when you file for it.');
      expect(r.copied, isFalse);
      expect(r.ideas[0].coverage, Coverage.covered);
      expect(r.ideas[1].coverage, Coverage.covered);
      expect(r.ideas[2].coverage, isNot(Coverage.missing)); // the twenty years: partly, at least
      expect(r.covered, greaterThanOrEqualTo(2));
      expect(r.flags, isEmpty);
      expect(r.headline, startsWith('You covered'));
    });

    test('an answer about something else finds none of the ideas', () {
      final r = _check('Privacy is about keeping personal information hidden from other people, like your email and the files on your computer.');
      expect(r.covered + r.partly, 0);
      expect(r.headline, 'I could not find any of the ${r.total} ideas yet.');
      expect(r.ideas.every((i) => i.matched == null), isTrue);
    });

    test('a covered idea says which sentence covered it', () {
      final r = _check('A patent lets the owner stop anyone else from making or selling the invention. Something else entirely follows here.');
      expect(r.ideas.first.matched, startsWith('A patent lets the owner'));
    });

    test('an answer lifted from the slides is called a copy, in its headline', () {
      final r = _check('$_patent $_utility');
      expect(r.copied, isTrue);
      expect(r.headline, 'Mostly copied from the slides. Try again in your own words.');
    });

    test('a short answer is not called a copy', () {
      expect(_check('A patent permits its owner').copied, isFalse);
    });

    test('a sentence that says the opposite is flagged, with the slide line it may contradict, worded as a check', () {
      final r = _check('A patent does not let the owner exclude the public from making, using, or selling the invention, so anyone can copy it.');
      final f = r.flags.singleWhere((f) => f.kind == FlagKind.opposite);
      expect(f.detail, _patent);
      expect(f.message, startsWith('This might not match your slides.'));
      expect(f.message, isNot(contains('wrong')));
    });

    test('"without" and similar words are not a negation: no false accusation', () {
      final r = _check('A patent protects an invention and stops other people from selling it without asking the owner.');
      expect(r.flags.where((f) => f.kind == FlagKind.opposite), isEmpty);
    });

    test('a number the slides do not have is flagged, and one they have is not', () {
      expect(_check('A patent gives its owner the right to exclude others from making the invention for 50 years after filing.').flags.map((f) => f.detail), contains('50'));
      expect(_check('A patent lets the owner exclude others from making the invention for up to 20 years after filing.').flags.where((f) => f.kind == FlagKind.number).map((f) => f.detail), ['20']);
      // "twenty" in words is in the slides, but this is a digit the slides never wrote: it is still a number to check
      expect(_check('A patent gives its owner the right to exclude others from making the invention for twenty years.').flags, isEmpty);
    });

    test('a name the slides do not have is flagged', () {
      final r = _check('A patent permits its owner to exclude others from making the invention, and it is granted by the Philippine Congress.');
      expect(r.flags.where((f) => f.kind == FlagKind.name).map((f) => f.detail), containsAll(['Philippine', 'Congress']));
      expect(r.flags.firstWhere((f) => f.kind == FlagKind.name).message, endsWith('Check it.'));
    });

    test('words of the slides about the topic that were not used are suggested, at most three', () {
      final r = _check('A patent protects something that somebody made and keeps it safe from the rest of the world.', terms: const ['exclude others', 'invention', 'permits', 'violators', 'utility patent']);
      expect(r.missingTerms.length, lessThanOrEqualTo(3));
      expect(r.missingTerms, contains('exclude others'));
      final used = _check('A patent owner can exclude others from copying the invention.', terms: const ['exclude others']);
      expect(used.missingTerms, isEmpty);
    });

    test('terms that are not about the ideas are not suggested', () {
      final r = _check('Something short and unrelated that goes nowhere at all.', terms: const ['volcano eruption']);
      expect(r.missingTerms, isEmpty);
    });

    test('a few distinct flags at most, and the same one is not repeated', () {
      final r = _check('The patent lasts 50 years. A patent lasts 50 years too. Congress, Senate, Parliament and Cabinet all grant a patent in 1999 and 2001.');
      expect(r.flags.length, lessThanOrEqualTo(4));
      expect(r.flags.where((f) => f.detail == '50'), hasLength(1));
    });

    test('with no ideas there is nothing to compare, and nothing breaks', () {
      final r = checkTeachBack(answer: 'A patent protects an invention for a long time.', ideas: const [], sourceText: _patent);
      expect(r.headline, 'Nothing to compare with.');
      expect(r.total, 0);
      expect(checkTeachBack(answer: '', ideas: _ideas(), sourceText: _patent).covered, 0);
    });

    test('the same answer always gives the same result', () {
      const a = 'A patent lets the owner stop others from selling the invention for twenty years.';
      expect(_check(a).headline, _check(a).headline);
      expect([for (final i in _check(a).ideas) i.score], [for (final i in _check(a).ideas) i.score]);
    });
  });

  group('the headline counts, never grades', () {
    IdeaResult r(Coverage c) => IdeaResult(const Idea('Some idea here'), coverage: c, score: 0);
    TeachBackResult res(List<Coverage> cs, {bool copied = false}) =>
        TeachBackResult(ideas: [for (final c in cs) r(c)], missingTerms: const [], flags: const [], copied: copied, words: 20);

    test('all, some, partly, none', () {
      expect(res([Coverage.covered, Coverage.covered]).headline, 'You covered all 2 ideas.');
      expect(res([Coverage.covered, Coverage.missing, Coverage.missing]).headline, 'You covered 1 of 3 ideas.');
      expect(res([Coverage.covered, Coverage.partly, Coverage.missing]).headline, 'You covered 1 of 3 ideas, and 1 partly.');
      expect(res([Coverage.partly, Coverage.missing]).headline, 'You covered 0 of 2 ideas, and 1 partly.');
      expect(res([Coverage.missing, Coverage.missing]).headline, 'I could not find any of the 2 ideas yet.');
      expect(res([Coverage.covered], copied: true).headline, contains('copied'));
    });
  });
}
