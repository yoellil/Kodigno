import '../domain/models.dart';
import '../domain/summary.dart';
import '../study/teach_judge.dart';

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
  /// With [schema] the server can only emit matching JSON.
  Future<String> chat(List<Map<String, String>> messages,
      {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema});
  Future<void> dispose();
}

abstract class AiEngine {
  /// [onProgress] gets chunksDone / totalChunks (0..1) after each chunk.
  /// With [verifyIn], [notes] is a condensed version (such as a lesson summary)
  /// of the original text: every answer must also be found in [verifyIn], and
  /// its "Term - definition" lines become term cards.
  Future<GeneratedSet> generate(
    String notes, {
    String? verifyIn,
    void Function(double fraction)? onProgress,
  });

  /// Turns [notes] into a study lesson: the big idea, an explained section per
  /// topic and what to remember. Throws [GenerationFailed] if nothing usable.
  Future<LessonSummary> summarize(
    String notes, {
    void Function(double fraction)? onProgress,
  });

  /// Answers the last user turn in [history] using [notes] as the lesson.
  Future<String> ask(String notes, List<ChatTurn> history);

  /// The key ideas of a topic, written from its slides ([slideText]), each one
  /// backed by them. None if it cannot write at least two. An engine that does not
  /// support this gives none.
  Future<List<String>> topicConcepts(String slideText, {String? topic}) async => const [];

  /// What the model makes of a student's [answer] against the topic's [concepts].
  /// Throws [GenerationFailed] if it cannot say, as an engine that does not support
  /// this does.
  Future<TeachBackJudgement> judgeExplanation({
    required List<String> concepts,
    required String answer,
    required String slideText,
  }) async =>
      throw GenerationFailed();
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
