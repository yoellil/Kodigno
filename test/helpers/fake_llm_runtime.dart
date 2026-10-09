import 'package:kodigno/ai/ai_engine.dart';

/// Returns scripted responses in order; an Object that is an Exception is thrown.
/// Once the script runs out it returns '', which no parser accepts.
class FakeLlmRuntime implements LlmRuntime {
  FakeLlmRuntime(this.script);
  final List<Object> script;
  final prompts = <String>[];

  @override
  Future<String> complete(String prompt,
      {int maxTokens = 1024, Map<String, Object?>? schema}) async {
    prompts.add(prompt);
    final next = script.isEmpty ? '' : script.removeAt(0);
    if (next is Exception) throw next;
    return next as String;
  }

  @override
  Future<String> chat(List<Map<String, String>> messages,
          {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) =>
      complete(messages.last['content']!, maxTokens: maxTokens, schema: schema);

  @override
  Future<void> dispose() async {}
}
