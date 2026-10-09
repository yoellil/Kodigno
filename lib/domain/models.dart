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
