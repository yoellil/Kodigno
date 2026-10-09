import 'dart:math' as math;
import 'dart:ui' show Color;

/// One Kulay color. [fk] = target Flesch-Kincaid grade band, [words] = target
/// story length, [paras] = paragraphs and sentences per paragraph,
/// [q] = questions per story.
class Level {
  const Level(this.name, this.grades, this.bg, this.fg,
      {required this.fk, required this.words, required this.paras, required this.q,
      required this.style, required this.types});
  final String name, grades, style, types;
  final Color bg, fg;
  final (double, double) fk;
  final (int, int) words;
  final (int, int) paras;
  final int q;

  int get firstGrade => int.parse(grades.split('-').first);
}

const levels = [
  Level('Aqua', '1-2', Color(0xFF5CC8D0), Color(0xFF10292B),
      fk: (0, 2.5), words: (45, 100), paras: (3, 3), q: 3,
      style: 'Very short sentences of 5 to 8 words. Only common one- and two-syllable words. Simple past tense.',
      types: 'who, what, and where questions'),
  Level('Lime', '2-3', Color(0xFFA6D84B), Color(0xFF1F2A08),
      fk: (1.5, 3.5), words: (80, 140), paras: (3, 4), q: 3,
      style: 'Short sentences of 6 to 10 words. Common everyday words.',
      types: 'who, what, where, and how many questions'),
  Level('Gold', '3-4', Color(0xFFE8B830), Color(0xFF2B2006),
      fk: (2.5, 4.5), words: (130, 200), paras: (4, 4), q: 4,
      style: 'Sentences of 8 to 12 words. Mostly common words, plus one or two new words that the story makes clear.',
      types: 'who, what, where, and how-did-they-feel questions, plus one question asking what a quoted word from the story means'),
  Level('Orange', '4-5', Color(0xFFEE8A3A), Color(0xFF2A1404),
      fk: (3.5, 5.5), words: (170, 260), paras: (4, 5), q: 4,
      style: 'Sentences of 10 to 14 words with some variety. A clear problem and solution.',
      types: "what, where, how-did-they-feel, and why questions (answered by a 'because' part of a sentence), plus one question asking what a quoted word means"),
  Level('Red', '5-6', Color(0xFFC93C35), Color(0xFFFFFFFF),
      fk: (4.5, 6.5), words: (220, 330), paras: (5, 5), q: 5,
      style: 'Varied sentences of 10 to 16 words. A problem, a turning point, and an ending.',
      types: 'why questions (cause and effect), what-happened questions, how-did-they-feel questions, and one question asking what a quoted word means'),
  Level('Purple', '7-8', Color(0xFF6E46A8), Color(0xFFFFFFFF),
      fk: (6, 8.5), words: (260, 380), paras: (5, 5), q: 5,
      style: 'Varied sentences of 12 to 18 words. Show feelings through actions. A lesson that is shown, not told.',
      types: 'why questions (cause and effect), what-did-they-do-next questions, how-did-they-feel questions, and one question asking what a quoted word means'),
  Level('Brown', '9-10', Color(0xFF7F5235), Color(0xFFFFFFFF),
      fk: (8, 10.5), words: (300, 450), paras: (5, 6), q: 5,
      style: 'Mature, varied sentences. Rich vocabulary. An idea worth discussing, such as a hard choice or a community problem.',
      types: 'why questions (cause and effect), what-happened questions, how-did-they-feel questions, and one question asking what a quoted word means'),
  Level('Olive', '11-12', Color(0xFF5E6A1F), Color(0xFFFFFFFF),
      fk: (10, 13), words: (350, 500), paras: (6, 5), q: 5,
      style: 'Mature, complex sentences with precise academic vocabulary. Explore a real issue from more than one side.',
      types: 'why questions (cause and effect), what-happened questions, how-did-they-feel questions, and one question asking what a quoted word means'),
];

const topics = [
  'Basketball', 'Fiesta', 'Jeepney ride', 'Sari-sari store', 'Typhoon day', 'Rice farm',
  'Fishing village', "Lola's cooking", 'Science fair', 'Mobile games', 'Dance contest',
  'Taal Volcano', 'Space and planets', 'School garden', 'Carabao', 'Coral reef',
];

/// A multiple-choice question. [evidence] = 0-based index into the story's
/// flattened sentences.
class Question {
  const Question(this.question, this.choices, this.answer, this.evidence);
  final String question;
  final List<String> choices;
  final int answer, evidence;

  Map<String, Object> toJson() =>
      {'question': question, 'choices': choices, 'answer': answer, 'evidence': evidence};
  factory Question.fromJson(Map<String, dynamic> j) => Question(j['question'] as String,
      List<String>.from(j['choices'] as List), j['answer'] as int, j['evidence'] as int);
}

class Passage {
  const Passage(this.level, this.title, this.paras, this.questions);
  final int level;
  final String title;
  final List<List<String>> paras;
  final List<Question> questions;
  List<String> get sentences => [for (final p in paras) ...p];
}

/// Fixed so every reader gets the same fair test. Aqua, Gold, Red, Brown.
const placement = [
  Passage(0, 'The Red Kite', [
    ['Ben has a red kite.', 'He runs to the field with Lola.', 'The wind is strong today.'],
    ['Ben lets the kite go up.', 'It flies over the big tree.', 'Lola claps her hands.', 'Then the kite gets stuck in the tree.'],
    ['A tall boy climbs up and gets it for Ben.', 'Ben says, "Thank you!"'],
  ], [
    Question("What color is Ben's kite?", ['Red', 'Blue', 'Green', 'Yellow'], 0, 0),
    Question('Who goes to the field with Ben?', ['His dad', 'Lola', 'His teacher', 'His dog'], 1, 1),
    Question('Where does the kite get stuck?', ['On a house', 'In the tree', 'In the river', 'On a car'], 1, 6),
  ]),
  Passage(2, 'The Sari-Sari Store', [
    ['Every morning, Mika helps her grandmother open their small sari-sari store.', 'They sell bread, candy, soap, and cold drinks to their neighbors.', 'Mika likes to count the coins and arrange the snacks in neat rows.'],
    ['One hot afternoon, the electricity went out on the whole street.', 'The drinks in the refrigerator began to get warm.', 'Mika had an idea.', 'She filled a big basin with ice from the fish vendor and put the bottles inside.'],
    ['Soon, tired tricycle drivers lined up to buy cold drinks.', 'Her grandmother smiled and said that Mika had saved the day.'],
  ], [
    Question('What does Mika like to do at the store?', ['Count coins and arrange snacks', 'Cook rice for customers', 'Sweep the street', 'Drive a tricycle'], 0, 2),
    Question('Why did the drinks start to get warm?', ['The ice melted', 'The electricity went out', 'The sun hit the store', 'The door was left open'], 1, 3),
    Question('Where did Mika get the ice?', ['From the fish vendor', 'From her school', 'From the refrigerator', 'From a tricycle driver'], 0, 6),
  ]),
  Passage(4, 'The Mangrove Planters', [
    ['When the typhoon season ended, the fishing village of San Roque looked tired and broken.', 'Strong waves had washed away part of the shore, and several houses near the water had been damaged.'],
    ['Teacher Rosa told her Grade 6 class that an old mangrove forest had once protected the village.', 'Its thick roots held the mud in place and slowed down the waves before they reached the houses.', 'Over the years, people had cut the mangroves for firewood, and the shore had become unprotected.'],
    ['The class decided to act.', 'Every Saturday for two months, the students collected mangrove seedlings and planted them in the soft mud at low tide.', 'It was muddy, tiring work, and some seedlings were lost to the tide.', 'Still, by the end of the school year, a thin green line of young trees stood along the shore.'],
  ], [
    Question('How did the mangroves protect the village?', ['Their roots held mud and slowed the waves', 'They gave shade to the fishermen', 'They kept tourists away', 'They stopped the rain from falling'], 0, 3),
    Question('Why had the shore become unprotected?', ['The typhoon destroyed the school', 'People cut the mangroves for firewood', 'The fish swam away', 'The students moved the mud'], 1, 4),
    Question("Which word best describes the students' work?", ['Easy', 'Quick', 'Difficult', 'Boring'], 2, 7),
  ]),
  Passage(6, "The Weaver's Choice", [
    ["For three generations, Lola Ines's family had woven abel cloth on wooden looms in a small town in Ilocos.", 'The patterns, passed down from mother to daughter, were never written on paper; they lived in the hands and memories of the weavers.'],
    ["When a clothing company offered to buy her designs and print them by machine, Ines's granddaughter Carla was thrilled.", 'The money would repair their leaking roof and pay for her college tuition.', 'Lola Ines, however, was quiet for a long time before she answered.'],
    ['She explained that a printed copy would look like abel cloth but would carry none of its story, and that the young people of the town would stop learning to weave if machines did the work.', 'In the end, the family reached a compromise: the company could use the designs only if it paid the town to run a weaving school.', "Carla, who had once found weaving slow and old-fashioned, became one of the school's first students."],
  ], [
    Question('How were the weaving patterns kept alive in the family?', ['They were printed in a book', 'They were remembered and taught by hand', 'They were sold to a company', 'They were kept in a museum'], 1, 1),
    Question("Why was Lola Ines worried about the company's offer?", ['The company would pay too little', 'Young people might stop learning to weave', 'The machines would break the looms', 'Carla would move away to college'], 1, 5),
    Question('What does the ending suggest about Carla?', ['She still thinks weaving is useless', "She has come to value her family's tradition", 'She wants to work for the clothing company', 'She is angry with her grandmother'], 1, 7),
  ]),
];

/// A past score, newest first.
typedef Score = ({int level, int pct});

/// Streaks only count scores at the current level, so a level change resets them.
({int up, int down}) streaks(int level, List<Score> recent) {
  var up = 0, down = 0;
  for (final a in recent) {
    if (a.level != level || a.pct < 80) break;
    up++;
  }
  for (final a in recent) {
    if (a.level != level || a.pct >= 60) break;
    down++;
  }
  return (up: up, down: down);
}

/// Move up: 80%+ on 3 stories in a row. Move down: below 60% on 2 in a row.
int nextLevel(int level, List<Score> recent) {
  final s = streaks(level, recent);
  if (s.up >= 3) return math.min(level + 1, levels.length - 1);
  if (s.down >= 2) return math.max(level - 1, 0);
  return level;
}

/// Pass (2 of 3) to try the next passage. Failing one places the reader on
/// the color between it and the last passage they passed.
({int? next, int? level}) placementStep(int i, bool passed) {
  if (passed && i < placement.length - 1) return (next: i + 1, level: null);
  if (passed) return (next: null, level: placement[i].level);
  return (next: null, level: i == 0 ? 0 : placement[i].level - 1);
}
