import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/app_controller.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/domain/summary.dart';
import 'package:kodigno/models/device_profiler.dart';
import 'package:kodigno/models/model_downloader.dart';
import 'package:kodigno/models/model_manager.dart';
import 'package:kodigno/models/tier.dart';
import 'package:kodigno/study/teach_judge.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _json = '''
{"tiers":[
 {"id":"low","label":"Basic quality","maxRamMb":3500,"model":"low","url":"http://x/a","sha256":"aa","sizeMb":400,"chunkChars":800,"questionsPerChunk":3,"cardsPerChunk":3},
 {"id":"standard","label":"Standard","maxRamMb":null,"model":"std","url":"http://x/b","sha256":"bb","sizeMb":1000,"chunkChars":1500,"questionsPerChunk":5,"cardsPerChunk":5}
]}''';

class _Profiler implements DeviceProfiler {
  _Profiler(this.ram, [this.free = 100000]);
  final int ram, free;
  @override
  Future<DeviceProfile> read() async => DeviceProfile(ramMb: ram, freeStorageMb: free);
}

class _OkDownloader extends ModelDownloader {
  @override
  Stream<DownloadProgress> download({
    required Uri url, required File target, required String sha256Hex,
  }) async* {
    await target.writeAsBytes([1]);
    yield DownloadProgress(1, 1);
  }
}

class _Engine implements AiEngine {
  _Engine(this.behavior, [this.summary, this.onGenerate, this.conceptsFn, this.judgeFn]);
  final Future<GeneratedSet> Function(void Function(double)? onProgress) behavior;
  final Future<LessonSummary> Function(void Function(double)? onProgress)? summary;
  final void Function(String notes, String? verifyIn)? onGenerate;
  final Future<List<String>> Function(String slideText, String? topic)? conceptsFn;
  final Future<TeachBackJudgement> Function(List<String> concepts, String answer)? judgeFn;

  @override
  Future<List<String>> topicConcepts(String slideText, {String? topic}) =>
      conceptsFn?.call(slideText, topic) ?? Future.value(const []);

  @override
  Future<TeachBackJudgement> judgeExplanation(
          {required List<String> concepts, required String answer, required String slideText}) =>
      judgeFn?.call(concepts, answer) ?? Future<TeachBackJudgement>.error(GenerationFailed());
  @override
  Future<GeneratedSet> generate(String notes,
          {String? verifyIn, void Function(double)? onProgress}) {
    onGenerate?.call(notes, verifyIn);
    return behavior(onProgress);
  }
  @override
  Future<LessonSummary> summarize(String notes, {void Function(double)? onProgress}) =>
      summary?.call(onProgress) ?? Future.value(_lesson);
  @override
  Future<String> ask(String notes, List<ChatTurn> history) async => 'ok';
  @override
  Future<void> dispose() async {}
}

const _lesson = LessonSummary(overview: 'About cells.', sections: [
  SummarySection(heading: 'The cell', explanation: 'Cells are the units of life.'),
]);

const _set = GeneratedSet(
    [QuizQuestion(prompt: 'Q', choices: ['a', 'b'], answerIndex: 0)],
    [Flashcard(front: 'f', back: 'b')]);

Future<AppController> _make({
  required int ram,
  int free = 100000,
  required Future<GeneratedSet> Function(void Function(double)? p) engine,
  Future<LessonSummary> Function(void Function(double)? p)? summary,
  void Function(String notes, String? verifyIn)? onGenerate,
  Future<List<String>> Function(String slideText, String? topic)? concepts,
  Future<TeachBackJudgement> Function(List<String> concepts, String answer)? judge,
}) async {
  SharedPreferences.setMockInitialValues({});
  final dir = await Directory.systemTemp.createTemp('ac');
  addTearDown(() => dir.delete(recursive: true));
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return AppController(
    tiers: TierTable.fromJson(_json),
    profiler: _Profiler(ram, free),
    models: ModelManager(dir, _OkDownloader()),
    repo: StudyRepository(db),
    engineFactory: (_, _) => _Engine(engine, summary, onGenerate, concepts, judge),
    prefs: await SharedPreferences.getInstance(),
  );
}

void main() {
  test('init recommends a tier from RAM and reports model not ready', () async {
    final c = await _make(ram: 2000, engine: (_) async => _set);
    await c.init();
    expect(c.tier!.id, 'low');
    expect(c.modelReady, isFalse);
  });

  test('download makes the model ready', () async {
    final c = await _make(ram: 2000, engine: (_) async => _set);
    await c.init();
    await c.downloadModel();
    expect(c.modelReady, isTrue);
  });

  test('storage too low blocks download and sets flag', () async {
    final c = await _make(ram: 2000, free: 100, engine: (_) async => _set);
    await c.init();
    await c.downloadModel();
    expect(c.storageTooLow, isTrue);
    expect(c.modelReady, isFalse);
  });

  test('chosen tier is remembered', () async {
    final c = await _make(ram: 2000, engine: (_) async => _set);
    await c.init();
    await c.chooseTier(c.tiers.byId('standard'));
    expect(c.tier!.id, 'standard');
    expect(c.prefs.getString('tier'), 'standard');
  });

  test('generate saves a set with source info and reports progress', () async {
    final c = await _make(ram: 2000, engine: (p) async {
      p?.call(0.5);
      return _set;
    });
    await c.init();
    await c.downloadModel();
    final seen = <double>[];
    c.addListener(() => seen.add(c.generationFraction));
    final id = await c.generate(
        title: 'Bio', notes: 'cell text', sourceType: 'pdf', sourcePaths: ['a.pdf']);
    expect(id, isNotNull);
    expect(c.error, isNull);
    expect(seen.any((v) => (v - 0.8).abs() < 1e-9), isTrue); // the second part of the work
    final d = await c.repo.getSet(id!);
    expect(d.set.sourceType, 'pdf');
    expect(d.set.sourceText, 'cell text');
  });

  test('GenerationFailed sets a user-visible error and saves nothing', () async {
    final c = await _make(ram: 2000, engine: (_) async => throw GenerationFailed());
    await c.init();
    await c.downloadModel();
    expect(await c.generate(title: 'Bio', notes: 'text'), isNull);
    expect(c.error, contains('try again'));
  });

  test('ModelUnavailable offers the next lower tier', () async {
    final c = await _make(
        ram: 9000, engine: (_) async => throw ModelUnavailableException('oom'));
    await c.init(); // standard
    await c.downloadModel();
    expect(await c.generate(title: 'Bio', notes: 'text'), isNull);
    expect(c.fallbackOffer!.id, 'low');
    await c.acceptFallback();
    expect(c.tier!.id, 'low');
    expect(c.fallbackOffer, isNull);
  });

  test('blank notes are rejected without calling the engine', () async {
    var called = false;
    final c = await _make(ram: 2000, engine: (_) async {
      called = true;
      return _set;
    });
    await c.init();
    await c.downloadModel();
    expect(await c.generate(title: 'x', notes: '   '), isNull);
    expect(called, isFalse);
    expect(c.error, isNotNull);
  });

  test('summarize returns the lesson and reports progress', () async {
    final c = await _make(ram: 2000, engine: (_) async => _set, summary: (p) async {
      p?.call(0.5);
      return _lesson;
    });
    await c.init();
    await c.downloadModel();
    final seen = <double>[];
    c.addListener(() => seen.add(c.summaryFraction));
    expect(await c.summarize('cell text'), same(_lesson));
    expect(seen, contains(0.5));
    expect(c.summarizing, isFalse);
  });

  test('summarize failures become messages fit to show the user', () async {
    final c = await _make(
        ram: 2000,
        engine: (_) async => _set,
        summary: (_) async => throw GenerationFailed());
    await c.init();
    await c.downloadModel();
    await expectLater(c.summarize('text'),
        throwsA(isA<SummaryFailed>().having((e) => e.message, 'message', contains('try again'))));
    expect(c.summarizing, isFalse);

    final oom = await _make(
        ram: 2000,
        engine: (_) async => _set,
        summary: (_) async => throw ModelUnavailableException('oom'));
    await oom.init();
    await oom.downloadModel();
    await expectLater(oom.summarize('text'), throwsA(isA<SummaryFailed>()));
  });

  test('summarize rejects blank notes without calling the engine', () async {
    var called = false;
    final c = await _make(ram: 2000, engine: (_) async => _set, summary: (_) async {
      called = true;
      return _lesson;
    });
    await c.init();
    await c.downloadModel();
    await expectLater(c.summarize('   '), throwsA(isA<SummaryFailed>()));
    expect(called, isFalse);
  });

  test('generate writes the lesson first, saves it, and makes the cards from it', () async {
    String? madeFrom, checkedAgainst;
    final c = await _make(
      ram: 2000,
      engine: (_) async => _set,
      onGenerate: (notes, verifyIn) {
        madeFrom = notes;
        checkedAgainst = verifyIn;
      },
    );
    await c.init();
    await c.downloadModel();
    final id = await c.generate(title: 'Bio', notes: 'cell text');
    expect(madeFrom, _lesson.toStudyText());
    expect(checkedAgainst, 'cell text');
    final d = await c.repo.getSet(id!);
    expect(d.summary!.encode(), _lesson.encode());
    expect(d.set.sourceText, 'cell text');
  });

  test('if no lesson can be made, the cards come from the notes and the set still saves', () async {
    String? madeFrom;
    String? checkedAgainst = 'unset';
    final c = await _make(
      ram: 2000,
      engine: (_) async => _set,
      summary: (_) async => throw GenerationFailed(),
      onGenerate: (notes, verifyIn) {
        madeFrom = notes;
        checkedAgainst = verifyIn;
      },
    );
    await c.init();
    await c.downloadModel();
    final id = await c.generate(title: 'Bio', notes: 'cell text');
    expect(madeFrom, 'cell text');
    expect(checkedAgainst, isNull);
    expect((await c.repo.getSet(id!)).summary, isNull);
    expect(c.error, isNull);
  });

  test('if the cards cannot be made from the lesson, they are made from the notes', () async {
    final seen = <String>[];
    var calls = 0;
    final c = await _make(
      ram: 2000,
      engine: (_) async => ++calls == 1 ? throw GenerationFailed() : _set,
      onGenerate: (notes, _) => seen.add(notes),
    );
    await c.init();
    await c.downloadModel();
    final id = await c.generate(title: 'Bio', notes: 'cell text');
    expect(seen, [_lesson.toStudyText(), 'cell text']);
    expect((await c.repo.getSet(id!)).summary, isNotNull); // the lesson is kept
  });

  test('a PDF\'s pages are kept: the lesson, the cards and the questions each point at a page', () async {
    final c = await _make(ram: 2000, engine: (_) async => _set);
    await c.init();
    await c.downloadModel();
    final notes = '${pageMarker(2)}\nThe cell is where life begins. Cells are the units of life.\n\n'
        '${pageMarker(6)}\nA question about b and the f card of the set.';
    final id = await c.generate(title: 'Bio', notes: notes, sourceType: 'pdf', sourcePaths: ['a.pdf']);
    final d = await c.repo.getSet(id!);
    expect(d.set.sourceText, notes); // the markers stay, so the pages can be found again
    final lessonRef = d.summary!.sourceOf('Cells are the units of life.')!;
    expect(lessonRef.pages, contains(2));
    expect(lessonRef.kind, isNot(SourceKind.unmatched));
    expect(SourceRef.decode(d.flashcards.single.source), isNotNull);
    expect(SourceRef.decode(d.questions.single.source), isNotNull);
  });

  test('notes without pages (a Word file, plain text) get no sources, and nothing breaks', () async {
    final c = await _make(ram: 2000, engine: (_) async => _set);
    await c.init();
    await c.downloadModel();
    final id = await c.generate(title: 'Bio', notes: 'cell text');
    final d = await c.repo.getSet(id!);
    expect(d.summary!.sources, isEmpty);
    expect(d.flashcards.single.source, '');
    expect(d.questions.single.source, '');
  });

  test('a lesson written again later also gets its sources', () async {
    final c = await _make(ram: 2000, engine: (_) async => _set);
    await c.init();
    await c.downloadModel();
    final lesson = await c.summarize('${pageMarker(4)}\nCells are the units of life, and they divide.');
    expect(lesson.sourceOf('Cells are the units of life.')!.pages, [4]);
  });

  group('Teach-Back model', () {
    const verdicts = TeachBackJudgement([ConceptVerdict(Verdict.yes, 'a quote of four words')], []);

    test('is not available until the model is installed', () async {
      final c = await _make(ram: 2000, engine: (_) async => _set, concepts: (_, _) async => ['One idea here is stated.', 'Another idea here is stated.']);
      await c.init();
      expect(c.available, isFalse);
      expect(await c.concepts('slides'), isEmpty); // not asked at all
      expect(await c.judge(concepts: const ['x'], answer: 'a', slideText: 's'), isNull);
      await c.downloadModel();
      expect(c.available, isTrue);
    });

    test('the smallest model writes the ideas but is not asked to judge; a bigger one does both', () async {
      final low = await _make(ram: 2000, engine: (_) async => _set);
      await low.init();
      await low.downloadModel();
      expect(low.tier!.id, 'low');
      expect(low.available, isTrue);
      expect(low.canJudge, isFalse);

      final big = await _make(ram: 9000, engine: (_) async => _set);
      await big.init();
      await big.downloadModel();
      expect(big.tier!.id, 'standard');
      expect(big.canJudge, isTrue);
    });

    test('concepts and the judgement come from the engine, with the topic and the answer passed on', () async {
      String? topic, answer;
      final c = await _make(
        ram: 9000,
        engine: (_) async => _set,
        concepts: (slides, t) async {
          topic = t;
          return ['A patent protects an invention for years.', 'A patent lets its owner stop others.'];
        },
        judge: (concepts, a) async {
          answer = a;
          return verdicts;
        },
      );
      await c.init();
      await c.downloadModel();
      expect(await c.concepts('slides', topic: 'Patents'), hasLength(2));
      expect(topic, 'Patents');
      final j = await c.judge(concepts: const ['x'], answer: 'my words', slideText: 's');
      expect(j!.concepts.single.verdict, Verdict.yes);
      expect(answer, 'my words');
    });

    test('a model that fails gives no ideas and no judgement, and nothing is thrown', () async {
      final c = await _make(
        ram: 9000,
        engine: (_) async => _set,
        concepts: (_, _) async => throw StateError('boom'),
        judge: (_, _) async => throw GenerationFailed(),
      );
      await c.init();
      await c.downloadModel();
      expect(await c.concepts('slides'), isEmpty);
      expect(await c.judge(concepts: const ['x'], answer: 'a', slideText: 's'), isNull);
    });

    test('a model that cannot run is let go, and the next ask starts a fresh one', () async {
      var made = 0;
      var first = true;
      final dir = await Directory.systemTemp.createTemp('ac2');
      addTearDown(() => dir.delete(recursive: true));
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      SharedPreferences.setMockInitialValues({});
      final c = AppController(
        tiers: TierTable.fromJson(_json),
        profiler: _Profiler(9000),
        models: ModelManager(dir, _OkDownloader()),
        repo: StudyRepository(db),
        engineFactory: (_, _) {
          made++;
          return _Engine((_) async => _set, null, null, (_, _) async {
            if (first) {
              first = false;
              throw ModelUnavailableException('out of memory');
            }
            return ['A patent protects an invention for years.', 'A patent lets its owner stop others.'];
          });
        },
        prefs: await SharedPreferences.getInstance(),
      );
      await c.init();
      await c.downloadModel();
      expect(await c.concepts('slides'), isEmpty);
      expect(await c.concepts('slides'), hasLength(2));
      expect(made, 2);
    });
  });
}
