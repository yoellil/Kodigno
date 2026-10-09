// Live check on the real model, run by hand (skipped otherwise):
//   $env:KULAY_LIVE_MODEL = "C:\path\to\qwen2.5-1.5b-instruct-q4_k_m.gguf"; flutter test test/reading/live_story_test.dart
// Optional: KULAY_LIVE_STORIES (default 4).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/llama_server_runtime.dart';
import 'package:kodigno/reading/levels.dart';
import 'package:kodigno/reading/nlp.dart';
import 'package:kodigno/reading/story_engine.dart';

void main() {
  final model = Platform.environment['KULAY_LIVE_MODEL'];
  test('writes checked stories on the bundled llama-server', () async {
    final rt = LlamaServerRuntime(serverExe: File('third_party/llama/llama-server.exe').absolute.path, modelPath: model!);
    addTearDown(rt.dispose);
    final engine = StoryEngine(() async => rt, modelName: model.split(RegExp(r'[\\/]')).last);
    final n = int.parse(Platform.environment['KULAY_LIVE_STORIES'] ?? '4');
    var ok = 0;
    for (var i = 0; i < n; i++) {
      final level = (i * 3) % levels.length;
      final topic = topics[(i * 5) % topics.length];
      final watch = Stopwatch()..start();
      try {
        final s = await engine.makeStory(level, topic, job: Job(Priority.reader));
        ok++;
        // ignore: avoid_print
        print('${levels[level].name} / $topic: ok in ${watch.elapsed.inSeconds}s, ${s.questions.length} questions, '
            'grade ${s.checks['grade']}, drafts ${s.checks['drafts']}');
        for (final q in s.questions) {
          // ignore: avoid_print
          print('   ${q.question} -> ${q.choices[q.answer]}  [${s.sentences[q.evidence]}]');
          expect(s.sentences[q.evidence], isNotEmpty);
        }
        expect(lintStory(s.paras, StoryPlan(name: '${s.checks['name']}'), levels[level], topic).hard, isEmpty);
      } on StoryFailed catch (e) {
        // ignore: avoid_print
        print('${levels[level].name} / $topic: failed in ${watch.elapsed.inSeconds}s: $e');
      }
    }
    final w = await engine.explainWord('bustling', 'The market was bustling with people.', 2);
    // ignore: avoid_print
    print('bustling: ${w.meaning} (${w.synonym})');
    // ignore: avoid_print
    print('$ok of $n stories passed');
  }, skip: model == null ? 'set KULAY_LIVE_MODEL to run' : false, timeout: const Timeout(Duration(minutes: 40)));
}
