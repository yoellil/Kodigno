import '../domain/models.dart';

/// One message in a tutor chat. [role] is 'user' or 'assistant'.
class ChatTurn {
  const ChatTurn(this.role, this.text);
  final String role;
  final String text;
}

abstract class LlmRuntime {
  /// With [schema] (a JSON schema) the server can only emit matching JSON.
  Future<String> complete(String prompt,
      {int maxTokens = 1024, Map<String, Object?>? schema});

  /// Chat completion over [messages], each {'role': ..., 'content': ...}.
  Future<String> chat(List<Map<String, String>> messages, {int maxTokens = 512});
  Future<void> dispose();
}

abstract class AiEngine {
  /// [onProgress] gets chunksDone / totalChunks (0..1) after each chunk.
  Future<GeneratedSet> generate(
    String notes, {
    void Function(double fraction)? onProgress,
  });

  /// Answers the last user turn in [history] using [notes] as the lesson.
  Future<String> ask(String notes, List<ChatTurn> history);
  Future<void> dispose();
}

class GenerationFailed implements Exception {
  @override
  String toString() => "Couldn't generate, try again.";
}

/// Thrown by a runtime when the model cannot run (out of memory, crash,
/// file missing). Never retried; triggers tier fallback in the controller.
class ModelUnavailableException implements Exception {
  ModelUnavailableException(this.message);
  final String message;
  @override
  String toString() => 'Model unavailable: $message';
}
