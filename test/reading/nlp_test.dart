// Ported from Kulay's test.js, including real bad outputs the model produced.
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/reading/levels.dart';
import 'package:kodigno/reading/nlp.dart';
import 'package:kodigno/reading/story_engine.dart' show difficulty;

List<Score> at(int level, List<int> pcts) => [for (final p in pcts) (level: level, pct: p)];

Checked check(Map<String, dynamic> raw, List<String> s, String name) =>
    checkQuestion(raw, s, entities(s, StoryPlan(name: name)), StoryPlan(name: name));

void main() {
  group('level rules', () {
    test('move up on 3 strong scores at the current color', () {
      expect(nextLevel(2, at(2, [80, 100, 90])), 3);
      expect(nextLevel(2, at(2, [80, 100, 70])), 2);
      expect(nextLevel(7, at(7, [100, 100, 100])), 7, reason: 'Olive is the top');
      expect(nextLevel(3, [...at(3, [100, 100]), ...at(2, [100])]), 3);
    });
    test('move down on 2 weak scores', () {
      expect(nextLevel(4, at(4, [40, 50, 100])), 3);
      expect(nextLevel(4, at(4, [40, 60])), 4);
      expect(nextLevel(0, at(0, [0, 0])), 0, reason: 'Aqua is the bottom');
      expect(streaks(4, [...at(4, [30]), ...at(5, [30])]), (up: 0, down: 1));
    });
    test('placement steps and passages', () {
      expect(placementStep(0, false), (next: null, level: 0));
      expect(placementStep(0, true), (next: 1, level: null));
      expect(placementStep(1, false), (next: null, level: 1));
      expect(placementStep(3, true), (next: null, level: 6));
      for (final p in placement) {
        for (final q in p.questions) {
          expect(q.evidence < p.sentences.length && q.answer < 4, isTrue, reason: q.question);
        }
      }
    });
  });

  test('readability', () {
    final easy = measure(['Ben has a red kite.', 'He runs to the field.']);
    final hard = measure([
      'The community deliberately implemented comprehensive environmental regulations, considerably transforming agricultural productivity.'
    ]);
    expect(easy.grade < 2 && hard.grade > 12, isTrue);
    expect(difficulty(levels[0], easy.grade).off, 0, reason: 'Aqua has no floor');
    expect(difficulty(levels[0], hard.grade).off > 0, isTrue);
  });

  group('splitting', () {
    test('quotes stay with speaker, titles hold, repeats and cut-offs drop', () {
      expect(splitStory('Mr. Cruz smiled. "Run!" said Ana. Mr. Cruz smiled.\nThey started a project called'), [
        ['Mr. Cruz smiled.', '"Run!" said Ana.']
      ]);
      expect(splitStory('Rina thought, "Maybe... why not start with the seeds?"'), [
        ['Rina thought, "Maybe... why not start with the seeds?"']
      ]);
      expect(splitStory('The wind was strong. felt the weight of the storm.'), [
        ['The wind was strong.', 'felt the weight of the storm.']
      ]);
      expect(splitStory('**Mika** lived in Naga. *She* was happy.'), [
        ['Mika lived in Naga.', 'She was happy.']
      ]);
    });
  });

  group('story check', () {
    const plan = StoryPlan(name: 'Mika', place: 'Cebu', age: 15);
    final short = Level('Test', '1-2', levels[0].bg, levels[0].fg,
        fk: levels[0].fk, words: (20, 100), paras: levels[0].paras, q: 3, style: '', types: '');
    test('screenshot bug: starts mid-way, name missing, too short', () {
      final cebu = splitStory(
          "wheezed as she stepped into the narrow alleyway leading to her mother's grocery store.\nThe wind was strong.\nfelt the weight of the storm.");
      final hard = lintStory(cebu, plan, levels[6], 'Typhoon day').hard;
      expect(hard.any((p) => p.contains('starts in the middle')), isTrue, reason: '$hard');
      expect(hard.any((p) => p.contains('first sentence')), isTrue);
      expect(hard.any((p) => p.contains('too short')), isTrue);
    });
    test('good, off topic, not English, placeholder, repeats, name reuse', () {
      final good = splitStory(
          'Mika lives in Cebu. Mika has a red ball.\nShe plays basketball with Jun at the park. Jun throws the ball.\nMika makes the shot. She is very happy.');
      expect(lintStory(good, plan, short, 'Basketball').hard, isEmpty);
      expect(lintStory(good, plan, short, 'Space and planets').hard.any((p) => p.contains('not about')), isTrue);
      expect(
          lintStory(splitStory('Mika fue al mercado con su abuela. Mika compró pan y queso para la familia.'), plan, short, 'mercado')
              .hard
              .any((p) => p.contains('English')),
          isTrue);
      expect(
          lintStory(splitStory('[Name] went home. Mika was happy. Mika played basketball.'), plan, short, 'Basketball')
              .hard
              .any((p) => p.contains('placeholder')),
          isTrue);
      final echo = splitStory(
          "Mika's mom would pack a big bag of snacks. Mika danced at the fiesta.\nMika's mom packed a big bag of snacks. Mika went home happy.");
      expect(lintStory(echo, plan, short, 'Fiesta').hard.any((p) => p.contains('repeats itself')), isTrue);
      expect(
          lintStory(splitStory('Mika lived in Baguio. Mika loved her pet cat, Mika, very much.'), plan, short, 'my pet cat')
              .hard
              .any((p) => p.contains('someone else')),
          isTrue);
    });
  });

  group('question check', () {
    final market = [
      'Mika and her lola went to the market.',
      'At noon, Jun sold fish at the market.',
      'Lola bought bread from Aling Nena.',
      'Mika felt happy because her team won.'
    ];
    Question ok(Checked c) {
      expect(c.why, isNull);
      return c.q!;
    }

    test('mammals: not in the story', () {
      final typhoon = [
        'Mika wheezed as she stepped into the narrow alleyway.',
        'It was the typhoon season in Cebu, and the city had been under a heavy warning.'
      ];
      expect(
          check({'evidence': 2, 'question': 'What is the protagonist most concerned about during the typhoon season?', 'answer': 'Mammals of the typhoon', 'wrong': ['Street vendors', 'Poison gas', 'Other people']}, typhoon, 'Mika').why,
          matches('not stated|gives itself away'));
      expect(check({'evidence': 1, 'question': 'What did Mika see in the alleyway?', 'answer': 'Mammals', 'wrong': []}, typhoon, 'Mika').why,
          contains('not stated'));
    });
    test('who gets people, never the proof sentence or another true answer', () {
      final q = ok(check({'evidence': 2, 'question': 'Who sold fish at the market?', 'answer': 'Jun', 'wrong': ['the fish', 'Market', 'Jun']}, market, 'Mika'));
      expect(q.choices[q.answer], 'Jun');
      expect(q.evidence, 1);
      for (final c in q.choices) {
        expect(RegExp('fish|market', caseSensitive: false).hasMatch(c), isFalse, reason: c);
      }
      final went = ok(check({'evidence': 1, 'question': 'Who went to the market?', 'answer': 'Mika', 'wrong': []}, market, 'Mika'));
      expect(went.choices, isNot(contains('Jun')));
    });
    test('proof moves to the answer; feelings get opposite feelings', () {
      final q = ok(check({'evidence': 1, 'question': 'How did Mika feel when her team won?', 'answer': 'happy', 'wrong': ['glad', 'joyful']}, market, 'Mika'));
      expect(q.evidence, 3);
      expect(q.choices.length, 4);
      for (var i = 0; i < 4; i++) {
        if (i != q.answer) expect(valence(q.choices[i]), 'neg', reason: q.choices[i]);
      }
    });
    test('wrong kind, give-away, protagonist', () {
      expect(check({'evidence': 3, 'question': 'Where did Lola buy bread?', 'answer': 'Aling Nena', 'wrong': []}, market, 'Mika').why, contains('where'));
      expect(check({'evidence': 2, 'question': 'Who sold fish at the market, Jun?', 'answer': 'Jun', 'wrong': []}, market, 'Mika').why, contains('only repeats'));
      final named = ok(check({'evidence': 4, 'question': 'Why did the protagonist feel happy?', 'answer': 'her team won', 'wrong': ['she lost her ball', 'it rained', 'school ended']}, market, 'Mika'));
      expect(named.question, 'Why did Mika feel happy?');
    });
    test('made-up name, echo choice, borrowed answers', () {
      final store = ok(check({'evidence': 1, 'question': 'What did Lola buy?', 'answer': 'bread', 'wrong': ["Mika's toy car", 'fish', 'rice', 'milk']}, ['Lola bought bread from Aling Nena.'], 'Luis'));
      expect(store.choices.any((c) => c.contains('Mika')), isFalse);
      final reef = ['Determined to help, Nina started cleaning up the trash.', 'Nina decided to organize a beach clean-up event with friends.'];
      final why = ok(check({'evidence': 1, 'question': 'Why did Nina organize a beach clean-up event?', 'answer': 'to help', 'wrong': ['To clean the beach', 'to play games', 'to win a prize', 'to sleep']}, reef, 'Nina'));
      expect(why.choices, isNot(contains('To clean the beach')));
      expect(check({'evidence': 1, 'question': 'Why was Divina fascinated by the Taal Volcano?', 'answer': 'The majestic Taal Volcano', 'wrong': []}, ['Divina had always been fascinated by the majestic Taal Volcano.'], 'Divina').why,
          matches('gives itself away|only repeats'));
      expect(check({'evidence': 1, 'question': "What happened to Jun's brother?", 'answer': 'caught in the rain', 'wrong': ['stuck in traffic']}, ["Jun's brother was caught in the rain.", "Jun's father was a respected teacher."], 'Jun').why,
          contains('not enough'));
    });
    test('negation, paraphrase, word-for-word proof', () {
      expect(check({'evidence': 1, 'question': 'What were the plants?', 'answer': 'weeds', 'wrong': ['trees', 'flowers', 'vegetables']}, ['The plants were not just weeds, but a sign of the past.'], 'Tonyo').why,
          contains('denies'));
      expect(check({'evidence': 1, 'question': 'What does Ramon do when he helps his dad?', 'answer': 'Drills holes in the ground', 'wrong': []}, ['Ramon helps his dad by digging holes in the ground.'], 'Ramon').why,
          contains('not stated'));
      final ran = ok(check({'evidence': 1, 'question': 'Where did Carla run?', 'answer': 'To the playground', 'wrong': ['To her house', 'To the store', 'To the church']}, ["Carla couldn't play basketball on her own.", 'Carla woke up early and ran to the playground.'], 'Carla'));
      expect(ran.evidence, 1);
    });
    test('provinces, numbers, towns', () {
      final prov = ok(check({'evidence': 1, 'question': 'Where did Jomar see the Fiesta?', 'answer': 'Palawan', 'wrong': ['Coron', 'Makati']}, ['Jomar was eager to see the Fiesta in Palawan.'], 'Jomar'));
      for (var i = 0; i < 4; i++) {
        if (i != prov.answer) expect(provinces, contains(prov.choices[i]));
      }
      final many = ok(check({'evidence': 1, 'question': 'How many mangoes did Jun buy?', 'answer': '3', 'wrong': []}, ['Jun bought 3 mangoes at the market.'], 'Jun'));
      expect(many.choices.every((c) => RegExp(r'^\d+$').hasMatch(c)), isTrue, reason: '${many.choices}');
      final where = ok(check({'evidence': 1, 'question': 'Where did Paolo live?', 'answer': 'Tacloban', 'wrong': ['New York City', 'the beach']}, ['Paolo lived in Tacloban, a small town.', 'Paolo went to the park.'], 'Paolo'));
      for (var i = 0; i < 4; i++) {
        if (i != where.answer) expect(cities, contains(where.choices[i]));
      }
    });
  });

  test('skills and word help', () {
    expect(skillOf('Why did Nina organize a clean-up?'), 'Cause and effect');
    expect(skillOf('How did Mika feel when her team won?'), 'Feelings');
    expect(skillOf('What does the word "bustling" mean?'), 'Word meaning');
    expect(skillOf('Where did Paolo live?'), 'Details');
    expect(checkMeaning('bustling', 'full of busy, moving people'), isNull);
    expect(checkMeaning('excited', 'feeling excitement'), contains('uses the word'));
    expect(checkMeaning('happy', ''), contains('too short'));
    expect(checkMeaning('happy', 'a feeling that you get when many good things happen to you and your friends at the same time all day long'),
        contains('too long'));
  });
}
