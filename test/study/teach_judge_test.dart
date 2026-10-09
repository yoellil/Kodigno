import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/study/teach_back.dart';
import 'package:kodigno/study/teach_judge.dart';

const _slides = 'A patent permits its owner to exclude the public from making, using, or selling a protected invention, and it allows for legal action against violators.\n'
    'A utility patent is issued for the invention of a new and useful process, machine, or composition of matter.\n'
    'It generally permits its owner to exclude others for up to twenty years from the date of filing.\n'
    'A design patent protects a new, original, and ornamental design of an article.';

String _json(Object o) => jsonEncode(o);

const _c1 = 'A patent lets the owner stop the public from making, using, or selling a protected invention.';
const _c2 = 'A utility patent covers a new and useful process, machine, or composition of matter.';
const _c3 = 'A design patent protects an ornamental design of an article.';

const _answer = 'A patent gives the owner the right to stop other people from making, using or selling their invention. '
    'It usually lasts up to twenty years from when you file for it. A design patent covers how a thing looks.';

void main() {
  group('the prompts', () {
    test('the key ideas prompt carries the slides and the topic, and asks for slide-backed plain sentences', () {
      final p = buildConceptsPrompt(_slides, topic: 'Patents');
      expect(p, contains('TOPIC: Patents'));
      expect(p, contains(_slides));
      expect(p, contains('Never add facts, names, dates or numbers that are not in them'));
      expect(buildConceptsPrompt(_slides), isNot(contains('TOPIC:')));
    });

    test('the judge prompt numbers the ideas and asks for the student\'s exact words as evidence', () {
      final p = buildJudgePrompt(concepts: const [_c1, _c2], answer: _answer, slideText: _slides);
      expect(p, contains('1. $_c1'));
      expect(p, contains('2. $_c2'));
      expect(p, contains("STUDENT'S EXPLANATION:\n$_answer"));
      expect(p, contains('exact words copied from the student'));
      expect(p, contains('Never give credit for an idea the student did not write'));
    });

    test('the schemas fit the number of ideas', () {
      final s = judgeSchema(3);
      final ideas = (s['properties']! as Map)['ideas'] as Map;
      expect(ideas['minItems'], 3);
      expect(ideas['maxItems'], 3);
      final c = (conceptsSchema()['properties']! as Map)['concepts'] as Map;
      expect(c['minItems'], 2);
      expect(c['maxItems'], 4);
    });
  });

  group('parseConcepts', () {
    test('keeps ideas that the slides back up', () {
      final c = parseConcepts(_json({'concepts': [_c1, _c2, _c3]}), _slides);
      expect(c, [_c1, _c2, _c3]);
    });

    test('drops a heading or a fragment, and an idea the slides do not back', () {
      final c = parseConcepts(
          _json({
            'concepts': [
              'Patents.',
              'Volcanoes erupt when magma rises through cracks in the crust of the planet.',
              _c1,
            ],
          }),
          _slides);
      expect(c, [_c1]);
    });

    test('drops an invented year, figure or name', () {
      final c = parseConcepts(
          _json({
            'concepts': [
              'A patent permits its owner to exclude others for up to 50 years from the date of filing.',
              'A patent permits its owner to exclude others, and it is granted by the Philippine Congress.',
              _c1,
            ],
          }),
          _slides);
      expect(c, [_c1]);
    });

    test('keeps one of two ideas that say the same thing, and at most four', () {
      final c = parseConcepts(
          _json({
            'concepts': [
              _c1,
              'A patent lets its owner stop the public from making, using, or selling a protected invention.',
              _c2,
              _c3,
              'A patent allows legal action against violators of the protected invention.',
              'It generally permits its owner to exclude others for up to twenty years from the filing date.',
            ],
          }),
          _slides);
      expect(c.length, lessThanOrEqualTo(4));
      expect(c.where((x) => x.contains('stop the public')).length, 1);
    });

    test('echoed placeholders are stripped, and spaces are tidied', () {
      final c = parseConcepts(_json({'concepts': ['  A patent   lets the owner stop the public <idea> from making, using, or selling a protected invention.  ']}), _slides);
      expect(c.single, 'A patent lets the owner stop the public from making, using, or selling a protected invention.');
    });

    test('output that is not what was asked for is a format error', () {
      expect(() => parseConcepts('not json at all', _slides), throwsFormatException);
      expect(() => parseConcepts('{"other": 1}', _slides), throwsFormatException);
      expect(() => parseConcepts('{"concepts": "a string"}', _slides), throwsFormatException);
      expect(parseConcepts('Here you go: ${_json({'concepts': [_c1]})} thanks', _slides), [_c1]); // text around it is fine
      expect(parseConcepts(_json({'concepts': [1, null, _c1]}), _slides), [_c1]);
    });
  });

  group('quoteIn', () {
    test('finds words that are really there, whatever the capitals, punctuation or spacing', () {
      expect(quoteIn('stop other people from making, using or selling', _answer), isTrue);
      expect(quoteIn('STOP   OTHER people from MAKING using or selling!', _answer), isTrue);
    });

    test('allows a small word or comma dropped in copying, but not words that are not there', () {
      expect(quoteIn('the right to stop other people from making using or selling their inventions', _answer), isTrue);
      expect(quoteIn('a patent protects books and music for the whole life of the author', _answer), isFalse);
    });

    test('a very short quote counts for nothing', () {
      expect(quoteIn('patent', _answer), isFalse);
      expect(quoteIn('', _answer), isFalse);
    });
  });

  group('parseJudgement', () {
    String judged(List<Map<String, String>> ideas, [List<Map<String, String>> opposites = const []]) =>
        _json({'ideas': ideas, 'opposites': opposites});

    TeachBackJudgement parse(String raw, {int n = 3, String answer = _answer}) =>
        parseJudgement(raw, conceptCount: n, answer: answer, slideText: _slides);

    test('a verdict with real evidence is kept', () {
      final j = parse(judged([
        {'verdict': 'yes', 'evidence': 'stop other people from making, using or selling their invention'},
        {'verdict': 'partly', 'evidence': 'It usually lasts up to twenty years'},
        {'verdict': 'no', 'evidence': ''},
      ]));
      expect(j.concepts.map((c) => c.verdict), [Verdict.yes, Verdict.partly, Verdict.no]);
      expect(j.concepts.first.evidence, startsWith('stop other people'));
      expect(j.concepts.last.evidence, '');
    });

    test('a "yes" whose evidence is not in the explanation is thrown away: nothing is credited without proof', () {
      final j = parse(judged([
        {'verdict': 'yes', 'evidence': 'a patent protects books and music for the whole life of the author'},
        {'verdict': 'yes', 'evidence': ''},
        {'verdict': 'no', 'evidence': ''},
      ]));
      expect(j.concepts.map((c) => c.verdict), [null, null, Verdict.no]);
    });

    test('evidence of fewer than four words is not evidence', () {
      final j = parse(judged([
        {'verdict': 'yes', 'evidence': 'a patent gives'},
        {'verdict': 'no', 'evidence': ''},
        {'verdict': 'no', 'evidence': ''},
      ]));
      expect(j.concepts.first.verdict, isNull);
    });

    test('one quote cannot show three different ideas', () {
      const q = 'stop other people from making, using or selling their invention';
      final j = parse(judged([
        {'verdict': 'yes', 'evidence': q},
        {'verdict': 'yes', 'evidence': q},
        {'verdict': 'partly', 'evidence': q},
      ]));
      expect(j.concepts.every((c) => c.verdict == null), isTrue);
      final two = parse(judged([
        {'verdict': 'yes', 'evidence': q},
        {'verdict': 'yes', 'evidence': q},
        {'verdict': 'no', 'evidence': ''},
      ]));
      expect(two.concepts.take(2).every((c) => c.verdict == Verdict.yes), isTrue); // twice is fine
    });

    test('an unknown verdict is dropped', () {
      final j = parse(judged([
        {'verdict': 'maybe', 'evidence': 'stop other people from making, using or selling'},
        {'verdict': 'no', 'evidence': ''},
        {'verdict': 'no', 'evidence': ''},
      ]));
      expect(j.concepts.first.verdict, isNull);
    });

    test('the wrong number of ideas, or no JSON, is a format error', () {
      expect(() => parse(judged([{'verdict': 'no', 'evidence': ''}])), throwsFormatException);
      expect(() => parse('nonsense'), throwsFormatException);
      expect(() => parse(_json({'ideas': 'x', 'opposites': []})), throwsFormatException);
    });

    group('opposites', () {
      const said = 'A patent does not let the owner exclude the public from making, using, or selling the invention.';
      const answer = '$said Anyone can copy it.';

      test('are kept only if the student said it, the slides say the other, they are about the same thing and one has a "not"', () {
        final j = parse(
          judged([
            {'verdict': 'no', 'evidence': ''}, {'verdict': 'no', 'evidence': ''}, {'verdict': 'no', 'evidence': ''},
          ], [
            {'said': said, 'slides': 'A patent permits its owner to exclude the public from making, using, or selling a protected invention'},
          ]),
          answer: answer,
        );
        expect(j.opposites, hasLength(1));
        expect(j.opposites.single.said, said);
      });

      test('are dropped if the student did not say it, or the slides do not', () {
        const slide = 'A patent permits its owner to exclude the public from making, using, or selling a protected invention';
        expect(
            parse(judged([for (var i = 0; i < 3; i++) {'verdict': 'no', 'evidence': ''}], [{'said': 'A patent never lets anybody exclude the public from using an invention at all.', 'slides': slide}]), answer: answer).opposites,
            isEmpty);
        expect(
            parse(judged([for (var i = 0; i < 3; i++) {'verdict': 'no', 'evidence': ''}], [{'said': said, 'slides': 'Slides that nobody ever wrote about patents exclude the public'}]), answer: answer).opposites,
            isEmpty);
      });

      test('are dropped if neither has a "not": a different way of saying it is not the opposite', () {
        const same = 'A patent allows the owner to keep the public from making, using, or selling the invention.';
        final j = parse(
          judged([for (var i = 0; i < 3; i++) {'verdict': 'no', 'evidence': ''}], [
            {'said': same, 'slides': 'A patent permits its owner to exclude the public from making, using, or selling a protected invention'},
          ]),
          answer: '$same And more.',
        );
        expect(j.opposites, isEmpty);
      });

      test('are dropped if they are about different things, and at most two are kept', () {
        final j = parse(
          judged([for (var i = 0; i < 3; i++) {'verdict': 'no', 'evidence': ''}], [
            {'said': 'Privacy does not mean hiding personal files from other people.', 'slides': 'A patent permits its owner to exclude the public from making, using, or selling a protected invention'},
          ]),
          answer: 'Privacy does not mean hiding personal files from other people. Something else.',
        );
        expect(j.opposites, isEmpty);
        final many = parse(
          judged([for (var i = 0; i < 3; i++) {'verdict': 'no', 'evidence': ''}], [
            for (var i = 0; i < 4; i++)
              {'said': said, 'slides': 'A patent permits its owner to exclude the public from making, using, or selling a protected invention'},
          ]),
          answer: answer,
        );
        expect(many.opposites.length, lessThanOrEqualTo(2));
      });
    });
  });

  group('combineWithModel', () {
    IdeaResult idea(Coverage c, {String? matched}) =>
        IdeaResult(const Idea('An idea of the topic, in plain words'), coverage: c, score: 0.2, matched: matched);
    TeachBackResult words(List<Coverage> cs, {List<Flag> flags = const [], bool copied = false}) => TeachBackResult(
          ideas: [for (final c in cs) idea(c, matched: c == Coverage.missing ? null : 'A word match')],
          missingTerms: const ['invention'],
          flags: flags,
          copied: copied,
          words: 25,
        );
    TeachBackJudgement said(List<Verdict?> vs, {List<Opposite> opposites = const []}) =>
        TeachBackJudgement([for (final v in vs) ConceptVerdict(v, v == null || v == Verdict.no ? '' : 'The student’s own words')], opposites);

    test('yes is covered and partly is partly, whatever the words found', () {
      final r = combineWithModel(words([Coverage.missing, Coverage.missing]), said([Verdict.yes, Verdict.partly]));
      expect(r.ideas.map((i) => i.coverage), [Coverage.covered, Coverage.partly]);
      expect(r.checkedBy, CheckedBy.model);
    });

    test('no is missing, unless the words found it covered: then the two disagree, so it is partly', () {
      final r = combineWithModel(
          words([Coverage.missing, Coverage.partly, Coverage.covered]), said([Verdict.no, Verdict.no, Verdict.no]));
      expect(r.ideas.map((i) => i.coverage), [Coverage.missing, Coverage.missing, Coverage.partly]);
    });

    test('an idea the model gave no usable verdict for keeps the words\' result', () {
      final r = combineWithModel(words([Coverage.covered, Coverage.partly, Coverage.missing]), said([null, null, null]));
      expect(r.ideas.map((i) => i.coverage), [Coverage.covered, Coverage.partly, Coverage.missing]);
    });

    test('the model\'s evidence is what is shown for an idea it credits; for the rest, the words\' sentence', () {
      final r = combineWithModel(words([Coverage.partly, Coverage.partly, Coverage.partly]), said([Verdict.yes, null, Verdict.no]));
      expect(r.ideas[0].matched, 'The student’s own words');
      expect(r.ideas[1].matched, 'A word match');
      expect(r.ideas[2].coverage, Coverage.missing);
      expect(r.ideas[2].matched, isNull);
    });

    test('opposites the model found are flagged first, with the words\' flags after, no repeats, at most four', () {
      const same = Flag(FlagKind.number, 'Sentence.', '50');
      final r = combineWithModel(
        words([Coverage.missing], flags: [same, const Flag(FlagKind.name, 'Sentence.', 'Congress'), const Flag(FlagKind.name, 'Sentence.', 'Senate'), const Flag(FlagKind.name, 'Sentence.', 'Cabinet')]),
        said([Verdict.no], opposites: const [Opposite('A patent does not let anyone exclude.', 'A patent permits its owner to exclude.')]),
      );
      expect(r.flags.first.kind, FlagKind.opposite);
      expect(r.flags.first.sentence, 'A patent does not let anyone exclude.');
      expect(r.flags.first.detail, 'A patent permits its owner to exclude.');
      expect(r.flags.length, 4);
    });

    test('what the words found about copying, length and terms is kept', () {
      final r = combineWithModel(words([Coverage.covered], copied: true), said([Verdict.yes]));
      expect(r.copied, isTrue);
      expect(r.words, 25);
      expect(r.missingTerms, ['invention']);
      expect(r.headline, startsWith('Mostly copied'));
    });

    test('a judgement about a different number of ideas is not used', () {
      final w = words([Coverage.partly, Coverage.missing]);
      final r = combineWithModel(w, said([Verdict.yes]));
      expect(identical(r, w), isTrue);
      expect(r.checkedBy, CheckedBy.words);
    });
  });
}
