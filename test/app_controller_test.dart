import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/app_controller.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/models.dart';
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
  _Engine(this.behavior);
  final Future<GeneratedSet> Function(void Function(double)? onProgress) behavior;
  @override
  Future<GeneratedSet> generate(String notes, {void Function(double)? onProgress}) =>
      behavior(onProgress);
  @override
  Future<String> ask(String notes, List<ChatTurn> history) async => 'ok';
  @override
  Future<void> dispose() async {}
}

const _set = GeneratedSet(
    [QuizQuestion(prompt: 'Q', choices: ['a', 'b'], answerIndex: 0)],
    [Flashcard(front: 'f', back: 'b')]);

Future<AppController> _make({
  required int ram,
  int free = 100000,
  required Future<GeneratedSet> Function(void Function(double)? p) engine,
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
    engineFactory: (_, _) => _Engine(engine),
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
    expect(seen, contains(0.5));
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
}
