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
  const Flashcard({required this.front, required this.back});
  final String front;
  final String back;
}

class GeneratedSet {
  const GeneratedSet(this.questions, this.flashcards);
  final List<QuizQuestion> questions;
  final List<Flashcard> flashcards;
}

/// One study question and its short answer, written from a [fact] in the notes.
/// [wrong] holds the model's believable wrong answers, for quiz choices.
class QaItem {
  const QaItem(this.question, this.answer, {this.fact = '', this.wrong = const [], this.evidence = ''});
  final String question;
  final String answer;
  final String fact;
  final List<String> wrong;

  /// The sentence of the notes that states the answer (checked, not the model's own words).
  final String evidence;
}
