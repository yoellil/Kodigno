import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/app_controller.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/summary.dart';
import 'package:kodigno/models/device_profiler.dart';
import 'package:kodigno/models/model_downloader.dart';
import 'package:kodigno/models/model_manager.dart';
import 'package:kodigno/models/tier.dart';
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
  _Engine(this.behavior, [this.summary, this.onGenerate]);
  final Future<GeneratedSet> Function(void Function(double)? onProgress) behavior;
  final Future<LessonSummary> Function(void Function(double)? onProgress)? summary;
  final void Function(String notes, String? verifyIn)? onGenerate;
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
    engineFactory: (_, _) => _Engine(engine, summary, onGenerate),
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
}
