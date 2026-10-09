// The local AI pipeline, ported from Kulay's ai.js. The model writes a story
// and questions; Kulay checks the work twice before a reader sees it.
// Check 1: the story makes sense and fits the color (lintStory + reading grade).
// Check 2: every answer is stated in its proof sentence (checkQuestion) and
// the AI can answer its own question from the story alone.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import '../ai/ai_engine.dart';
import 'levels.dart';
import 'nlp.dart';

/// Stories saved by an older pipeline are never served again.
const pipelineVersion = 2;

/// How urgent a model call is. Lower runs first.
abstract final class Priority {
  static const word = 0, reader = 1, background = 2;
}

/// One piece of work on the model: a story or a word. [priority] can be
/// raised while it runs (a reader starts waiting on a background story).
class Job {
  Job(this.priority);
  int priority;
  bool cancelled = false;
}

class JobCancelled implements Exception {}

class StoryFailed implements Exception {
  StoryFailed(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One model call at a time; a waiting call with a lower priority number goes next.
class CallLine {
  var _busy = false;
  final _waiting = <(Job, Completer<void>)>[];

  Future<T> run<T>(Job job, Future<T> Function() call) async {
    if (_busy) {
      final c = Completer<void>();
      _waiting.add((job, c));
      await c.future;
    } else {
      _busy = true;
    }
    try {
      return await call();
    } finally {
      if (_waiting.isEmpty) {
        _busy = false;
      } else {
        var best = 0;
        for (var i = 1; i < _waiting.length; i++) {
          if (_waiting[i].$1.priority < _waiting[best].$1.priority) best = i;
        }
        _waiting.removeAt(best).$2.complete(); // stays busy: handed straight on
      }
    }
  }
}

/// Signed distance from the level's target grade band (0 = inside).
({double off, double cost}) difficulty(Level l, double grade) {
  // A band starting at 0 (Aqua) has no floor: very simple text can score below zero.
  final tooEasy = l.fk.$1 > 0 && grade < l.fk.$1 - 0.5;
  final off = tooEasy ? grade - l.fk.$1 : grade > l.fk.$2 + 0.5 ? grade - l.fk.$2 : 0.0;
  return (off: off, cost: off.abs());
}

/// A finished, checked story.
class WrittenStory {
  WrittenStory(this.level, this.topic, this.title, this.paras, this.questions, this.checks);
  final int level;
  final String topic, title;
  final List<List<String>> paras;
  final List<Question> questions;
  final Map<String, Object?> checks;
  List<String> get sentences => [for (final p in paras) ...p];
}

/// step(n, detail) reports progress on the 8 steps shown to the reader.
typedef OnStep = void Function(int step, String detail);

const _towns = ['Iloilo', 'Cebu', 'Davao', 'Baguio', 'Bohol', 'Batangas', 'Pampanga', 'Tacloban', 'Vigan', 'Palawan', 'Dumaguete',
  'Cagayan de Oro', 'Naga', 'Legazpi', 'Zamboanga', 'Laguna', 'Marikina', 'Bacolod', 'Bulacan', 'Nueva Ecija'];
const _topicTown = {'taal volcano': 'Batangas', 'coral reef': 'Palawan', 'rice farm': 'Nueva Ecija'};

const _safe = 'Everything must be safe and kind for children: no violence, romance, brand names, or scary content.';

const _storySys = '''You write short reading passages for Filipino students who are learning to read in English. $_safe
Write in English, in the past tense, about made-up characters in the Philippines. A Filipino word such as merienda or barangay is fine if the story makes its meaning clear.
Do not state dates, numbers, or facts you are not sure are true.
Every sentence starts with a capital letter and ends with a period, question mark, or exclamation mark. Call the main character by name, never "the protagonist". Never repeat a sentence. Do not put the title inside the story.''';

// Small models ignore word counts but follow a paragraph-by-paragraph plan.
const _beats = [
  'Introduce {name} and the place. Start with "{name}".',
  'A problem starts or something new happens.',
  '{name} tries to deal with it.',
  'Someone sees it differently, or the problem gets harder.',
  'A turning point.',
  'How it ends and what {name} learns.',
];
const _beatPick = {
  3: [0, 1, 5],
  4: [0, 1, 2, 5],
  5: [0, 1, 2, 4, 5],
  6: [0, 1, 2, 3, 4, 5],
};
Map<String, Object?> _storySchema(int n) => {
      'type': 'object',
      'properties': {
        'title': {'type': 'string'},
        'paragraphs': {'type': 'array', 'items': {'type': 'string'}, 'minItems': n, 'maxItems': n},
      },
      'required': ['title', 'paragraphs'],
    };

const _qSys = '''You write reading comprehension questions for students. $_safe
Every answer is copied from one numbered sentence of the story. The question never contains its answer. Wrong answers are the same kind of thing as the right answer, and are false in the story.''';
const _checkSys = 'You are a careful student taking a reading test. Read the story and answer the question using only the story.';

const Map<String, Object?> _qItem = {
  'type': 'object',
  'properties': {
    'evidence': {'type': 'integer'},
    'question': {'type': 'string'},
    'answer': {'type': 'string'},
    'wrong': {'type': 'array', 'items': {'type': 'string'}, 'minItems': 3, 'maxItems': 3},
  },
  'required': ['evidence', 'question', 'answer', 'wrong'],
};
Map<String, Object?> _qSchema(int n) => {
      'type': 'object',
      'properties': {
        'questions': {'type': 'array', 'items': _qItem, 'minItems': n, 'maxItems': n},
      },
      'required': ['questions'],
    };
const Map<String, Object?> _checkSchema = {
  'type': 'object',
  'properties': {
    'answer': {'type': 'string', 'enum': ['A', 'B', 'C', 'D']},
  },
  'required': ['answer'],
};

String _qRules(String name) => '''For each question:
- "evidence": the number of ONE sentence that states the answer.
- "question": a clear question about that sentence. Call characters by name (for example $name), never "the protagonist".
- "answer": the right answer, 1 to 6 words copied from that sentence.
- "wrong": 3 wrong answers of the same kind (a name for a name, a place for a place, a feeling for a feeling, a number for a number) that are false in the story.
Example: for sentence [3] "Mika sold cold drinks to the tricycle drivers." write {"evidence": 3, "question": "Who bought cold drinks from Mika?", "answer": "the tricycle drivers", "wrong": ["the fish vendors", "her classmates", "the teachers"]}''';

const _wordSys = '''You explain English words to Filipino students who are learning English. $_safe
Give the meaning the word has in the given sentence, using simple words a child already knows. Never use the word itself in the meaning.''';
const Map<String, Object?> _wordSchema = {
  'type': 'object',
  'properties': {
    'meaning': {'type': 'string'},
    'synonym': {'type': 'string'},
  },
  'required': ['meaning', 'synonym'],
};

class _BadJson implements Exception {}

class StoryEngine {
  StoryEngine(this.runtime, {this.maxDrafts = 4, this.modelName = 'the local AI', math.Random? random})
      : _rng = random ?? math.Random();

  /// The model server. Asked for on every call, so a tier change is picked up.
  final Future<LlmRuntime> Function() runtime;

  /// 4 drafts on Standard and High; 3 on Basic, which then falls back to a saved story.
  int maxDrafts;
  String modelName;
  final math.Random _rng;
  final line = CallLine();
  final _wordCache = <String, ({String meaning, String? synonym})>{};

  T _pick<T>(List<T> list) => list[_rng.nextInt(list.length)];

  StoryPlan plan(int level, String topic) {
    final girl = _rng.nextBool();
    return StoryPlan(
      name: _pick(girl ? girlNames : boyNames),
      gender: girl ? 'girl' : 'boy',
      age: levels[level].firstGrade + 6 + _rng.nextInt(2),
      place: _topicTown[topic.toLowerCase()] ?? _pick(_towns),
    );
  }

  /// Small models sometimes run away inside JSON. Output is capped; broken JSON is retried once.
  Future<Map<String, dynamic>> _chat(Job job, String system, String user, Map<String, Object?> schema,
      {double temperature = 0.8, int maxTokens = 1500}) async {
    for (var tryNo = 1;; tryNo++) {
      if (job.cancelled) throw JobCancelled();
      final rt = await runtime();
      final text = await line.run(
          job,
          () => rt.chat([
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': user},
              ], maxTokens: maxTokens, temperature: temperature, schema: schema));
      if (job.cancelled) throw JobCancelled();
      try {
        final out = jsonDecode(text);
        if (out is Map<String, dynamic>) return out;
      } on FormatException {
        // falls through to the retry
      }
      if (tryNo >= 2) throw _BadJson();
    }
  }

  // Steps 2-3: write, then Check 1. A draft with a hard problem is never used.
  // Among good drafts, keep the one closest to the color's reading grade.
  Future<({String title, List<List<String>> paras, double grade, int words, int drafts})> _writeStory(
      Job job, int level, String topic, StoryPlan plan, OnStep step) async {
    final l = levels[level];
    final (n, per) = l.paras;
    final beats = [
      for (final (i, b) in _beatPick[n]!.indexed) '${i + 1}. ${_beats[b].replaceAll('{name}', plan.name)} ($per sentences)'
    ].join('\n');
    final brief = 'Write a story about: $topic.\nMain character: ${plan.name}, a ${plan.age}-year-old ${plan.gender} from ${plan.place}. '
        'Use the name ${plan.name} in the first sentence and several more times.\nReader level: Grade ${l.grades}.\n'
        'Length: ${l.words.$1} to ${l.words.$2} words.\nStyle: ${l.style}\nWrite exactly $n paragraphs:\n$beats';
    ({String title, List<List<String>> paras, double grade, int words, double cost})? best;
    var feedback = '';
    var drafts = 0;
    final target = 'target ${l.fk.$1}-${l.fk.$2}';
    for (var draft = 1; draft <= maxDrafts; draft++) {
      drafts = draft;
      step(2, draft == 1 ? '${plan.name}, ${plan.age}, from ${plan.place}. About ${l.words.$1}-${l.words.$2} words.' : 'Draft $draft');
      final Map<String, dynamic> out;
      try {
        // Room for the longest allowed story plus JSON, and no more.
        out = await _chat(job, _storySys, brief + feedback, _storySchema(n), maxTokens: (l.words.$2 * 2.2).round() + 300);
      } on _BadJson {
        step(3, 'Draft $draft came back broken. Rewriting.');
        continue;
      }
      final paragraphs = out['paragraphs'] is List ? [for (final p in out['paragraphs'] as List) '$p'] : <String>[];
      final paras = splitStory(paragraphs.join('\n'));
      final lint = lintStory(paras, plan, l, topic);
      final d = difficulty(l, lint.grade);
      if (lint.hard.isEmpty && (best == null || d.cost < best.cost)) {
        final title = '${out['title'] ?? ''}'.trim().replaceFirst(RegExp(r'[.,;:]+$'), '');
        best = (title: title, paras: paras, grade: lint.grade, words: lint.words, cost: d.cost);
      }
      if (lint.hard.isEmpty && d.cost == 0) {
        step(3, 'Grade ${lint.grade} ($target), ${lint.words} words, ${plan.name} named, every sentence complete. Passed.');
        break;
      }
      final problems = [
        ...lint.hard,
        if (d.off > 0) 'it measured reading grade ${lint.grade}, too hard for Grade ${l.grades}',
        if (d.off < 0) 'it measured reading grade ${lint.grade}, too easy for Grade ${l.grades}',
      ];
      // ponytail: a small model rarely hits grade 10+; a clean draft within 1.5 grades beats minutes of retries.
      final closeEnough = best != null && draft >= 2 && best.cost <= 1.5;
      step(3, 'Grade ${lint.grade} ($target), ${lint.words} words. Problem: ${problems.join('; ')}.'
          '${closeEnough ? ' Keeping the clean draft at grade ${best.grade}.' : draft < maxDrafts ? ' Rewriting.' : ''}');
      if (closeEnough) break;
      feedback = '\n\nYour last draft had these problems: ${problems.join('; ')}. Write a new draft that fixes them.'
          '${d.off > 0 ? ' Use shorter sentences and shorter, more common words.' : ''}'
          '${d.off < 0 ? ' Use longer sentences and richer words.' : ''}';
    }
    if (best == null) throw StoryFailed('The AI could not write a story that makes sense');
    return (title: best.title, paras: best.paras, grade: best.grade, words: best.words, drafts: drafts);
  }

  /// Null if the AI reader picks the keyed answer, otherwise why it failed.
  /// Asked twice with the choices in opposite orders, so a lucky guess or a
  /// letter habit does not pass. The story comes first in the prompt so the
  /// server can reuse it from its prompt cache.
  Future<String?> _verify(Job job, Question q, String numbered) async {
    for (final order in const [
      [0, 1, 2, 3],
      [3, 2, 1, 0]
    ]) {
      final r = await _chat(
          job,
          _checkSys,
          'Story:\n$numbered\n\nQuestion: ${q.question}\n'
          '${[for (final (i, c) in order.indexed) '${'ABCD'[i]}) ${q.choices[c]}'].join('\n')}\n\nAnswer with one letter.',
          _checkSchema,
          temperature: 0,
          maxTokens: 20);
      final letter = 'ABCD'.indexOf('${r['answer']}');
      final pick = letter < 0 ? -1 : order[letter];
      if (pick != q.answer) {
        return 'the AI reader chose "${pick < 0 ? r['answer'] : q.choices[pick]}", not "${q.choices[q.answer]}"';
      }
    }
    return null;
  }

  // Steps 4-6: number the sentences, write questions, then Check 2 on each one.
  Future<({List<Question> questions, int rewritten, int dropped})> _writeQuestions(
      Job job, int level, List<String> sentences, StoryPlan plan, OnStep step) async {
    final l = levels[level];
    final numbered = [for (final (i, s) in sentences.indexed) '[${i + 1}] $s'].join('\n');
    final ent = entities(sentences, plan);
    step(4, '${sentences.length} sentences. Found ${ent.people.length} people, ${ent.places.length} places.');

    final kept = <(Question, String)>[];
    var rewritten = 0, dropped = 0;
    bool isNew(Question q) =>
        !kept.any((k) => k.$1.question.toLowerCase() == q.question.toLowerCase() || k.$1.evidence == q.evidence);
    Checked vet(Checked res) {
      if (res.q == null) return res;
      if (res.kind == 'vocab' && (level < 2 || kept.any((k) => k.$2 == 'vocab'))) {
        return const Checked.fail('one word-meaning question is enough');
      }
      if (!isNew(res.q!)) return const Checked.fail('it repeats another question');
      return res;
    }

    for (var batch = 0; batch < 2 && kept.length < l.q; batch++) {
      final ask = l.q + 3;
      step(5, batch > 0 ? 'Writing more questions' : '$ask questions: ${l.types}');
      final Map<String, dynamic> out;
      try {
        out = await _chat(
            job,
            _qSys,
            'Story:\n$numbered\n\nWrite $ask multiple-choice questions for Grade ${l.grades} readers, each about a different sentence. '
            'Use ${l.types}.\n${_qRules(plan.name)}',
            _qSchema(ask));
      } on _BadJson {
        continue;
      }
      final raws = out['questions'] is List ? (out['questions'] as List).whereType<Map<String, dynamic>>() : const <Map<String, dynamic>>[];
      for (final raw in raws) {
        if (kept.length >= l.q) break;
        var res = vet(checkQuestion(raw, sentences, ent, plan));
        var why = res.why ?? await _verify(job, res.q!, numbered);
        // The AI could not answer its own question: one rewrite, then it is thrown out.
        if (why != null && res.q != null) {
          rewritten++;
          step(6, 'Rewriting a question: $why.');
          try {
            final fix = await _chat(
                job,
                _qSys,
                'Story:\n$numbered\n\nThis question failed because $why:\n${jsonEncode(raw)}\n'
                'Write ONE better question about the same sentence.\n${_qRules(plan.name)}',
                _qItem);
            res = vet(checkQuestion(fix, sentences, ent, plan));
            why = res.why ?? await _verify(job, res.q!, numbered);
          } on _BadJson {
            why = 'the rewrite came back broken';
          }
        }
        if (why != null) {
          dropped++;
          step(6, 'Threw out a question: $why.');
          continue;
        }
        kept.add((res.q!, res.kind));
        step(6, '${kept.length} of ${l.q} questions passed: answer found in sentence ${res.q!.evidence + 1}, and the AI got it right.');
      }
    }
    return (questions: [for (final k in kept) k.$1], rewritten: rewritten, dropped: dropped);
  }

  /// Writes and checks one story. A story whose questions keep failing is
  /// replaced by a new story once. Throws [StoryFailed], [JobCancelled], or
  /// [ModelUnavailableException].
  Future<WrittenStory> makeStory(int level, String topic, {required Job job, OnStep? onStep}) async {
    final step = onStep ?? (_, _) {};
    final l = levels[level];
    final watch = Stopwatch()..start();
    for (var round = 1; round <= 2; round++) {
      final p = plan(level, topic);
      final ({String title, List<List<String>> paras, double grade, int words, int drafts}) story;
      try {
        story = await _writeStory(job, level, topic, p, step);
      } on StoryFailed {
        if (round == 2) rethrow;
        step(2, 'No draft passed. Starting over with a new character.');
        continue;
      }
      final sentences = [for (final para in story.paras) ...para];
      final qs = await _writeQuestions(job, level, sentences, p, step);
      final enough = round == 1 ? math.min(3, l.q) : 2;
      if (qs.questions.length >= enough) {
        step(7, '${qs.questions.length} questions, choices mixed up');
        return WrittenStory(level, topic, story.title.isEmpty ? topic : story.title, story.paras, qs.questions, {
          'v': pipelineVersion,
          'grade': story.grade,
          'words': story.words,
          'target': [l.fk.$1, l.fk.$2],
          'drafts': story.drafts,
          'name': p.name,
          'place': p.place,
          'verified': qs.questions.length,
          'rewritten': qs.rewritten,
          'dropped': qs.dropped,
          'seconds': watch.elapsed.inSeconds,
          'model': modelName,
        });
      }
      if (round == 1) step(5, 'Only ${qs.questions.length} good questions. Writing a new story.');
    }
    throw StoryFailed('The AI could not write questions that hold up');
  }

  /// The meaning of [word] as it is used in [sentence], for a reader at [level].
  /// Throws [StoryFailed] if no usable meaning comes back.
  Future<({String meaning, String? synonym})> explainWord(String word, String sentence, int level) async {
    final key = '${word.toLowerCase()}|$sentence';
    final cached = _wordCache[key];
    if (cached != null) return cached;
    final l = levels[level];
    final job = Job(Priority.word);
    // A synonym is usable if it is one or two words and not the same word again.
    bool okSynonym(String w) =>
        w.isNotEmpty && w.split(RegExp(r'\s+')).length <= 2 && !w.toLowerCase().startsWith(word.toLowerCase().substring(0, math.min(4, word.length)));
    var feedback = '';
    String? synonym, meaning;
    for (var tryNo = 1; tryNo <= 3 && meaning == null; tryNo++) {
      final Map<String, dynamic> r;
      try {
        r = await _chat(
            job,
            _wordSys,
            'Sentence: "$sentence"\nWord: "$word"\nIn under 15 words, what does "$word" mean in this sentence, for a Grade ${l.grades} reader? '
            'Also give one simpler word that means the same.$feedback',
            _wordSchema,
            temperature: 0.3 + 0.3 * (tryNo - 1),
            maxTokens: 200);
      } on _BadJson {
        continue;
      }
      var m = '${r['meaning'] ?? ''}'.trim();
      if (m.isNotEmpty) m = m[0].toUpperCase() + m.substring(1);
      final s = '${r['synonym'] ?? ''}'.trim();
      if (synonym == null && okSynonym(s)) synonym = s;
      final why = checkMeaning(word, m);
      if (why == null) {
        meaning = m;
      } else {
        feedback = '\nYour last answer was not usable because $why. Explain it another way, for example "a person who..." or "to do...".';
      }
    }
    // ponytail: a small model sometimes only manages a synonym; that still helps a reader.
    if (meaning == null && synonym != null) meaning = 'It means about the same as "$synonym".';
    if (meaning == null) throw StoryFailed('No good meaning for "$word"');
    final out = (meaning: meaning, synonym: meaning.contains('"$synonym"') ? null : synonym);
    return _wordCache[key] = out;
  }
}
