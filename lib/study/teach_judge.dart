import 'dart:convert';

import '../domain/nlp.dart';
import '../domain/prompt.dart' show isGrounded;
import '../domain/summary.dart';
import 'teach_back.dart' show wordCount;

/// What the AI model says about one key idea of a topic.
enum Verdict { yes, partly, no }

/// A quote of fewer words than this is not evidence of an idea.
const minEvidenceWords = 4;

/// The model's verdict on one key idea. [verdict] is null if the model gave none,
/// or if the words it quoted as evidence are not in the student's explanation:
/// a verdict with nothing behind it is not used.
class ConceptVerdict {
  const ConceptVerdict(this.verdict, this.evidence);
  final Verdict? verdict;

  /// The student's own words that the model says show the idea.
  final String evidence;
}

/// A sentence of the explanation that the model says is the opposite of the slides.
class Opposite {
  const Opposite(this.said, this.slides);
  final String said;
  final String slides;
}

/// What the model made of an explanation.
class TeachBackJudgement {
  const TeachBackJudgement(this.concepts, this.opposites);

  /// One per key idea, in order.
  final List<ConceptVerdict> concepts;
  final List<Opposite> opposites;
}

/// What the Teach-Back screen needs from the AI model. The app's controller is one;
/// a test can be another.
abstract class TeachBackModel {
  /// True if the model is installed and can be asked.
  bool get available;

  /// True if the model is big enough to judge whether an explanation says an idea.
  /// The smallest one is not: it says "yes" to wrong explanations too, so it only
  /// writes the key ideas and the check of the explanation stays with the words.
  bool get canJudge;

  /// The key ideas of a topic, written from [slideText], or none if the model
  /// could not write usable ones.
  Future<List<String>> concepts(String slideText, {String? topic});

  /// What the model makes of [answer] against [concepts], or null if it could not.
  Future<TeachBackJudgement?> judge({
    required List<String> concepts,
    required String answer,
    required String slideText,
  });
}

// ---------------------------------------------------------------- key ideas

String buildConceptsPrompt(String slideText, {String? topic}) => '''
You are a teacher. Below are the slides of one topic of a lesson.
Write the 3 or 4 key ideas a student must understand to explain this topic, as short plain sentences in your own words.
Reply with JSON only: an object with a "concepts" list.
Rules:
- Each concept is one complete sentence of 8 to 25 words that states an idea. It is not a heading or a label.
- Cover different ideas. Do not say the same idea twice.
- Use only the slides. Never add facts, names, dates or numbers that are not in them.
${topic == null ? '' : '\nTOPIC: $topic\n'}
SLIDES:
$slideText
''';

Map<String, Object?> conceptsSchema() => {
      'type': 'object',
      'properties': {
        'concepts': {
          'type': 'array',
          'minItems': 2,
          'maxItems': 4,
          'items': {'type': 'string', 'minLength': 30, 'maxLength': 220},
        },
      },
      'required': ['concepts'],
    };

Map<dynamic, dynamic> _object(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) throw const FormatException('no JSON object in model output');
  final decoded = jsonDecode(raw.substring(start, end + 1));
  if (decoded is! Map) throw const FormatException('JSON is not an object');
  return decoded;
}

String _squash(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// The key ideas in the model's [raw] output that the slides back up: a complete
/// sentence, not a heading, with its words, years, figures and names all in
/// [slideText], and not the same as one already taken. At most four. Throws a
/// [FormatException] if the output is not what was asked for.
List<String> parseConcepts(String raw, String slideText) {
  final list = _object(raw)['concepts'];
  if (list is! List) throw const FormatException('no concepts');
  final out = <String>[];
  final seen = <String>[];
  for (final x in list) {
    if (x is! String) continue;
    final c = x.replaceAll(RegExp(r'<[^<>]{2,}>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = wordCount(c);
    if (words < 6 || words > 40) continue;
    if (!isGrounded(c, slideText, minRatio: 0.4) || !figuresInSource(c, slideText) || !namesInSource(c, slideText)) {
      continue; // not something the slides say
    }
    final stems = terms(c).toSet();
    final repeat = seen.any((s) {
      final t = terms(s).toSet();
      final shared = stems.where(t.contains).length;
      return stems.isNotEmpty && shared / stems.length >= 0.8;
    });
    if (repeat) continue;
    seen.add(c);
    out.add(c);
    if (out.length == 4) break;
  }
  return out;
}

// ------------------------------------------------------------------ judging

String buildJudgePrompt({required List<String> concepts, required String answer, required String slideText}) => '''
A student explained a topic from memory. Decide whether their explanation shows each key idea, in any words, even if they do not use the same words as the slides.
Reply with JSON only: an object with "ideas" (one item for each numbered idea, in the same order) and "opposites".
Rules:
- "verdict" is "yes" if the explanation clearly says the idea, "partly" if it only touches on it, and "no" if it does not say it.
- "evidence" is the exact words copied from the student's explanation that show the idea. Leave it empty if the verdict is "no".
- "opposites" lists any sentence of the student's explanation that says the opposite of what the slides say. Each has "said" (the exact words of the student) and "slides" (the exact words of the slides). It is usually empty.
- Judge only what the student wrote. Never give credit for an idea the student did not write.

KEY IDEAS:
${[for (var i = 0; i < concepts.length; i++) '${i + 1}. ${concepts[i]}'].join('\n')}

SLIDES:
$slideText

STUDENT'S EXPLANATION:
$answer
''';

Map<String, Object?> judgeSchema(int ideas) => {
      'type': 'object',
      'properties': {
        'ideas': {
          'type': 'array',
          'minItems': ideas,
          'maxItems': ideas,
          'items': {
            'type': 'object',
            'properties': {
              'verdict': {
                'type': 'string',
                'enum': ['yes', 'partly', 'no'],
              },
              'evidence': {'type': 'string', 'maxLength': 300},
            },
            'required': ['verdict', 'evidence'],
          },
        },
        'opposites': {
          'type': 'array',
          'maxItems': 2,
          'items': {
            'type': 'object',
            'properties': {
              'said': {'type': 'string', 'maxLength': 300},
              'slides': {'type': 'string', 'maxLength': 300},
            },
            'required': ['said', 'slides'],
          },
        },
      },
      'required': ['ideas', 'opposites'],
    };

/// True if [quote] is really in [text]: its letters and digits appear there in the
/// same order, or at least 85% of its words do, in any order (a model may drop a
/// comma or a small word when it copies). A very short quote counts for nothing.
bool quoteIn(String quote, String text) {
  final q = _squash(quote), t = _squash(text);
  if (q.length < 8) return false;
  if (t.contains(q)) return true;
  final words = q.split(' ');
  final have = t.split(' ').toSet();
  return words.where(have.contains).length / words.length >= 0.85;
}

/// The model's [raw] verdict on [conceptCount] key ideas, with every verdict
/// checked: its evidence must really be in the student's [answer], or the verdict
/// is dropped. An "opposite" is kept only if what the student said is in the
/// answer, what the slides say is in [slideText], and the two are about the same
/// thing. Throws a [FormatException] if the output is not what was asked for.
TeachBackJudgement parseJudgement(String raw, {required int conceptCount, required String answer, required String slideText}) {
  final obj = _object(raw);
  final ideas = obj['ideas'];
  if (ideas is! List || ideas.length != conceptCount) throw const FormatException('wrong number of ideas');
  final verdicts = <ConceptVerdict>[];
  for (final x in ideas) {
    final m = x is Map ? x : const {};
    final v = switch (m['verdict']) {
      'yes' => Verdict.yes,
      'partly' => Verdict.partly,
      'no' => Verdict.no,
      _ => null,
    };
    final evidence = (m['evidence'] is String ? m['evidence'] as String : '').trim();
    if (v == Verdict.no) {
      verdicts.add(const ConceptVerdict(Verdict.no, ''));
    } else if (v != null && wordCount(evidence) >= minEvidenceWords && quoteIn(evidence, answer)) {
      verdicts.add(ConceptVerdict(v, evidence));
    } else {
      verdicts.add(const ConceptVerdict(null, '')); // a yes with nothing behind it
    }
  }
  // One quote cannot show three different ideas: the model is stretching it.
  final uses = <String, int>{};
  for (final v in verdicts) {
    if (v.verdict != null && v.verdict != Verdict.no) uses[_squash(v.evidence)] = (uses[_squash(v.evidence)] ?? 0) + 1;
  }
  for (var i = 0; i < verdicts.length; i++) {
    final v = verdicts[i];
    if (v.verdict != null && v.verdict != Verdict.no && uses[_squash(v.evidence)]! >= 3) {
      verdicts[i] = const ConceptVerdict(null, '');
    }
  }

  final opposites = <Opposite>[];
  final raw2 = obj['opposites'];
  if (raw2 is List) {
    for (final o in raw2) {
      if (o is! Map || o['said'] is! String || o['slides'] is! String) continue;
      final said = (o['said'] as String).trim(), slides = (o['slides'] as String).trim();
      if (!quoteIn(said, answer) || !quoteIn(slides, slideText)) continue;
      final a = terms(said).toSet(), b = terms(slides).toSet();
      if (a.where(b.contains).length < 3) continue; // not about the same thing
      if (!plainNegationDiffers(said, slides)) continue; // nothing to say it is the opposite
      opposites.add(Opposite(said, slides));
      if (opposites.length == 2) break;
    }
  }
  return TeachBackJudgement(verdicts, opposites);
}
