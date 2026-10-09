import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/llama_server_runtime.dart';
import 'package:kodigno/domain/output_parser.dart';
import 'package:kodigno/domain/prompt.dart';

void main() {
  final model = Platform.environment['MODEL_PATH'];
  final server = Platform.environment['LLAMA_SERVER'];

  test('real model returns parseable output', () async {
    final rt = LlamaServerRuntime(serverExe: server!, modelPath: model!);
    final out = await rt.complete(
      buildPrompt(
          'The mitochondria is the powerhouse of the cell. '
          'It produces ATP through cellular respiration.',
          questions: 2,
          cards: 2),
      maxTokens: 600,
    );
    await rt.dispose();
    expect(() => parseGeneratedSet(out), returnsNormally, reason: out);
  },
      skip: (model == null || server == null) ? 'set MODEL_PATH and LLAMA_SERVER' : false,
      timeout: const Timeout(Duration(minutes: 5)));
}
