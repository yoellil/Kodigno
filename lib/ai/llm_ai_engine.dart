import '../domain/models.dart';
import '../domain/output_parser.dart';
import '../domain/prompt.dart';
import '../models/tier.dart';
import 'ai_engine.dart';

class LlmAiEngine implements AiEngine {
  LlmAiEngine(
    this.runtime,
    this.tier, {
    this.maxChunks = 6,
    this.maxAttempts = 3,
  });

  final LlmRuntime runtime;
  final Tier tier;
  final int maxChunks;
  final int maxAttempts;

  @override
  Future<GeneratedSet> generate(
    String notes, {
    void Function(double fraction)? onProgress,
  }) async {
    final chunks = chunkText(notes, tier.chunkChars).take(maxChunks).toList();
    final questions = <QuizQuestion>[];
    final cards = <Flashcard>[];
    final seenQ = <String>{};
    final seenC = <String>{};
    var succeeded = 0;

    for (var i = 0; i < chunks.length; i++) {
      final set = await _generateChunk(chunks[i]);
      onProgress?.call((i + 1) / chunks.length);
      if (set == null) continue;
      succeeded++;
      for (final q in set.questions) {
        if (seenQ.add(q.prompt.toLowerCase().trim())) questions.add(q);
      }
      for (final c in set.flashcards) {
        if (seenC.add(c.front.toLowerCase().trim())) cards.add(c);
      }
    }
    if (succeeded == 0) throw GenerationFailed();
    return GeneratedSet(questions, cards);
  }

  Future<GeneratedSet?> _generateChunk(String chunk) async {
    final prompt = buildPrompt(
      chunk,
      questions: tier.questionsPerChunk,
      cards: tier.cardsPerChunk,
    );
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final set = parseGeneratedSet(await runtime.complete(prompt));
        // Small models sometimes parrot the prompt's example: drop those items.
        final cleaned = GeneratedSet(
          [
            for (final q in set.questions)
              if (q.prompt.trim() != exampleQuestionPrompt) q,
          ],
          [
            for (final c in set.flashcards)
              if (c.front.trim() != exampleCardFront) c,
          ],
        );
        if (cleaned.questions.isEmpty && cleaned.flashcards.isEmpty)
          continue; // retry
        return cleaned;
      } on FormatException {
        continue; // malformed output: retry
      }
    }
    return null;
  }

  @override
  Future<void> dispose() => runtime.dispose();
}
