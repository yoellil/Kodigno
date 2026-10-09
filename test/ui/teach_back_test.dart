import 'package:drift/native.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/data/teach_back_repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/domain/summary.dart';
import 'package:kodigno/study/teach_judge.dart';
import 'package:kodigno/ui/set_detail_screen.dart';
import 'package:kodigno/ui/summary_screen.dart';
import 'package:kodigno/ui/teach_back_screen.dart';
import 'package:kodigno/ui/theme.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await t.pump(const Duration(milliseconds: 70));
  }
}

const _patent = 'A patent permits its owner to exclude the public from making, using, or selling a protected invention, and it allows for legal action against violators.';
const _utility = 'A utility patent is issued for the invention of a new and useful process, machine, or composition of matter.';
const _twenty = 'It generally permits its owner to exclude others from making the invention for up to twenty years from the date of filing.';
const _copyright = 'A copyright is the exclusive right to distribute, display, perform, or reproduce an original work in any form.';

final _notes = [
  pageMarker(14),
  'Copyrights\n- $_copyright',
  '',
  pageMarker(16),
  'Patents\n- $_patent\n- $_utility\n- $_twenty',
].join('\n');

LessonSummary _lesson() => const LessonSummary(
      overview: 'About intellectual property.',
      sections: [
        SummarySection(heading: 'Copyrights', explanation: 'A copyright protects an original work.', keyPoints: ['Copyright protects an original work'], terms: ['original work']),
        SummarySection(heading: 'Patents', explanation: 'A patent protects an invention.', keyPoints: ['A patent protects an invention for years'], terms: ['exclude others', 'invention']),
      ],
      takeaways: ['IP protects creators.'],
    ).withSources(SourceLocator(parsePages(_notes)));

class _Env {
  _Env(this.db, this.repo, this.setId);
  final AppDatabase db;
  final StudyRepository repo;
  final int setId;
}

Future<_Env> _env(WidgetTester t, {bool withLesson = true, String? notes, LessonSummary? lesson}) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1000, 1500);
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() => t.runAsync(db.close));
  final repo = StudyRepository(db);
  final id = (await t.runAsync(() => repo.saveSet('Module 3', const GeneratedSet([], []),
      sourceType: 'pdf', sourceText: notes ?? _notes, sourcePaths: ['C:/none.pdf'], summary: withLesson ? (lesson ?? _lesson()) : null)))!;
  return _Env(db, repo, id);
}

Future<void> _open(WidgetTester t, Widget home) async {
  await t.pumpWidget(MaterialApp(theme: kTheme(), home: home));
  await settle(t);
}

Future<void> _write(WidgetTester t, String text) async {
  await t.enterText(find.byType(TextField), text);
  await t.pump();
}

Future<List<TeachBackAttempt>> _saved(WidgetTester t, _Env e) async =>
    (await t.runAsync(() => e.db.select(e.db.teachBackAttempts).get()))!;

const _good = 'A patent gives the owner the right to stop other people from making, using or selling their invention, and they can take legal action against violators. '
    'A utility patent covers new and useful processes, machines or compositions of matter.';

/// A stand-in for the AI model: it writes the ideas and gives the judgement it is told to.
class _FakeModel implements TeachBackModel {
  _FakeModel({
    this.available = true,
    this.canJudge = true,
    this.ideas = const [],
    this.judgement,
    this.judgeGate,
    this.throwOnConcepts = false,
  });
  @override
  final bool available;
  @override
  final bool canJudge;
  final List<String> ideas;
  final TeachBackJudgement? judgement;
  final Completer<TeachBackJudgement?>? judgeGate;
  final bool throwOnConcepts;

  int conceptCalls = 0, judgeCalls = 0;
  String? lastAnswer, lastSlideText;

  @override
  Future<List<String>> concepts(String slideText, {String? topic}) async {
    conceptCalls++;
    if (throwOnConcepts) throw StateError('boom');
    return ideas;
  }

  @override
  Future<TeachBackJudgement?> judge({required List<String> concepts, required String answer, required String slideText}) async {
    judgeCalls++;
    lastAnswer = answer;
    lastSlideText = slideText;
    return judgeGate != null ? judgeGate!.future : judgement;
  }
}

void main() {
  group('writing', () {
    testWidgets('asks for an explanation, keeps the slides hidden, and waits for enough words', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      expect(find.text('Teach it back'), findsOneWidget);
      expect(find.text('BETA'), findsOneWidget);
      expect(find.text('Patents'), findsOneWidget);
      expect(find.textContaining('in your own words'), findsOneWidget);
      expect(find.textContaining('Your slides stay hidden'), findsOneWidget);
      expect(find.textContaining('permits its owner to exclude'), findsNothing); // the slides' words are not shown yet

      expect(find.textContaining('0 words. Write a little more first'), findsOneWidget);
      await _write(t, 'A patent protects things');
      expect(find.textContaining('4 words. Write a little more first (at least 8)'), findsOneWidget);
      await t.tap(find.text('Check my explanation'), warnIfMissed: false);
      await settle(t);
      expect(find.textContaining('THE IDEAS IN YOUR SLIDES'), findsNothing); // too short: no check

      await _write(t, 'A patent protects an invention from being copied by others');
      expect(find.text('10 words'), findsOneWidget);
    });
  });

  group('the check', () {
    testWidgets('a good explanation: the headline, the ideas with their slides, and the try is kept', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      await _write(t, _good);
      await t.tap(find.text('Check my explanation'));
      await settle(t);

      expect(find.textContaining('You covered'), findsWidgets);
      expect(find.text('THE IDEAS IN YOUR SLIDES'), findsOneWidget);
      expect(find.textContaining('permits its owner to exclude the public'), findsOneWidget); // now the slides show
      expect(find.text('Slide 16'), findsWidgets); // each idea says where it is
      expect(find.text('COVERED'), findsWidgets);
      expect(find.textContaining('compares words'), findsOneWidget);
      expect(find.text('WORTH A SECOND LOOK'), findsNothing);

      final saved = await _saved(t, e);
      expect(saved, hasLength(1));
      expect(saved.single.section, 'Patents');
      expect(saved.single.answer, _good);
      expect(saved.single.covered, greaterThanOrEqualTo(2));
      expect(t.takeException(), isNull);
    });

    testWidgets('an answer copied from the slides is called a copy', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      await _write(t, '$_patent $_utility');
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      expect(find.text('Mostly copied from the slides. Try again in your own words.'), findsOneWidget);
      expect((await _saved(t, e)).single.copied, isTrue);
    });

    testWidgets('an answer about something else finds nothing', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      await _write(t, 'Privacy is about keeping personal information hidden from other people and from the public at large.');
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      expect(find.textContaining('I could not find any of the'), findsOneWidget);
      expect(find.text('NOT FOUND'), findsWidgets);
    });

    testWidgets('a sentence that may say the opposite is shown as something to check, not as wrong', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      await _write(t, 'A patent does not let the owner exclude the public from making, using, or selling the invention, so anyone can copy it.');
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      expect(find.text('WORTH A SECOND LOOK'), findsOneWidget);
      expect(find.textContaining('This might not match your slides.'), findsOneWidget);
      expect(find.textContaining('wrong'), findsNothing);
    });

    testWidgets('a number or a name the slides do not have is flagged', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      await _write(t, 'A patent lets its owner exclude others from making the invention for 50 years, and it is granted by the Philippine Congress.');
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      expect(find.text('Your slides do not have the number 50. Check it.'), findsOneWidget);
      expect(find.text('Your slides do not mention Philippine. Check it.'), findsOneWidget);
    });

    testWidgets('Try again goes back to writing with the text kept', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      await _write(t, _good);
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      await t.tap(find.text('Try again'));
      await t.pump();
      expect(find.text('Check my explanation'), findsOneWidget);
      expect(find.text(_good), findsOneWidget); // still in the box
      expect(find.text('THE IDEAS IN YOUR SLIDES'), findsNothing);
    });
  });

  group('"I covered this"', () {
    testWidgets('moves an idea to covered, says so, and keeps it', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      await _write(t, 'Privacy is about keeping personal information hidden from other people and from the public at large.');
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      expect(find.text('I covered this'), findsWidgets);
      await t.ensureVisible(find.text('I covered this').first);
      await t.tap(find.text('I covered this').first);
      await settle(t);
      expect(find.text('YOU SAID YOU COVERED THIS'), findsOneWidget);
      expect(find.textContaining('With the 1 you said you covered: 1 of'), findsOneWidget);
      final saved = (await _saved(t, e)).single;
      expect(saved.overruledIdeas, [0]);
    });

    testWidgets('tapping it for the same idea twice counts once', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      await _write(t, 'Privacy is about keeping personal information hidden from other people and from the public at large.');
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      await t.ensureVisible(find.text('I covered this').first);
      await t.tap(find.text('I covered this').first);
      await settle(t);
      expect(find.text('YOU SAID YOU COVERED THIS'), findsOneWidget); // it has no button now
      expect((await _saved(t, e)).single.overruledIdeas, hasLength(1));
    });
  });

  group('earlier tries', () {
    testWidgets('are listed with what was covered, newest first', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      expect(find.text('EARLIER TRIES AT THIS TOPIC'), findsNothing);
      await _write(t, 'Privacy is about keeping personal information hidden from other people and from the public at large.');
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      await t.tap(find.text('Try again'));
      await t.pump();
      await _write(t, _good);
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      await t.ensureVisible(find.text('EARLIER TRIES AT THIS TOPIC'));
      expect(find.text('EARLIER TRIES AT THIS TOPIC'), findsOneWidget);
      expect(find.textContaining('Covered 0 of'), findsOneWidget);
      expect(find.textContaining('Covered 2 of'), findsOneWidget);
    });
  });

  group('when there is nothing to check', () {
    testWidgets('a set with no lesson says so', (t) async {
      final e = await _env(t, withLesson: false);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 0));
      expect(find.text('No lesson yet'), findsOneWidget);
    });

    testWidgets('a topic with no slide text and no key points has nothing to compare with', (t) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => t.runAsync(db.close));
      t.view.devicePixelRatio = 1.0;
      t.view.physicalSize = const Size(1000, 1200);
      addTearDown(t.view.reset);
      final repo = StudyRepository(db);
      final id = (await t.runAsync(() => repo.saveSet('Bare', const GeneratedSet([], []),
          sourceText: 'Notes with no pages.', summary: const LessonSummary(sections: [SummarySection(heading: 'Empty', explanation: '')]))))!;
      await _open(t, TeachBackScreen(repo: repo, setId: id, sectionIndex: 0));
      expect(find.text('Nothing to compare with'), findsOneWidget);
    });

    testWidgets('a topic number that is not in the lesson says there is no lesson yet, and does not crash', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 9));
      expect(find.text('No lesson yet'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('a lesson without pages (a Word file) still works, from its key points', (t) async {
      // a lesson made from a Word file: no pages, so no slide numbers
      const plain = LessonSummary(sections: [
        SummarySection(heading: 'Copyrights', explanation: 'A copyright protects an original work.', keyPoints: ['Copyright protects an original work']),
        SummarySection(
            heading: 'Patents',
            explanation: 'A patent protects an invention for a number of years.',
            keyPoints: ['A patent protects an invention for a number of years', 'A patent lets the owner stop others from selling the invention']),
      ]);
      final e = await _env(t, notes: 'Plain notes with no pages at all.', lesson: plain);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1));
      await _write(t, 'A patent protects an invention for a number of years so that nobody else can sell it.');
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      expect(find.text('THE IDEAS IN YOUR SLIDES'), findsOneWidget);
      expect(find.text('Slide 16'), findsNothing); // no pages, no slide tags
      expect(t.takeException(), isNull);
    });
  });

  group('the topics list', () {
    testWidgets('shows each topic, and a try changes how it reads', (t) async {
      final e = await _env(t);
      await _open(t, TeachBackTopicsScreen(repo: e.repo, setId: e.setId));
      expect(find.text('Teach it back'), findsOneWidget);
      expect(find.text('Copyrights'), findsOneWidget);
      expect(find.text('Patents'), findsOneWidget);
      expect(find.text('Not tried yet'), findsNWidgets(2));

      await t.tap(find.text('Patents'));
      await settle(t);
      await _write(t, _good);
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      await t.tap(find.text('Done'));
      await settle(t);
      expect(find.text('Not tried yet'), findsOneWidget);
      expect(find.textContaining('Last try: covered'), findsOneWidget);
      expect(find.textContaining('· 1 try'), findsOneWidget);
    });

    testWidgets('a set with no lesson offers to open the summary', (t) async {
      final e = await _env(t, withLesson: false);
      await _open(t, TeachBackTopicsScreen(repo: e.repo, setId: e.setId));
      expect(find.textContaining('no lesson yet'), findsOneWidget);
      expect(find.text('Open summary'), findsOneWidget);
    });
  });

  group('with the AI model', () {
    const c1 = 'A patent lets the owner stop the public from making, using, or selling a protected invention.';
    const c2 = 'A utility patent covers a new and useful process, machine, or composition of matter.';
    const mine = 'If you come up with something new, the law lets you be the only one who can build it or sell it for roughly two decades, and you can take people to court if they copy you.';

    TeachBackJudgement judged(List<ConceptVerdict> v, {List<Opposite> opposites = const []}) => TeachBackJudgement(v, opposites);
    const yes = ConceptVerdict(Verdict.yes, 'you can take people to court if they copy you');
    const no = ConceptVerdict(Verdict.no, '');

    Future<void> check(WidgetTester t, _Env e, _FakeModel m, {String answer = mine, int section = 1}) async {
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: section, model: m));
      await _write(t, answer);
      await t.tap(find.text('Check my explanation'));
      await settle(t);
    }

    testWidgets('shows the model\'s key ideas and its verdicts, with what the student wrote, even in other words', (t) async {
      final e = await _env(t);
      final m = _FakeModel(ideas: const [c1, c2], judgement: judged([yes, no]));
      await check(t, e, m);

      expect(find.text(c1), findsOneWidget);
      expect(find.text(c2), findsOneWidget);
      expect(find.textContaining('permits its owner to exclude the public from making'), findsNothing); // not the slide line any more
      expect(find.text('You covered 1 of 2 ideas.'), findsOneWidget);
      expect(find.text('COVERED'), findsOneWidget); // although the student shared almost no words with the slides
      expect(find.text('NOT FOUND'), findsOneWidget);
      expect(find.text('You wrote: "you can take people to court if they copy you"'), findsOneWidget);
      expect(find.textContaining('Checked by the AI model, which read your slides and your explanation'), findsOneWidget);
      expect(find.textContaining('The AI model can be wrong too'), findsOneWidget);
      expect(m.judgeCalls, 1);
      expect(m.lastSlideText, contains('A patent permits its owner'));
      expect(m.lastAnswer, mine);
      expect((await _saved(t, e)).single.checkedBy, 'model');
    });

    testWidgets('the key ideas are written once and kept: a second try does not ask for them again', (t) async {
      final e = await _env(t);
      final m = _FakeModel(ideas: const [c1, c2], judgement: judged([yes, no]));
      await check(t, e, m);
      expect(m.conceptCalls, 1);
      final kept = await t.runAsync(() => TeachBackRepository(e.db).conceptsFor(e.setId, 'Patents'));
      expect(kept, [c1, c2]);

      await t.tap(find.text('Try again'));
      await t.pump();
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      expect(m.conceptCalls, 1); // the same ideas, from the saved copy
      expect(m.judgeCalls, 2);
      expect(find.text(c1), findsOneWidget);
    });

    testWidgets('each idea says which slide it is about, when it can be placed', (t) async {
      final e = await _env(t);
      final m = _FakeModel(ideas: const [c1, 'Quantum computers use qubits to explore many answers at the same time.'], judgement: judged([yes, no]));
      await check(t, e, m);
      expect(find.text('Slide 16'), findsOneWidget); // the patent idea; the other matches no slide, so no tag
    });

    testWidgets('while the model reads the explanation, a waiting message shows', (t) async {
      final e = await _env(t);
      final gate = Completer<TeachBackJudgement?>();
      final m = _FakeModel(ideas: const [c1, c2], judgeGate: gate);
      await _open(t, TeachBackScreen(repo: e.repo, setId: e.setId, sectionIndex: 1, model: m));
      await _write(t, mine);
      await t.tap(find.text('Check my explanation'));
      for (var i = 0; i < 6; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
        await t.pump(const Duration(milliseconds: 60));
      }
      expect(find.text('Reading your explanation...'), findsOneWidget);
      expect(find.text('Check my explanation'), findsNothing);
      gate.complete(judged([yes, no]));
      await settle(t);
      expect(find.text('Reading your explanation...'), findsNothing);
      expect(find.text('You covered 1 of 2 ideas.'), findsOneWidget);
    });

    testWidgets('a model too small to judge writes the ideas, but the words do the checking, and it says so', (t) async {
      final e = await _env(t);
      final m = _FakeModel(ideas: const [c1, c2], canJudge: false, judgement: judged([yes, yes]));
      await check(t, e, m);
      expect(find.text(c1), findsOneWidget);
      expect(find.textContaining('too small to judge your explanation'), findsOneWidget);
      expect(m.judgeCalls, 0);
      expect(find.text('You wrote: "you can take people to court if they copy you"'), findsNothing); // no model evidence
      expect((await _saved(t, e)).single.checkedBy, 'words');
    });

    testWidgets('no model installed: the slides\' own lines are the ideas, and it says why', (t) async {
      final e = await _env(t);
      final m = _FakeModel(available: false);
      await check(t, e, m, answer: _good);
      expect(find.textContaining('permits its owner to exclude the public'), findsOneWidget);
      expect(find.text('Checked by comparing words only. The AI model is not installed.'), findsOneWidget);
      expect(m.conceptCalls, 0);
      expect(m.judgeCalls, 0);
    });

    testWidgets('a model that cannot write the ideas: the slides\' lines are used', (t) async {
      final e = await _env(t);
      final m = _FakeModel(ideas: const ['Only one idea written here by the model.']);
      await check(t, e, m, answer: _good);
      expect(find.textContaining('permits its owner to exclude the public'), findsOneWidget);
      expect(find.textContaining('could not write the key ideas this time'), findsOneWidget);
      expect(m.judgeCalls, 0);
      expect(await t.runAsync(() => TeachBackRepository(e.db).conceptsFor(e.setId, 'Patents')), isNull); // nothing kept
    });

    testWidgets('a model that cannot judge this time: the words\' result, with the model\'s ideas', (t) async {
      final e = await _env(t);
      final m = _FakeModel(ideas: const [c1, c2], judgement: null);
      await check(t, e, m, answer: _good);
      expect(find.text(c1), findsOneWidget);
      expect(find.textContaining('could not judge your explanation this time'), findsOneWidget);
      expect((await _saved(t, e)).single.checkedBy, 'words');
    });

    testWidgets('a model that throws never breaks the check: it falls back to words', (t) async {
      final e = await _env(t);
      final m = _FakeModel(ideas: const [c1, c2], judgement: judged([yes, no]), throwOnConcepts: true);
      await check(t, e, m, answer: _good);
      expect(find.text('THE IDEAS IN YOUR SLIDES'), findsOneWidget);
      expect(find.text('Checked by comparing words only.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('where the model and the words disagree, the idea is partly there', (t) async {
      final e = await _env(t);
      // the words find the first idea well covered (the student copied its words); the model says no
      final m = _FakeModel(ideas: const [c1, c2], judgement: judged([no, no]));
      await check(t, e, m, answer: 'A patent lets the owner stop the public from making, using, or selling a protected invention, and that is all there is to it.');
      expect(find.text('PARTLY THERE'), findsOneWidget);
      expect(find.text('NOT FOUND'), findsOneWidget);
    });

    testWidgets('an opposite the model found is shown as something to look at', (t) async {
      final e = await _env(t);
      final m = _FakeModel(
        ideas: const [c1, c2],
        judgement: judged([no, no], opposites: const [Opposite('A patent does not let the owner exclude anyone.', 'A patent permits its owner to exclude the public')]),
      );
      await check(t, e, m, answer: 'A patent does not let the owner exclude anyone from making the invention, so it protects nothing at all.');
      expect(find.text('WORTH A SECOND LOOK'), findsOneWidget);
      expect(find.textContaining('This might not match your slides. Compare it with: "A patent permits its owner to exclude the public"'), findsOneWidget);
    });

    testWidgets('the topics list passes the model on, so a topic opened from it is checked by it', (t) async {
      final e = await _env(t);
      final m = _FakeModel(ideas: const [c1, c2], judgement: judged([yes, no]));
      await _open(t, TeachBackTopicsScreen(repo: e.repo, setId: e.setId, model: m));
      await t.tap(find.text('Patents'));
      await settle(t);
      await _write(t, mine);
      await t.tap(find.text('Check my explanation'));
      await settle(t);
      expect(m.judgeCalls, 1);
      expect(find.text(c1), findsOneWidget);
    });

    testWidgets('"I covered this" still works on a model-checked idea', (t) async {
      final e = await _env(t);
      final m = _FakeModel(ideas: const [c1, c2], judgement: judged([no, no]));
      await check(t, e, m);
      await t.ensureVisible(find.text('I covered this').first);
      await t.tap(find.text('I covered this').first);
      await settle(t);
      expect(find.text('YOU SAID YOU COVERED THIS'), findsOneWidget);
      expect((await _saved(t, e)).single.overruledIdeas, [0]);
    });
  });

  group('where it starts', () {
    testWidgets('each topic of the Summary has "Explain it back", the overview and takeaways do not', (t) async {
      final e = await _env(t);
      await _open(t, SummaryScreen(repo: e.repo, setId: e.setId, title: 'Module 3', notes: _notes));
      expect(find.text('Explain it back'), findsNWidgets(2)); // Copyrights and Patents only
      await t.ensureVisible(find.text('Explain it back').last);
      await t.tap(find.text('Explain it back').last);
      await settle(t);
      expect(find.text('Teach it back'), findsOneWidget);
      expect(find.text('Patents'), findsWidgets);
    });

    testWidgets('the set page has a Teach back tile that opens the topics', (t) async {
      final e = await _env(t);
      await _open(t, SetDetailScreen(repo: e.repo, setId: e.setId));
      await t.ensureVisible(find.text('Teach back'));
      await t.tap(find.text('Teach back'));
      await settle(t);
      expect(find.text('Teach it back'), findsOneWidget);
      expect(find.text('Copyrights'), findsOneWidget);
    });
  });
}
