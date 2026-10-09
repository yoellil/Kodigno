import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/llama_server_runtime.dart';
import 'package:kodigno/ai/llm_ai_engine.dart';
import 'package:kodigno/models/tier.dart';
import 'package:kodigno/sources/pdf_text.dart';

const _low = Tier(
  id: 'low',
  label: 'Basic quality',
  model: 'm',
  url: 'u',
  sha256: 's',
  maxRamMb: 3500,
  sizeMb: 470,
  chunkChars: 800,
  questionsPerChunk: 3,
  cardsPerChunk: 3,
);

const _high = Tier(
  id: 'high',
  label: 'High quality',
  model: 'm',
  url: 'u',
  sha256: 's',
  maxRamMb: null,
  sizeMb: 2008,
  chunkChars: 2500,
  questionsPerChunk: 8,
  cardsPerChunk: 8,
);

// Slide-style bullets, as the summary will usually get them.
const _slides = '''
Photosynthesis
- Plants make their own food
- Needs light, water and carbon dioxide
- Produces glucose and oxygen
- Happens in chloroplasts

Chlorophyll
- Green pigment inside chloroplasts
- Absorbs red and blue light, reflects green
- Captures the light energy that drives the process

Light and dark reactions
- Light reactions: in the thylakoid membranes, split water, make ATP and release oxygen
- Calvin cycle: in the stroma, uses ATP and carbon dioxide to build glucose
- The Calvin cycle does not need light directly, but depends on the light reactions' ATP

Why it matters
- Source of the oxygen we breathe
- Base of nearly every food chain
''';

void main() {
  final model = Platform.environment['MODEL_PATH'];
  final server = Platform.environment['LLAMA_SERVER'];
  final pdf = Platform.environment['SAMPLE_PDF']; // optional: summarize this PDF instead
  // TIER=high uses the High tier's chunk size; the model file is whatever MODEL_PATH is.

  test('real model writes a lesson from slide bullets', () async {
    final rt = LlamaServerRuntime(serverExe: server!, modelPath: model!);
    final engine = LlmAiEngine(rt, Platform.environment['TIER'] == 'high' ? _high : _low);
    final notes = pdf == null ? _slides : await PdfrxTextExtractor().extract(pdf);
    // ignore: avoid_print
    print('notes: ${notes.length} chars');
    final clock = Stopwatch()..start();
    final lesson = await engine.summarize(notes);
    await engine.dispose();
    // ignore: avoid_print
    print('summarized in ${clock.elapsed.inSeconds}s');
    // ignore: avoid_print
    print(lesson.toText());
    expect(lesson.sections, isNotEmpty);
  },
      skip: (model == null || server == null) ? 'set MODEL_PATH and LLAMA_SERVER' : false,
      timeout: const Timeout(Duration(minutes: 10)));
}
