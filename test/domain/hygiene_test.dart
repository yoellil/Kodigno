import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/hygiene.dart';

void main() {
  group('looksLikeCitation', () {
    test('flags bibliography entries, links and numbered references', () {
      for (final s in [
        'Smith, J., & Lee, K. (2020). Cell biology today. Journal of Biology, 12(3), 45-67.',
        'Retrieved from https://example.com/cells',
        'See www.example.org for details',
        'doi:10.1000/182',
        '[3] Brown, A. Introduction to Genetics. Oxford University Press, 2018.',
        'Alberts, B. (2014). Molecular Biology of the Cell. Garland Science.',
      ]) {
        expect(looksLikeCitation(s), isTrue, reason: s);
      }
    });

    test('leaves ordinary facts alone', () {
      for (final s in [
        'Mitochondria make ATP.',
        'Rizal was born in Calamba in 1861.',
        'Smith et al. found that sleep improves memory.',
        'The treaty was signed in 1648 (after thirty years of war).',
        'World War II ended in 1945.',
      ]) {
        expect(looksLikeCitation(s), isFalse, reason: s);
      }
    });
  });

  group('stripReferences', () {
    test('drops a trailing References section and everything after it', () {
      const text = 'Cells are small.\nThey have a nucleus.\nMore facts here.\nReferences\n'
          'Smith, J. (2020). Cells. Journal of Biology, 1(2), 3-4.\nJones, K. (2019). Nuclei.';
      expect(stripReferences(text), 'Cells are small.\nThey have a nucleus.\nMore facts here.');
    });

    test('a heading near the top only drops the entries under it', () {
      const text = 'Sources\n[1] Smith, J. Cells. Press, 2020.\nCells are small.\n'
          'The nucleus holds the DNA.\nMitochondria make energy.';
      expect(stripReferences(text),
          'Cells are small.\nThe nucleus holds the DNA.\nMitochondria make energy.');
    });

    test('removes inline markers such as [3] and [1, 2]', () {
      expect(stripReferences('Cells are small [3]. They divide [1, 2].'),
          'Cells are small. They divide.');
    });

    test('text without references is unchanged', () {
      expect(stripReferences('One.\nTwo.'), 'One.\nTwo.');
    });
  });

  group('answers', () {
    test('cleanAnswer drops "The answer is" and wrapping quotes', () {
      expect(cleanAnswer('The answer is Calamba'), 'Calamba');
      expect(cleanAnswer('Answer: Calamba'), 'Calamba');
      expect(cleanAnswer('"Calamba"'), 'Calamba');
      expect(cleanAnswer('Answering machines'), 'Answering machines');
    });

    test('isPlaceholderAnswer catches empty-meaning answers', () {
      for (final s in ['answer', 'Answer.', 'The answer', 'N/A', 'None of the above', '', 'The answer is']) {
        expect(isPlaceholderAnswer(s), isTrue, reason: s);
      }
      expect(isPlaceholderAnswer('Calamba'), isFalse);
      expect(isPlaceholderAnswer('Answer key'), isFalse);
    });

    test('normalizeChoice gives every choice one style', () {
      expect(normalizeChoice('calamba.'), 'Calamba');
      expect(normalizeChoice('"Manila"'), 'Manila');
      expect(normalizeChoice('  100  degrees Celsius. '), '100 degrees Celsius');
      expect(normalizeChoice('the U.S.'), 'The U.S.');
      expect(normalizeChoice('Responsible and ethical AI.'), 'Responsible and ethical AI');
    });
  });

  group('fixSquashedText', () {
    test('puts spaces back in run-together headings', () {
      expect(fixSquashedText('forIntellectualPropertyActof2008'), 'for Intellectual Property Actof 2008');
      expect(fixSquashedText('GeneralAgreementonTariffsandTrade'), 'General Agreementon Tariffsand Trade');
    });

    test('leaves normal lines, including names like JavaScript, alone', () {
      const line = 'We wrote the app in JavaScript and TypeScript for iPhone users.';
      expect(fixSquashedText(line), line);
    });
  });

  test('withoutQuestionEcho drops a lead-in that repeats the question verb', () {
    expect(withoutQuestionEcho('It expresses the conscience of the profession', 'What does the ACM Code of Ethics express?'),
        'The conscience of the profession');
    expect(withoutQuestionEcho('It protects inventions', 'What does a copyright cover?'), 'It protects inventions');
    expect(withoutQuestionEcho('Calamba', 'Where was Rizal born?'), 'Calamba');
  });

  test('withoutQuestionEcho drops the subject the question already names, and its verb', () {
    expect(withoutQuestionEcho('The CVE database is an example of a national database', 'What is the CVE database?'),
        'An example of a national database');
    expect(withoutQuestionEcho('State-sponsored hackers steal government secrets and sabotage networks',
            'What do state-sponsored hackers do?'),
        'Steal government secrets and sabotage networks');
    expect(withoutQuestionEcho('The Internet of Things enables people to connect billions of devices',
            'What does the Internet of Things (IoT) enable?'),
        'People to connect billions of devices');
    // one named word, or too little left, is not an echo
    expect(withoutQuestionEcho('InfraGard shares cyber intelligence', 'What does InfraGard share?'),
        'InfraGard shares cyber intelligence');
    expect(withoutQuestionEcho('External attacks exploit weaknesses', 'What do external attacks do?'),
        'External attacks exploit weaknesses');
    expect(withoutQuestionEcho('Network services like DNS and HTTP', 'Which services are prime targets?'),
        'Network services like DNS and HTTP');
  });
}
