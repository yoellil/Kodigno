import 'models.dart';
import 'source_ref.dart';

/// [set] with the page behind each flashcard and quiz question looked up in
/// [locator]. Without a locator (no pages in the notes) it is returned as it is.
GeneratedSet attachSources(GeneratedSet set, SourceLocator? locator) {
  if (locator == null) return set;
  return GeneratedSet(
    [
      for (final q in set.questions)
        QuizQuestion(
          prompt: q.prompt,
          choices: q.choices,
          answerIndex: q.answerIndex,
          explanation: q.explanation,
          // The explanation is the fact the question was made from; failing that,
          // the question with its right answer.
          source: locator.locate(q.explanation.isNotEmpty ? q.explanation : '${q.prompt} ${q.choices[q.answerIndex]}'),
        ),
    ],
    [
      for (final c in set.flashcards)
        Flashcard(front: c.front, back: c.back, source: locator.locate('${c.front} ${c.back}')),
    ],
  );
}
