import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/ai/llm_ai_engine.dart';
import 'package:kodigno/app_controller.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/card_assist.dart';
import 'package:kodigno/models/device_profiler.dart';
import 'package:kodigno/models/model_downloader.dart';
import 'package:kodigno/models/model_manager.dart';
import 'package:kodigno/models/tier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_llm_runtime.dart';

const _json = '''
{"tiers":[
 {"id":"standard","label":"Standard","maxRamMb":null,"model":"std","url":"http://x/b","sha256":"bb","sizeMb":1000,"chunkChars":1500,"questionsPerChunk":5,"cardsPerChunk":5}
]}''';

class _Profiler implements DeviceProfiler {
  @override
  Future<DeviceProfile> read() async => const DeviceProfile(ramMb: 8000, freeStorageMb: 100000);
}

/// A runtime that also records what was sent to chat.
class _Chat extends FakeLlmRuntime {
  _Chat(super.script);
  final sent = <List<Map<String, String>>>[];
  Map<String, Object?>? schema;
  double? temperature;

  @override
  Future<String> chat(List<Map<String, String>> messages,
      {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) {
    sent.add(messages);
    this.schema = schema;
    this.temperature = temperature;
    return super.chat(messages, maxTokens: maxTokens, temperature: temperature, schema: schema);
  }
}

Future<AppController> _make(LlmRuntime rt, {bool installed = true}) async {
  SharedPreferences.setMockInitialValues({});
  final dir = await Directory.systemTemp.createTemp('ca');
  addTearDown(() => dir.delete(recursive: true));
  if (installed) {
    File('${dir.path}/std.gguf').writeAsBytesSync([1]);
    File('${dir.path}/std.gguf.ok').writeAsStringSync('ok');
  }
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final c = AppController(
    tiers: TierTable.fromJson(_json),
    profiler: _Profiler(),
    models: ModelManager(dir, ModelDownloader()),
    repo: StudyRepository(db),
    engineFactory: (tier, _) => LlmAiEngine(rt, tier),
    prefs: await SharedPreferences.getInstance(),
  );
  await c.init();
  return c;
}

void main() {
  test('asks the local model with the system rules, the notes and a strict JSON schema', () async {
    final rt = _Chat(['{"definition":"The cell\'s power plant that makes ATP."}']);
    final c = await _make(rt);
    final s = await c.suggestCard(
        want: AssistField.definition,
        term: 'Mitochondria',
        notes: 'Mitochondria make ATP for the cell.',
        setTitle: 'Biology');
    expect(s, "The cell's power plant that makes ATP.");
    expect(rt.sent.single.first, {'role': 'system', 'content': cardAssistSystemPrompt});
    expect(rt.sent.single.last['content'], allOf(contains('TERM: Mitochondria'), contains('Mitochondria make ATP')));
    expect(rt.schema, cardAssistSchema(AssistField.definition));
    expect(rt.temperature, lessThanOrEqualTo(0.3)); // little creativity: it is a fact
  });

  test('works the other way round: the term for a definition', () async {
    final rt = _Chat(['{"term":"Mitochondria"}']);
    final c = await _make(rt);
    expect(await c.suggestCard(want: AssistField.term, definition: 'Makes ATP for the cell.'), 'Mitochondria');
  });

  test('nothing typed yet: no model call, a message that says what to do', () async {
    final rt = _Chat([]);
    final c = await _make(rt);
    await expectLater(c.suggestCard(want: AssistField.definition, term: '  '),
        throwsA(isA<CardAssistFailed>().having((e) => e.message, 'message', contains('Type the term first'))));
    await expectLater(c.suggestCard(want: AssistField.term, definition: ''),
        throwsA(isA<CardAssistFailed>().having((e) => e.message, 'message', contains('Type the definition first'))));
    expect(rt.sent, isEmpty);
  });

  test('the model not being set up is said plainly', () async {
    final c = await _make(_Chat([]), installed: false);
    await expectLater(c.suggestCard(want: AssistField.definition, term: 'x'),
        throwsA(isA<CardAssistFailed>().having((e) => e.message, 'message', contains('not set up'))));
  });

  test('"not sure" and unreadable answers become messages for the student', () async {
    final unsure = await _make(_Chat(['{"definition":""}']));
    await expectLater(unsure.suggestCard(want: AssistField.definition, term: 'Zorblax'),
        throwsA(isA<CardAssistFailed>().having((e) => e.message, 'message', contains("wasn't sure"))));
    final garbage = await _make(_Chat(['not json at all']));
    await expectLater(garbage.suggestCard(want: AssistField.definition, term: 'x'),
        throwsA(isA<CardAssistFailed>().having((e) => e.message, 'message', contains('not usable'))));
  });

  test('a model that cannot run is reported, not thrown raw', () async {
    final c = await _make(_Chat([ModelUnavailableException('out of memory')]));
    await expectLater(c.suggestCard(want: AssistField.definition, term: 'x'),
        throwsA(isA<CardAssistFailed>().having((e) => e.message, 'message', contains('could not run'))));
  });
}
