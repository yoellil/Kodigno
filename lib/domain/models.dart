class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    this.explanation = '',
  });
  final String prompt;
  final List<String> choices;
  final int answerIndex;
  final String explanation;
}

class Flashcard {
  const Flashcard({required this.front, required this.back, this.id});
  final String front;
  final String back;

  /// The card's row in the database, once saved. A card with an id can be edited.
  final int? id;
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
