import '../domain/models.dart';

class QuizSession {
  QuizSession(this.questions) : _answers = List.filled(questions.length, null);

  final List<QuizQuestion> questions;
  final List<int?> _answers;
  int index = 0;

  bool get isDone => index >= questions.length;
  QuizQuestion get current => questions[index];

  void answer(int choice) {
    if (isDone) throw StateError('quiz already finished');
    _answers[index++] = choice;
  }

  int get score {
    var n = 0;
    for (var i = 0; i < questions.length; i++) {
      if (_answers[i] == questions[i].answerIndex) n++;
    }
    return n;
  }

  List<Map<String, Object>> get results => [
        for (var i = 0; i < questions.length; i++)
          {
            'q': i,
            'chosen': _answers[i] ?? -1,
            'correct': _answers[i] == questions[i].answerIndex,
          }
      ];
}
