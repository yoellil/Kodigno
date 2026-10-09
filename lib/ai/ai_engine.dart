import '../domain/models.dart';

abstract class LlmRuntime {
  Future<String> complete(String prompt, {int maxTokens = 1024});
  Future<void> dispose();
}

abstract class AiEngine {
  /// [onProgress] gets chunksDone / totalChunks (0..1) after each chunk.
  Future<GeneratedSet> generate(String notes, {void Function(double fraction)? onProgress});
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
