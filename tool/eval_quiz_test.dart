// Runs the real model over the PDFs in models-dev/eval/ the way the app does
// (lesson first, then the set from the lesson, checked against the notes) and
// writes every question and card to models-dev/eval/out/<label>/ for grading.
// Not part of the test suite.
// Run: flutter test tool/eval_quiz_test.dart   (EVAL_LABEL=name, EVAL_ONLY=part-of-filename)
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/ai/llama_server_runtime.dart';
import 'package:kodigno/ai/llm_ai_engine.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/summary.dart';
import 'package:kodigno/models/tier.dart';
import 'package:kodigno/sources/pdf_text.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

/// Passes calls through, keeping each fact check's question and reply.
class _Recorder implements LlmRuntime {
  _Recorder(this.inner);
  final LlmRuntime inner;
  final checks = <(String, String)>[];

  @override
  Future<String> complete(String prompt, {int maxTokens = 1024, Map<String, Object?>? schema}) =>
      inner.complete(prompt, maxTokens: maxTokens, schema: schema);

  @override
  Future<String> chat(List<Map<String, String>> messages,
      {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) async {
    final reply = await inner.chat(messages, maxTokens: maxTokens, temperature: temperature, schema: schema);
    final m = RegExp(r'QUESTION: ([^\n]*)').firstMatch(messages.last['content']!);
    if (m != null) checks.add((m[1]!, reply));
    return reply;
  }

  @override
  Future<void> dispose() => inner.dispose();
}

void main() {
  final env = Platform.environment;
  final label = env['EVAL_LABEL'] ?? 'run';
  final only = env['EVAL_ONLY'];
  final model = env['MODEL_PATH'] ??
      p.join(env['APPDATA'] ?? '', 'Kulay', 'Kulay', 'models', 'qwen2.5-1.5b-instruct-q4_k_m.gguf');
  final server = p.absolute('third_party/llama/llama-server.exe');
  final pdfs = Directory('models-dev/eval').existsSync()
      ? (Directory('models-dev/eval').listSync().whereType<File>().where((f) => f.path.endsWith('.pdf')).toList()
        ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];

  test('eval quiz generation', () async {
    Pdfrx.pdfiumModulePath = p.absolute('build/windows/x64/runner/Release/pdfium.dll');
    final tier = TierTable.fromJson(File('assets/model_tiers.json').readAsStringSync()).byId('standard');
    final out = Directory('models-dev/eval/out/$label')..createSync(recursive: true);
    for (final pdf in pdfs) {
      final name = p.basenameWithoutExtension(pdf.path);
      if (only != null && !name.contains(only)) continue;
      final cache = File('models-dev/eval/$name.txt');
      if (!cache.existsSync()) cache.writeAsStringSync(await PdfrxTextExtractor().extract(pdf.path));
      final notes = cache.readAsStringSync();
      if (env['EVAL_EXTRACT_ONLY'] != null) continue;

      final rec = _Recorder(LlamaServerRuntime(serverExe: server, modelPath: model));
      final engine = LlmAiEngine(rec, tier);
      final watch = Stopwatch()..start();
      LessonSummary? lesson;
      try {
        lesson = await engine.summarize(notes);
      } on GenerationFailed {
        lesson = null;
      }
      final lessonSecs = watch.elapsed.inSeconds;
      GeneratedSet set;
      if (lesson == null) {
        set = await engine.generate(notes);
      } else {
        try {
          set = await engine.generate(lesson.toStudyText(), verifyIn: notes);
        } on GenerationFailed {
          set = await engine.generate(notes);
        }
      }
      await engine.dispose();
      final secs = watch.elapsed.inSeconds;

      final kept = {for (final q in set.questions) q.prompt, for (final c in set.flashcards) c.front};
      final dropped = [for (final (q, r) in rec.checks) if (!kept.contains(q.split('\n').first)) '$q   -> $r'];
      final md = StringBuffer('# $name ($label, ${secs}s: lesson ${lessonSecs}s, '
          '${rec.checks.length} fact checks, ${dropped.length} dropped)\n\n## Dropped by the fact check\n\n');
      for (final d in dropped) {
        md.writeln('- ${d.trim().replaceAll('\n', '\n  ')}');
      }
      md.writeln('\n## Quiz (${set.questions.length})\n');
      for (final (i, q) in set.questions.indexed) {
        md.writeln('${i + 1}. ${q.prompt}');
        for (final (j, c) in q.choices.indexed) {
          md.writeln('   - ${j == q.answerIndex ? '**[x]**' : '[ ]'} $c');
        }
        md.writeln('   - _why:_ ${q.explanation.replaceAll('\n', ' ')}\n');
      }
      md.writeln('## Flashcards (${set.flashcards.length})\n');
      for (final (i, c) in set.flashcards.indexed) {
        md.writeln('${i + 1}. **${c.front}**  \n   ${c.back.replaceAll('\n', '  \n   ')}\n');
      }
      File(p.join(out.path, '$name.md')).writeAsStringSync(md.toString());
      File(p.join(out.path, '$name.json')).writeAsStringSync(const JsonEncoder.withIndent(' ').convert({
        'seconds': secs,
        'questions': [
          for (final q in set.questions)
            {'prompt': q.prompt, 'choices': q.choices, 'answer': q.answerIndex, 'why': q.explanation},
        ],
        'cards': [for (final c in set.flashcards) {'front': c.front, 'back': c.back}],
      }));
      // ignore: avoid_print
      print('$name: ${set.questions.length} questions, ${set.flashcards.length} cards, ${secs}s '
          '(lesson ${lessonSecs}s, ${rec.checks.length} checks, ${dropped.length} dropped)');
    }
  }, skip: pdfs.isEmpty ? 'put PDFs in models-dev/eval' : false, timeout: const Timeout(Duration(hours: 3)));
}
