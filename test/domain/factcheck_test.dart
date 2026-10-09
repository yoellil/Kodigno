import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/factcheck.dart';

const _notes = '''
Rizal was born in Calamba in 1861.
He wrote the novel Noli Me Tangere in Berlin in 1887.
He was executed at Bagumbayan in 1896.

IT workers are not recognized as professionals.
The ACM Code of Ethics was adopted in 1992.
The IEEE Code of Ethics comprises 10 principles.
''';

void main() {
  final index = NoteIndex(_notes);

  test('search finds the passage that settles the question', () {
    final hit = index.search('When was the ACM Code of Ethics adopted? 1992').first;
    expect(hit.text, contains('ACM Code of Ethics was adopted in 1992'));
  });

  test('an answer stated in the notes is supported, with the sentence as its quote', () {
    final r = checkQa(index, 'Where was Rizal executed?', 'Bagumbayan');
    expect(r.ok, isTrue);
    expect(r.exact, isTrue);
    expect(r.quote, 'He was executed at Bagumbayan in 1896.');
  });

  test('a line that leans on the one before it ("He wrote...") still finds its subject', () {
    expect(checkQa(index, 'In which city did Rizal write Noli Me Tangere?', 'Berlin').ok, isTrue);
  });

  test('an invented year, figure or name is not supported', () {
    expect(checkQa(index, 'When was the ACM Code of Ethics adopted?', '1998').ok, isFalse);
    expect(checkQa(index, 'How many principles does the IEEE Code of Ethics comprise?', '12').ok, isFalse);
    expect(checkQa(index, 'Where was Rizal executed?', 'Intramuros').ok, isFalse);
  });

  test('an answer from one fact under a question about another is not supported', () {
    final r = checkQa(index, 'In which year was Rizal born?', '1992');
    expect(r.ok, isFalse);
  });

  test('a question that mixes a date with a rule from elsewhere is not supported', () {
    final r = checkQa(index, 'What is the first principle of the revised IEEE Code?', 'Rizal was born in Calamba');
    expect(r.ok, isFalse);
  });

  test('a paraphrase that flips the meaning is contradicted', () {
    final r = checkQa(index, 'How are IT workers regarded?', 'IT workers are recognized as professionals');
    expect(r.verdict, Verdict.contradicted);
  });

  test('a faithful paraphrase is supported but not exact, so it can go to the judge', () {
    final r = checkQa(index, 'What did Rizal write in Berlin?', 'Noli Me Tangere novel');
    expect(r.ok, isTrue);
    expect(r.exact, isFalse);
    expect(r.passage, isNotNull);
  });

  test('nothing in the notes matches', () {
    expect(checkQa(NoteIndex(''), 'Anything?', 'No').ok, isFalse);
  });

  test('a question that reverses a "not" in the notes is not supported', () {
    final idx = NoteIndex('BART Case Amicus Curiae did not know of this in 1975.');
    expect(checkQa(idx, 'Who was aware of the ECPD Canons in 1975?', 'BART Case Amicus Curiae').ok, isFalse);
    expect(checkQa(idx, 'Who did not know of the ECPD Canons in 1975?', 'BART Case Amicus Curiae').ok, isTrue);
  });

  group('answerTypeProblem', () {
    test('catches an answer of the wrong kind', () {
      expect(answerTypeProblem('What instruments did the laboratory have?', '300'), isNotNull);
      expect(answerTypeProblem('Who wrote it?', '1887'), isNotNull);
      expect(answerTypeProblem('When was he born?', 'Calamba'), isNotNull);
      expect(answerTypeProblem('How many principles are there?', 'Several'), isNotNull);
      expect(answerTypeProblem('Was Rizal discriminated against at UST?', 'No'), isNotNull);
    });

    test('lets sensible answers through', () {
      expect(answerTypeProblem('How many principles are there?', '10'), isNull);
      expect(answerTypeProblem('When was he born?', 'June 19, 1861'), isNull);
      expect(answerTypeProblem('What year was it adopted?', '1912'), isNull);
      expect(answerTypeProblem('Where was he born?', 'Calamba'), isNull);
      expect(answerTypeProblem('What is the age of consent?', '18'), isNull);
    });
  });

  test('a question that says "he" with no name before it is too vague to keep', () {
    expect(hasLooseReference('When did he become an interno at Ateneo?'), isTrue);
    expect(hasLooseReference('Where did they spend the summer?'), isTrue);
    expect(hasLooseReference('What did Rizal give to his mother?'), isFalse);
    expect(hasLooseReference('When did Rizal become an interno at Ateneo?'), isFalse);
  });

  test('two questions with the same answer and mostly the same words are one card', () {
    expect(sameQuestion('What date did Rizal become an interno in Ateneo?', 'June 16, 1875',
        'When did Rizal become an interno at Ateneo?', 'June 16, 1875'), isTrue);
    expect(sameQuestion('Where was Rizal born?', 'Calamba', 'Where was Rizal executed?', 'Bagumbayan'), isFalse);
  });
}
