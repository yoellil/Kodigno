import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/card_assist.dart';

void main() {
  group('buildCardAssistMessages', () {
    test('a system message with the rules, then one user message with the term', () {
      final m = buildCardAssistMessages(want: AssistField.definition, term: 'Mitochondria');
      expect(m.map((x) => x['role']), ['system', 'user']);
      expect(m.first['content'], cardAssistSystemPrompt);
      expect(m.first['content'], allOf(contains('at most 30 words'), contains('empty string')));
      expect(m.last['content'], allOf(contains('TERM: Mitochondria'), contains('Write the DEFINITION'), contains('{"definition": "..."}')));
    });

    test('for the other direction it gives the definition and asks for the term', () {
      final m = buildCardAssistMessages(want: AssistField.term, definition: 'The powerhouse of the cell.');
      expect(m.last['content'], allOf(contains('DEFINITION: The powerhouse of the cell.'), contains('Write the short TERM'), contains('{"term": "..."}')));
    });

    test('the lesson notes that cover the subject are included, others are not', () {
      final notes = '${'Plants make sugar from light. ' * 80}\nMitochondria make ATP for the cell.\n${'Rizal was born in Calamba. ' * 80}';
      final m = buildCardAssistMessages(want: AssistField.definition, term: 'Mitochondria', notes: notes, setTitle: 'Biology');
      expect(m.last['content'], allOf(contains('NOTES from the lesson "Biology"'), contains('Mitochondria make ATP')));
      expect(m.last['content']!.length, lessThan(2200));
    });

    test('no notes means no notes section, and a long input is clipped', () {
      final m = buildCardAssistMessages(want: AssistField.definition, term: 'x' * 900);
      expect(m.last['content'], isNot(contains('NOTES')));
      expect(m.last['content']!.length, lessThan(600));
    });
  });

  test('the schema asks for one key', () {
    expect((cardAssistSchema(AssistField.term)['required'] as List), ['term']);
    expect(((cardAssistSchema(AssistField.definition)['properties'] as Map).keys), ['definition']);
  });

  group('parseCardAssist', () {
    test('reads the suggestion, also inside prose', () {
      expect(parseCardAssist('{"definition":"The cell\'s power plant."}', AssistField.definition), "The cell's power plant.");
      expect(parseCardAssist('Sure! {"term":"Mitochondria"} done', AssistField.term), 'Mitochondria');
    });

    test('drops a label, quotes and a closing full stop on a term', () {
      expect(parseCardAssist('{"definition":"Definition: \\"Makes ATP.\\""}', AssistField.definition), 'Makes ATP.');
      expect(parseCardAssist('{"term":"Term: The Cell Membrane."}', AssistField.term), 'The Cell Membrane');
    });

    test('an empty answer means the model was not sure', () {
      expect(parseCardAssist('{"definition":"  "}', AssistField.definition), '');
    });

    test('a very long definition is cut to a brief one', () {
      final long = 'It is a structure that does a very large number of things, ${'and then more things ' * 30}.';
      expect(parseCardAssist('{"definition":"$long"}', AssistField.definition).length, lessThanOrEqualTo(245));
    });

    test('anything else is a FormatException', () {
      expect(() => parseCardAssist('no json', AssistField.term), throwsFormatException);
      expect(() => parseCardAssist('{"definition":"x"}', AssistField.term), throwsFormatException);
      expect(() => parseCardAssist('{"term":3}', AssistField.term), throwsFormatException);
    });
  });

  group('where a suggestion came from', () {
    test('mentionedIn finds a subject in the notes, ignoring case and punctuation', () {
      expect(mentionedIn('Mercado', 'Mercado: adopted in 1731.'), isTrue);
      expect(mentionedIn('domingo lam-co', 'It was adopted by Domingo Lam-co.'), isTrue);
      expect(mentionedIn('Photosynthesis', 'Mercado: adopted in 1731.'), isFalse);
      expect(mentionedIn('ab', 'ab cd'), isFalse); // too short to mean anything
      expect(mentionedIn('x term', ''), isFalse);
    });
  });

  group('withoutEchoedTerm', () {
    test('drops a lead-in that repeats the term', () {
      expect(withoutEchoedTerm("Mercado means 'market'.", 'Mercado'), 'Market.');
      expect(withoutEchoedTerm('Photosynthesis is the process plants use.', 'Photosynthesis'), 'The process plants use.');
      expect(withoutEchoedTerm('Paciano: the elder brother of Rizal.', 'Paciano'), 'The elder brother of Rizal.');
    });

    test('leaves a definition that does not start with the term', () {
      const d = 'The cell\'s power plant.';
      expect(withoutEchoedTerm(d, 'Mitochondria'), d);
      expect(withoutEchoedTerm('Mitochondria-rich tissue burns more fuel.', 'Mitochondria'), 'Mitochondria-rich tissue burns more fuel.');
      expect(withoutEchoedTerm(d, ''), d);
    });
  });
}
