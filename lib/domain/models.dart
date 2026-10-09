import 'source_ref.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    this.explanation = '',
    this.source,
  });
  final String prompt;
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  /// The page of the student's file this question rests on, once it is known.
  final SourceRef? source;
}

class Flashcard {
  const Flashcard({required this.front, required this.back, this.source});
  final String front;
  final String back;

  /// The page of the student's file this card rests on, once it is known.
  final SourceRef? source;
}

class GeneratedSet {
  const GeneratedSet(this.questions, this.flashcards);
  final List<QuizQuestion> questions;
  final List<Flashcard> flashcards;
}

/// One study question and its short answer, written from a [fact] in the notes.
/// [wrong] holds the model's believable wrong answers, for quiz choices.
class QaItem {
  const QaItem(this.question, this.answer, {this.fact = '', this.wrong = const []});
  final String question;
  final String answer;
  final String fact;
  final List<String> wrong;
}
