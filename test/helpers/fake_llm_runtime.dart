import 'package:kodigno/ai/ai_engine.dart';

/// Returns scripted responses in order; an Object that is an Exception is thrown.
class FakeLlmRuntime implements LlmRuntime {
  FakeLlmRuntime(this.script);
  final List<Object> script;
  final prompts = <String>[];

  @override
  Future<String> complete(String prompt, {int maxTokens = 1024}) async {
    prompts.add(prompt);
    final next = script.removeAt(0);
    if (next is Exception) throw next;
    return next as String;
  }

  @override
  Future<void> dispose() async {}
}
