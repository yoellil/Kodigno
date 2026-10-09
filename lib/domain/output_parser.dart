import 'dart:convert';

import 'models.dart';

/// Parses model output into a [GeneratedSet]. Invalid items are dropped;
/// throws [FormatException] if nothing valid remains.
GeneratedSet parseGeneratedSet(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const FormatException('no JSON object in model output');
  }
  final decoded = jsonDecode(raw.substring(start, end + 1));
  if (decoded is! Map) throw const FormatException('JSON is not an object');

  final questions = <QuizQuestion>[];
  for (final q in (decoded['questions'] as List? ?? const [])) {
    if (q is! Map) continue;
    final prompt = (q['prompt'] as String?)?.trim() ?? '';
    final choices = [
      for (final c in (q['choices'] as List? ?? const []))
        if (c is String && c.trim().isNotEmpty) c.trim()
    ];
    final answer = q['answer_index'];
    if (prompt.isEmpty || choices.length < 2 || choices.length > 6) continue;
    if (answer is! int || answer < 0 || answer >= choices.length) continue;
    questions.add(QuizQuestion(
      prompt: prompt,
      choices: choices,
      answerIndex: answer,
      explanation: (q['explanation'] as String?)?.trim() ?? '',
    ));
  }

  final cards = <Flashcard>[];
  for (final c in (decoded['flashcards'] as List? ?? const [])) {
    if (c is! Map) continue;
    final front = (c['front'] as String?)?.trim() ?? '';
    final back = (c['back'] as String?)?.trim() ?? '';
    if (front.isNotEmpty && back.isNotEmpty) {
      cards.add(Flashcard(front: front, back: back));
    }
  }

  if (questions.isEmpty && cards.isEmpty) {
    throw const FormatException('no valid questions or flashcards');
  }
  return GeneratedSet(questions, cards);
}
