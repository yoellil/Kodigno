// Kulay's language checks. The AI writes; these rules decide whether what it
// wrote makes sense. Ported from Kulay's nlp.js, whose grounding ideas (an
// answer must be stated in the text, the question must not give it away,
// wrong choices must be the same kind of thing) came from domain/prompt.dart.
import 'dart:math' as math;

import 'levels.dart';

final _rng = math.Random();

// ---------- words ----------

final _stop = ('the and but for with was were are been its his her their they she you that this what who whom whose '
        'where when why how which did does had has have from into after before not all can will would could there then them very '
        'also just about over under again some any each than too only own same other more most such our your him out off upon onto')
    .split(' ')
    .toSet();

/// Content words cut to 4 letters, so "snacks" matches "snack" and "played" matches "plays".
Set<String> stems(String s) => {
      for (final m in RegExp('[a-z]+').allMatches(s.toLowerCase()))
        if (m[0]!.length > 2 && !_stop.contains(m[0]!)) m[0]!.substring(0, math.min(4, m[0]!.length)),
    };
int _overlap(Set<String> a, Set<String> b) => a.where(b.contains).length;
Set<String> _minus(Set<String> a, Set<String> b) => a.where((w) => !b.contains(w)).toSet();
String norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z0-9' ]+"), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
String _bare(String s) => norm(s).replaceFirst(RegExp(r'^(the|a|an) '), '');

/// [phrase] appears in [text] as whole words.
bool _has(String text, String phrase) => phrase.isNotEmpty && ' ${norm(text)} '.contains(' $phrase ');
int _wordCount(String s) => norm(s).split(' ').where((w) => w.isNotEmpty).length;
String _clip(String s, [int n = 40]) => s.length > n ? '${s.substring(0, n)}...' : s;
String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
final _digit = RegExp(r'\d');
List<T> _shuffled<T>(Iterable<T> list) => list.toList()..shuffle(_rng);

// ---------- word lists (the "gazetteers") ----------

Set<String> _set(String s) => s.split(' ').toSet();
final _personWords = _set('mother mom mama nanay father dad papa tatay grandmother grandfather grandma grandpa lola lolo sister brother '
    'kuya ate cousin cousins aunt uncle tita tito friend friends classmate classmates teacher teachers coach neighbor neighbors '
    'vendor vendors driver drivers farmer farmers fisherman fishermen captain doctor nurse boy boys girl girls kids children child '
    'baby family team player players student students principal priest mayor crowd people everyone villagers tourists customers '
    'baker cook chef guard owner parents volunteers officials scientist scientists leader elders');
final _placeWords = _set('school classroom market house home kitchen yard backyard garden park plaza field court gym beach sea ocean '
    'river lake mountain volcano farm ricefield forest church chapel store shop library hospital clinic street road bridge town city '
    'village barangay port pier boat jeepney bus tricycle room bedroom hall stage canteen carinderia bakery reef island hill camp '
    'office terminal shore coast stall center province');

/// A "where" answer that names a city gets other cities as wrong choices; a
/// province gets other provinces. Kept apart so a wrong choice is never a
/// place inside the answer (Coron is in Palawan).
const cities = ['Manila', 'Quezon City', 'Cebu', 'Davao', 'Iloilo', 'Baguio', 'Tacloban', 'Vigan', 'Dumaguete', 'Cagayan de Oro',
  'Naga', 'Legazpi', 'Zamboanga', 'Marikina', 'Bacolod', 'Pasig', 'Makati', 'Puerto Princesa', 'Tagbilaran', 'Lipa'];
const provinces = ['Palawan', 'Pampanga', 'Bohol', 'Batangas', 'Laguna', 'Bulacan', 'Cavite', 'Ilocos', 'Albay', 'Antique', 'Aklan',
  'Samar', 'Leyte', 'Nueva Ecija', 'Batanes'];
const _placeNames = [...cities, ...provinces, 'Bicol', 'Siargao', 'Mindanao', 'Luzon', 'Visayas', 'Taal', 'Philippines', 'Tondo',
  'Boracay', 'Mayon', 'Banaue', 'Coron'];
List<String>? _placeGroup(String s) =>
    [cities, provinces].where((g) => g.any((p) => _has(s, norm(p)))).firstOrNull;

/// Character names the story planner uses. A wrong choice naming one who is
/// not in the story was made up.
const girlNames = ['Mika', 'Ana', 'Bea', 'Joy', 'Liza', 'Rosa', 'Tala', 'Ligaya', 'Nina', 'Carla', 'Maya', 'Rina', 'Sofia', 'Andrea', 'Divina', 'Aya'];
const boyNames = ['Paolo', 'Jun', 'Miguel', 'Carlo', 'Rafael', 'Nico', 'Enzo', 'Marco', 'Gabriel', 'Jomar', 'Kiko', 'Ramon', 'Tonyo', 'Luis', 'Dindo', 'Rey'];
final _nameSet = {for (final n in [...girlNames, ...boyNames]) n.toLowerCase()};
final _placeTokens = {
  for (final p in _placeNames)
    for (final w in norm(p).split(' '))
      if (w.length > 2) w,
};
final _timeWords = _set('morning afternoon evening night noon midnight dawn sunrise sunset day days week weeks weekend month months '
    'year years today tonight yesterday tomorrow monday tuesday wednesday thursday friday saturday sunday january february april '
    'june july august september october november december summer christmas holiday holidays fiesta lunch breakfast dinner merienda '
    'recess hour hours minute minutes later early season');
final _numberWords = 'zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty'.split(' ');
final _colors = 'red blue green yellow orange purple pink white black brown gray gold silver'.split(' ');
final _feelPos = 'happy glad excited proud thankful grateful joyful hopeful relieved calm amazed brave determined cheerful delighted confident pleased curious inspired motivated satisfied peaceful eager thrilled encouraged loved safe'.split(' ');
final _feelNeg = 'sad scared afraid angry worried nervous tired lonely upset confused disappointed embarrassed anxious frustrated bored sorry jealous shy unhappy terrified annoyed overwhelmed heartbroken hopeless guilty ashamed helpless discouraged hurt stressed'.split(' ');
final _feelMid = 'surprised sleepy'.split(' ');
final _valenceOf = {
  for (final w in _feelPos) w: 'pos',
  for (final w in _feelNeg) w: 'neg',
  for (final w in _feelMid) w: 'mid',
};

/// 'pos', 'neg', 'mid', or null for the first feeling word in [s].
String? valence(String s) => norm(s).split(' ').map((t) => _valenceOf[t]).nonNulls.firstOrNull;

/// Capitalized words that are not people.
final _notNames = _set('i filipino filipinos english tagalog god christmas easter pinoy okay oh yes no hello mr mrs ms dr let');
const _titles = r'Aling|Mang|Lola|Lolo|Tita|Tito|Kuya|Ate|Teacher|Coach|Doctor|Mr\.|Mrs\.|Ms\.|Dr\.';
final _english = _set('the a an and to of in on at was is he she it his her they them we i you for with as had that but said not were be my');

final _generic = {
  'person': ['the teacher', 'a neighbor', 'the coach', 'a classmate', 'the vendor', 'the driver'],
  'place': ['the school', 'the market', 'the church', 'the beach', 'the river', 'the park', 'the plaza', 'the library'],
  'time': ['in the morning', 'at night', 'after lunch', 'on Sunday', 'before school', 'at noon'],
  'feeling': [..._feelPos, ..._feelNeg],
  'color': _colors,
};

// ---------- stories ----------

int _syllables(String word) {
  var w = word.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
  if (w.length <= 3) return 1;
  w = w.replaceFirst(RegExp(r'(?:[^laeiouy]es|ed|[^laeiouy]e)$'), '').replaceFirst(RegExp('^y'), '');
  final n = RegExp('[aeiouy]{1,2}').allMatches(w).length;
  return n == 0 ? 1 : n;
}

/// Flesch-Kincaid grade level.
/// ponytail: vowel-group syllable guess, good to about half a grade.
({int words, double grade}) measure(List<String> sentences) {
  final words = [for (final m in RegExp(r"[A-Za-z][A-Za-z']*").allMatches(sentences.join(' '))) m[0]!];
  if (words.isEmpty) return (words: 0, grade: 0.0);
  final syl = words.fold(0, (n, w) => n + _syllables(w));
  final grade = 0.39 * (words.length / sentences.length) + 11.8 * (syl / words.length) - 15.59;
  return (words: words.length, grade: (grade * 10).round() / 10);
}

final _abbr = RegExp(r'\b(Mr|Mrs|Ms|Dr|Jr|Sr|St|Sto|Sta|Ma|Engr|Atty)\.');
const _hold = '․'; // stands in for the dot of "Mr." while splitting

/// Story text -> paragraphs of sentences. A dialogue tag (`"Wait!" said Ben.`)
/// stays with its quote. Any other sentence that starts lowercase is kept, so
/// [lintStory] can reject the draft.
List<List<String>> splitStory(String text) {
  final seen = <String>{}; // small models sometimes repeat a sentence word for word
  final cleaned = text
      .replaceAll(RegExp(r'\*\*|__|\*|^#+\s*', multiLine: true), '')
      .replaceAllMapped(_abbr, (m) => '${m[1]}$_hold');
  var paras = [
    for (final p in cleaned.split(RegExp(r'\n+')))
      () {
        final out = <String>[];
        final flat = p.replaceAll(RegExp(r'\s+'), ' ');
        for (final m in RegExp(r'''[^.!?]+(?:[.!?]+["'”’)]*|$)''').allMatches(flat)) {
          final t = m[0]!.trim();
          // A sentence with no end mark was cut off by the model; drop it.
          if (t.isEmpty || seen.contains(t.toLowerCase()) || !RegExp(r'''[.!?]["'”’)]*$''').hasMatch(t)) continue;
          seen.add(t.toLowerCase());
          // Rejoin a dialogue tag or a thought that trails off ("Maybe... why not?").
          if (out.isNotEmpty && RegExp('^[a-z]').hasMatch(t) && RegExp(r'''([.!?,]["'”’]|\.\.\.|…)$''').hasMatch(out.last)) {
            out.last = '${out.last} $t';
          } else {
            out.add(t);
          }
        }
        return [for (final s in out) s.replaceAll(_hold, '.')];
      }(),
  ].where((p) => p.isNotEmpty).toList();
  // Small models often skip paragraph breaks; one wall of text is hard for young readers.
  if (paras.length == 1 && paras[0].length > 6) {
    final all = paras[0];
    paras = [for (var i = 0; i < all.length; i += 4) all.sublist(i, math.min(i + 4, all.length))];
  }
  return paras;
}

/// The main character, picked by code so the model cannot drop or garble them.
class StoryPlan {
  const StoryPlan({required this.name, this.gender = 'girl', this.age = 10, this.place = ''});
  final String name, gender, place;
  final int age;
}

/// Problems that make a draft unusable, whatever its reading level.
/// Empty [hard] = the story makes sense.
({List<String> hard, int words, double grade}) lintStory(
    List<List<String>> paras, StoryPlan plan, Level l, String topic) {
  final sentences = [for (final p in paras) ...p];
  final text = sentences.join(' ');
  final m = measure(sentences);
  final hard = <String>[];
  final broken = sentences.where((s) => RegExp('^[^A-Za-z0-9]*[a-z]').hasMatch(s)).firstOrNull;
  if (broken != null) hard.add('a sentence starts in the middle: "${_clip(broken)}"');
  if (RegExp(r'\[[^\]]*\]|\{[^}]*\}|_{3,}|\b(?:protagonist|main character)\b', caseSensitive: false).hasMatch(text)) {
    hard.add('it has a placeholder like [Name] or "the protagonist"');
  }
  final name = RegExp('\\b${RegExp.escape(plan.name)}\\b');
  if (!name.hasMatch(sentences.firstOrNull ?? '')) hard.add('the first sentence does not name ${plan.name}');
  if (name.allMatches(text).length < 2) hard.add('${plan.name} is named fewer than 2 times');
  if (RegExp('\\b(cat|dog|pet|puppy|kitten|bird|horse|carabao|friend|brother|sister|cousin|classmate)\\s*,?\\s*(named\\s+)?${RegExp.escape(plan.name)}\\b',
          caseSensitive: false)
      .hasMatch(text)) {
    hard.add('the name ${plan.name} is also used for someone else');
  }
  final min = (l.words.$1 * 0.7).round();
  if (m.words < min) hard.add('it is too short (${m.words} words, needs at least $min)');
  if (m.words > l.words.$2 * 1.6) hard.add('it is too long (${m.words} words)');
  // The same sentence said again in other words ("Mom would pack snacks." ... "Mom packed snacks.").
  final seen = <Set<String>>[];
  for (final s in sentences) {
    final w = stems(s);
    if (w.length >= 3 && seen.any((p) => _overlap(w, p) / {...w, ...p}.length >= 0.6)) {
      hard.add('it repeats itself: "${_clip(s)}"');
      break;
    }
    seen.add(w);
  }
  final t = stems(topic);
  if (t.isNotEmpty && _overlap(t, stems(text)) == 0) hard.add('it is not about $topic');
  final words = [for (final w in RegExp("[a-z']+").allMatches(text.toLowerCase())) w[0]!];
  if (words.isNotEmpty && words.where(_english.contains).length / words.length < 0.12) {
    hard.add('it is not in English');
  }
  return (hard: hard, words: m.words, grade: m.grade);
}

// ---------- questions ----------

const _kindLabel = {
  'person': '"who"', 'place': '"where"', 'time': '"when"', 'number': '"how many"', 'feeling': 'feeling', 'color': 'color',
};

String questionKind(String question) {
  final s = question.toLowerCase().trim();
  bool t(String p) => RegExp(p).hasMatch(s);
  if (t(r'\bmeans?\b|\bmeaning\b') && t('''["'“‘][a-z-]+["'”’]''')) return 'vocab';
  if (t(r'^why\b')) return 'other';
  if (t(r'^(who|whom|whose)\b')) return 'person';
  if (t(r'^where\b')) return 'place';
  if (t(r'^when\b|\bwhat time\b|\bwhat day\b')) return 'time';
  if (t(r'^how (many|much|old|long)\b')) return 'number';
  if (t(r'\b(feel|felt|feeling|feelings|emotion|mood)\b')) return 'feeling';
  if (t(r'\bwhat colou?r\b')) return 'color';
  return 'other';
}

/// People, places and times named in the story: wrong choices that sound like they belong.
typedef Entities = ({List<String> people, List<String> places, List<String> times});

bool fitsKind(String answer, String kind, Entities ent) {
  final n = norm(answer);
  final toks = n.split(' ');
  switch (kind) {
    case 'person':
      return toks.any(_personWords.contains) || ent.people.any((p) => _has(n, norm(p)));
    case 'place':
      return toks.any((t) => _placeWords.contains(t) || _placeWords.contains(t.replaceFirst(RegExp(r's$'), '')) || _placeTokens.contains(t)) ||
          RegExp(r'^(at|in|on|near|inside|outside|behind|under|to|into|by|beside)\b').hasMatch(n);
    case 'time':
      return toks.any(_timeWords.contains) || _digit.hasMatch(n) || RegExp(r'^(after|before|during|when|while|until)\b').hasMatch(n);
    case 'number':
      return _digit.hasMatch(n) || toks.any(_numberWords.contains);
    case 'feeling':
      return toks.any(_valenceOf.containsKey);
    case 'color':
      return toks.any(_colors.contains);
    default:
      return true;
  }
}

Entities entities(List<String> sentences, StoryPlan? plan) {
  final text = sentences.join(' ');
  final people = <String>{if (plan != null) plan.name};
  for (final m in RegExp('\\b(?:$_titles)\\s+[A-Z][a-z]+').allMatches(text)) {
    people.add(m[0]!);
  }
  for (final s in sentences) {
    final toks = s.split(RegExp(r'\s+'));
    for (var i = 1; i < toks.length; i++) {
      // A name is a capitalized word in the middle of a sentence, not after "the", not a place or a day.
      if (RegExp('''^["'“‘(]''').hasMatch(toks[i])) continue;
      final w = RegExp('^([A-Z][a-z]+)').firstMatch(toks[i])?[1];
      if (w == null || RegExp(r'''[.!?]["'”’]?$''').hasMatch(toks[i - 1])) continue;
      final lw = w.toLowerCase();
      if (RegExp(r'^(the|a|an)$', caseSensitive: false).hasMatch(toks[i - 1]) ||
          _notNames.contains(lw) || _placeTokens.contains(lw) || _timeWords.contains(lw)) {
        continue;
      }
      people.add(w);
    }
  }
  final places = <String>{
    for (final p in _placeNames)
      if (RegExp('\\b${RegExp.escape(p)}\\b').hasMatch(text)) p,
  };
  for (final m in RegExp(r'\bthe ([a-z]+)\b', caseSensitive: false).allMatches(text)) {
    if (_placeWords.contains(m[1]!.toLowerCase())) places.add('the ${m[1]!.toLowerCase()}');
  }
  final times = <String>{};
  for (final m in RegExp(r'\b(?:in the|on|at|every|that|one|last|next|after|before)\s+(?:the\s+)?([a-z]+)\b', caseSensitive: false)
      .allMatches(text)) {
    if (_timeWords.contains(m[1]!.toLowerCase())) times.add(m[0]!.toLowerCase());
  }
  return (people: people.toList(), places: places.toList(), times: times.toList());
}

/// The answer is stated in sentence [s]: word for word, or most of its own
/// words (not the question's) are there.
bool _stated(String answer, String question, String s) {
  final sup = _minus(stems(answer), stems(question));
  if (_has(s, _bare(answer))) return sup.isNotEmpty || _digit.hasMatch(answer);
  return sup.isNotEmpty && _overlap(sup, stems(s)) / sup.length >= 0.75;
}

/// The sentence says the opposite: "The plants were not just weeds" does not answer "weeds".
bool _denied(String answer, String s) {
  final toks = norm(s).split(' ');
  final a = _bare(answer).split(' ');
  for (var i = 0; i + a.length <= toks.length; i++) {
    if (toks.sublist(i, i + a.length).join(' ') != a.join(' ')) continue;
    if (toks.sublist(math.max(0, i - 3), i).any((t) => RegExp(r"^(not|never|no|nor)$|n't$").hasMatch(t))) return true;
  }
  return false;
}

/// "very proud" -> "very sad", "3 hours" -> "4 hours": wrong choices with the same shape as the answer.
List<String> _variants(String answer, String kind) {
  List<String> swap(String word, List<String> others) => [
        for (final o in others)
          answer.replaceFirst(RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false), o),
      ];
  final toks = norm(answer).split(' ');
  if (kind == 'feeling') {
    final f = toks.where(_valenceOf.containsKey).firstOrNull;
    if (f == null) return [];
    final v = _valenceOf[f];
    return swap(f, _shuffled(v == 'pos' ? _feelNeg : v == 'neg' ? _feelPos : [..._feelPos, ..._feelNeg]));
  }
  if (kind == 'color') {
    final c = toks.where(_colors.contains).firstOrNull;
    return c == null ? [] : swap(c, _shuffled(_colors.where((x) => x != c)));
  }
  final group = kind == 'place' ? _placeGroup(answer) : null;
  final town = group?.where((p) => _has(answer, norm(p))).firstOrNull;
  if (town != null) return swap(town, _shuffled(group!.where((t) => t != town)));
  final d = RegExp(r'\d+').firstMatch(answer);
  if (d != null) {
    final v = int.parse(d[0]!);
    return [
      for (final k in [1, -1, 2, 3, -2])
        if (v + k > 0) answer.replaceFirst(d[0]!, '${v + k}'),
    ];
  }
  final w = toks.where(_numberWords.contains).firstOrNull;
  if (w != null) {
    final i = _numberWords.indexOf(w);
    return swap(w, [
      for (final k in [i + 1, i - 1, i + 2, i + 3])
        if (k > 0 && k < _numberWords.length) _numberWords[k],
    ]);
  }
  return [];
}

/// Up to 3 wrong choices that are clearly wrong: the same kind as the answer,
/// not stated in the proof sentence, and not true in another sentence that
/// matches the question just as well.
List<String> _pickWrong(String answer, String kind, String question, int ev, List<String> sentences, Entities ent,
    List<String> preferred) {
  final a = _bare(answer);
  final qS = stems(question);
  final asked = _minus(qS, stems(answer)); // what the question is about
  final need = math.max(1, (asked.length / 2).ceil());
  final evidence = ev >= 0 && ev < sentences.length ? sentences[ev] : '';
  final evS = stems(evidence);
  final story = sentences.join(' ');
  final group = kind == 'place' ? _placeGroup(answer) : null;
  final storyWords = {for (final w in norm(story).split(' ')) w.replaceFirst(RegExp(r"'s$"), '')};
  final numeric = _digit.hasMatch(answer);
  final out = <String>[];
  final taken = [a];
  void add(String raw, {bool generic = false}) {
    if (out.length >= 3) return;
    final c = raw.replaceAll(RegExp(r'\s+'), ' ').replaceFirst(RegExp(r'[.!]+$'), '').trim();
    final l = _bare(c);
    if (l.isEmpty || taken.any((t) => t.contains(l) || l.contains(t))) return;
    if (_has(question, l) || _digit.hasMatch(c) != numeric || _wordCount(c) > 2 * _wordCount(answer) + 2) return;
    if (_kindLabel.containsKey(kind) && !fitsKind(c, kind, ent)) return;
    if (group != null && !group.any((p) => _has(c, norm(p)))) return; // a city for a city, not "the beach"
    if (kind == 'feeling' && valence(c) == valence(answer) && valence(answer) != 'mid') return; // "glad" is not wrong for "happy"
    if (_has(evidence, l)) return;
    final sup = _minus(stems(c), qS);
    if (sup.isEmpty && !numeric) return; // only echoes the question, so it sounds right
    if (sup.isNotEmpty && _overlap(sup, evS) == sup.length) return;
    for (var i = 0; i < sentences.length; i++) {
      if (i != ev && _has(sentences[i], l) && _overlap(asked, stems(sentences[i])) >= need) return;
    }
    if (generic && _has(story, l)) return;
    // Names a character who is not in the story.
    if (norm(c).split(' ').map((t) => t.replaceFirst(RegExp(r"'s$"), '')).any((t) => _nameSet.contains(t) && !storyWords.contains(t))) return;
    taken.add(l);
    out.add(c);
  }

  preferred.forEach(add);
  _variants(answer, kind).forEach(add);
  _shuffled(switch (kind) { 'person' => ent.people, 'place' => ent.places, 'time' => ent.times, _ => const <String>[] }).forEach(add);
  for (final c in _shuffled(_generic[kind] ?? const <String>[])) {
    add(c, generic: true);
  }
  return out;
}

/// A checked question: [q] on success, [why] with the reason it was thrown out.
class Checked {
  const Checked.ok(Question this.q, this.kind) : why = null;
  const Checked.fail(String this.why)
      : q = null,
        kind = '';
  final Question? q;
  final String kind;
  final String? why;
}

/// Model output -> a question whose answer is stated in its proof sentence,
/// with 3 clearly wrong choices, shuffled.
/// [raw] = {evidence: 1-based sentence number, question, answer, wrong: [...]}.
Checked checkQuestion(Map<String, dynamic> raw, List<String> sentences, Entities ent, StoryPlan? plan) {
  var question = '${raw['question'] ?? ''}'.replaceAll(RegExp(r'\s+'), ' ').trim();
  final answer = '${raw['answer'] ?? ''}'
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirst(RegExp(r'^(the answer is|answer:)\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'[.!]+$'), '')
      .trim();
  if (plan != null) {
    question = question.replaceAllMapped(RegExp(r"\bthe (protagonist|main character)('s)?\b", caseSensitive: false),
        (m) => plan.name + (m[2] ?? ''));
  }
  if (question.isEmpty || answer.isEmpty) return const Checked.fail('it was badly formed');
  question = question.replaceFirst(RegExp(r'[.!]*\??$'), '?');
  if (_wordCount(answer) > 8) return Checked.fail('the answer "${_clip(answer)}" is too long');

  String at(int i) => i >= 0 && i < sentences.length ? sentences[i] : '';
  final kind = questionKind(question);
  final evRaw = raw['evidence'];
  var ev = (evRaw is num ? evRaw.toInt() : int.tryParse('$evRaw') ?? 0) - 1;
  if (kind == 'vocab') {
    final word = RegExp('''["'“‘]([A-Za-z-]+)["'”’]''').firstMatch(question)?[1];
    if (word == null) return const Checked.fail('the quoted word is missing');
    bool inSentence(int i) => RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false).hasMatch(at(i));
    if (!inSentence(ev)) ev = [for (var i = 0; i < sentences.length; i++) i].where(inSentence).firstOrNull ?? -1;
    if (ev < 0) return Checked.fail('the word "$word" is not in the story');
    if (_bare(answer) == _bare(word)) return const Checked.fail('the answer repeats the word it should explain');
  } else {
    if (_minus(stems(answer), stems(question)).isEmpty && !_digit.hasMatch(answer)) {
      return Checked.fail('the answer "${_clip(answer)}" only repeats the question');
    }
    final a = stems(answer);
    if (a.length > 1 && _overlap(a, stems(question)) * 2 >= a.length) {
      return Checked.fail('the answer "${_clip(answer)}" gives itself away');
    }
    // The proof is the sentence that states the answer (word for word beats a
    // close match) and best matches the question. The model's pick wins a tie.
    int score(String s) {
      if (!_stated(answer, question, s)) return 0;
      return (_has(s, _bare(answer)) ? 10 : 1) + _overlap(stems(question), stems(s));
    }

    final scores = sentences.map(score).toList();
    final top = scores.fold(0, math.max);
    if (top == 0) return Checked.fail('the answer "${_clip(answer)}" is not stated in the story');
    if (ev < 0 || ev >= scores.length || scores[ev] != top) ev = scores.indexOf(top);
    if (_overlap(stems(question), stems(sentences[ev])) == 0) {
      return const Checked.fail('the question is not about the sentence that answers it');
    }
    if (!fitsKind(answer, kind, ent)) return Checked.fail('a ${_kindLabel[kind]} question got the answer "${_clip(answer)}"');
    if (_denied(answer, sentences[ev])) return Checked.fail('the story denies "${_clip(answer)}"');
  }
  final w = raw['wrong'];
  final preferred = w is List ? [for (final x in w) '$x'] : w == null ? <String>[] : ['$w'];
  final wrong = _pickWrong(answer, kind, question, ev, sentences, ent, preferred);
  if (wrong.length < 3) return Checked.fail('not enough clearly wrong choices for "${_clip(question)}"');
  final choices = [answer, ...wrong].map(_cap).toList();
  final order = _shuffled([0, 1, 2, 3]);
  return Checked.ok(Question(question, [for (final i in order) choices[i]], order.indexOf(0), ev), kind);
}

// ---------- teacher skills and word help ----------

/// The reading skills a question can practice, for the teacher's report.
const skills = ['Details', 'Cause and effect', 'Feelings', 'Word meaning'];

String skillOf(String question) {
  final kind = questionKind(question);
  if (kind == 'vocab') return 'Word meaning';
  if (kind == 'feeling') return 'Feelings';
  if (RegExp(r'^\s*why\b|\bbecause\b|\bwhat (made|caused)\b', caseSensitive: false).hasMatch(question)) {
    return 'Cause and effect';
  }
  return 'Details';
}

/// A word's meaning from the AI: short, and not explained with the word
/// itself. Null = fine, otherwise the problem.
String? checkMeaning(String word, String meaning) {
  final n = _wordCount(meaning);
  if (n < 2) return 'the meaning is too short';
  if (n > 20) return 'the meaning is too long';
  if (_overlap(stems(word), stems(meaning)) > 0) return 'the meaning uses the word "$word" itself';
  if (RegExp(r'\[[^\]]*\]|\{[^}]*\}').hasMatch(meaning)) return 'the meaning has a placeholder';
  return null;
}
