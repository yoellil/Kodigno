import 'dart:convert';

import 'nlp.dart';
import 'prompt.dart';

/// One topic of a lesson: what it is, in the teacher's own words, and the few
/// points a student must remember from it.
class SummarySection {
  const SummarySection({
    required this.heading,
    required this.explanation,
    this.keyPoints = const [],
    this.facts = const [],
    this.terms = const [],
  });
  final String heading;
  final String explanation;
  final List<String> keyPoints;

  /// The phrases this section keeps coming back to.
  final List<String> terms;

  /// Dates, figures and tables lifted word for word from the notes, never
  /// written by the model.
  final List<String> facts;

  Map<String, Object?> toJson() => {
        'heading': heading,
        'explanation': explanation,
        'keyPoints': keyPoints,
        'facts': facts,
        'terms': terms,
      };

  factory SummarySection.fromJson(Map<String, dynamic> j) => SummarySection(
        heading: j['heading'] as String? ?? '',
        explanation: j['explanation'] as String? ?? '',
        keyPoints: _strings(j['keyPoints']),
        facts: _strings(j['facts']),
        terms: _strings(j['terms']),
      );
}

List<String> _strings(Object? v) => [if (v is List) for (final x in v) if (x is String) x];

/// A study lesson made from a student's slides or notes: the big idea, one
/// explained section per topic, and what to remember afterwards.
class LessonSummary {
  const LessonSummary({
    this.overview = '',
    required this.sections,
    this.takeaways = const [],
    this.keyTerms = const [],
  });
  final String overview;
  final List<SummarySection> sections;
  final List<String> takeaways;

  /// The words and phrases the whole lesson keeps coming back to.
  final List<String> keyTerms;

  /// For saving with the study set.
  String encode() => jsonEncode({
        'overview': overview,
        'sections': [for (final s in sections) s.toJson()],
        'takeaways': takeaways,
        'keyTerms': keyTerms,
      });

  /// A saved lesson, or null if [saved] is empty or unreadable.
  static LessonSummary? decode(String saved) {
    if (saved.isEmpty) return null;
    try {
      final j = jsonDecode(saved) as Map<String, dynamic>;
      final sections = [
        for (final s in (j['sections'] as List? ?? const []))
          if (s is Map<String, dynamic>) SummarySection.fromJson(s),
      ];
      if (sections.isEmpty) return null;
      return LessonSummary(
        overview: j['overview'] as String? ?? '',
        sections: sections,
        takeaways: _strings(j['takeaways']),
        keyTerms: _strings(j['keyTerms']),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// The lesson as plain notes, for making flashcards and a quiz from it: each
  /// section's heading, explanation, points and facts, a blank line between.
  String toStudyText() => [
        for (final s in sections)
          [
            s.heading,
            if (s.explanation.isNotEmpty) s.explanation,
            ...s.keyPoints,
            ...s.facts,
          ].join('\n'),
      ].join('\n\n');

  /// The lesson as Markdown, for copying or exporting.
  String toText() {
    final b = StringBuffer();
    if (overview.isNotEmpty) b.writeln('## Overview\n$overview\n');
    for (final s in sections) {
      b.writeln('## ${s.heading}\n${s.explanation}');
      if (s.terms.isNotEmpty) b.writeln('Key terms: ${s.terms.join(', ')}');
      for (final p in s.keyPoints) {
        b.writeln('- $p');
      }
      if (s.facts.isNotEmpty) {
        b.writeln('Key facts:');
        for (final f in s.facts) {
          b.writeln('- ${f.replaceAll('\n', '\n  ')}');
        }
      }
      b.writeln();
    }
    if (takeaways.isNotEmpty) {
      b.writeln('## Remember');
      for (final t in takeaways) {
        b.writeln('- $t');
      }
    }
    return b.toString().trim();
  }
}

/// True if [text] is lifted straight out of [source] (ignoring case and
/// spacing) instead of being explained.
bool isCopy(String text, String source) {
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final t = norm(text);
  return t.isNotEmpty && norm(source).contains(t);
}

/// "1, 000, 000" as "1,000,000": PDFs space out the thousands.
String _tightNumbers(String s) =>
    s.replaceAllMapped(RegExp(r'(\d),\s+(?=\d{3}\b)'), (m) => '${m[1]},');

final _bulletStart = RegExp(
    '^(?:[•●❑❒▪■◦‣·–—*-]|\\d+[.)])\\s+');
final _dataRow = RegExp(r'^\d[\d,.]*(?:\s+\d[\d,.]*){2,}$');

/// A year, a quantity or a figure, but not "19th" or a list number.
bool _hasHardNumber(String s) {
  // "1.1 Avoid harm." and "2) Fraud" number a list; "Source: ..." is not a fact.
  final t = s.replaceFirst(RegExp(r'^(?:\d+(?:\.\d+)*[.)]?\s+)'), '');
  if (RegExp(r'^(?:credit|copyright|home)\b|\bsource\s*:', caseSensitive: false).hasMatch(t)) return false;
  return RegExp(r'\d{3,}|\d[.,]\d').hasMatch(t.replaceAll(RegExp(r'\b\d{1,2}(?:st|nd|rd|th)\b'), ''));
}

/// Dates, quantities and tables from [text], word for word, so they are never
/// lost or changed by the model. A table (rows of numbers) is kept whole, with
/// its column names.
List<String> keyFacts(String text, {int max = 8}) {
  // An empty line marks the start of the next slide.
  final lines = [for (final l in text.split('\n')) _tightNumbers(l.trim())];

  final tables = <String>[];
  final items = <String>[];
  var cur = '';
  var prevCaps = false;
  void flush() {
    if (cur.isNotEmpty) items.add(cur);
    cur = '';
  }

  for (var i = 0; i < lines.length; i++) {
    if (lines[i].isEmpty) {
      flush();
      prevCaps = false;
      continue;
    }
    if (_dataRow.hasMatch(lines[i])) {
      flush();
      final start = i;
      while (i + 1 < lines.length && _dataRow.hasMatch(lines[i + 1])) {
        i++;
      }
      // Column names: the lines just above the rows, back to the last full sentence.
      final head = <String>[];
      for (var j = start - 1; j >= 0 && head.length < 6; j--) {
        if (lines[j].isEmpty || RegExp(r'[.!?]$').hasMatch(lines[j]) || _dataRow.hasMatch(lines[j])) break;
        head.insert(0, lines[j]);
      }
      tables.add([if (head.isNotEmpty) head.join(' '), ...lines.sublist(start, i + 1)].join('\n'));
      continue;
    }
    final starts = _bulletStart.hasMatch(lines[i]);
    final line = lines[i].replaceFirst(_bulletStart, '');
    // A heading in capitals stands alone: it never runs into the line after it.
    final caps = line == line.toUpperCase() && RegExp(r'[A-Z]{3}').hasMatch(line);
    if (cur.isEmpty || starts || caps || prevCaps || RegExp(r'[.!?:]$').hasMatch(cur)) {
      flush();
      cur = line;
    } else {
      cur = '$cur $line';
    }
    prevCaps = caps;
  }
  flush();

  final seen = <String>{};
  return [
    for (final f in [
      ...tables,
      for (final it in items)
        if (it.length <= 240 && it.split(' ').length >= 3 && _hasHardNumber(it)) it,
    ])
      if (seen.add(f.toLowerCase())) f,
  ].take(max).toList();
}

/// A sentence about the slides themselves ("This part introduces...", "In this
/// section we focus on..."), which says nothing about the subject.
final _aboutTheSlides = RegExp(
    r'^(?:in\s+)?(?:this|the|these|our)\s+(?:part|section|slides?|lesson|notes?|module|passage|text|topic)\b'
    r'|^it\s+(?:also\s+)?(?:explains|describes|discusses|covers|highlights|introduces|emphasi[sz]es|outlines|shows|delves)\b',
    caseSensitive: false);

/// [text] without the sentences that say the opposite of the line of
/// [sourceItems] they are closest to.
String dropContradictions(String text, List<String> sourceItems) {
  final sentence = RegExp(r'(?:[^.!?]|[.!?](?!\s|$))+[.!?]+(?=\s|$)');
  return [
    for (final m in sentence.allMatches(text))
      if (!contradicts(m[0]!, sourceItems)) m[0]!.trim(),
  ].join(' ');
}

/// [text] without its sentences about the slides themselves.
String dropSlideTalk(String text) {
  final sentence = RegExp(r'(?:[^.!?]|[.!?](?!\s|$))+[.!?]+(?=\s|$)');
  return [
    for (final m in sentence.allMatches(text))
      if (!_aboutTheSlides.hasMatch(m[0]!.trim())) m[0]!.trim(),
  ].join(' ');
}

/// A year or figure: "1830", "390", "1,000,000", or "2 million", "50%".
final _figure = RegExp(
    r'\d{1,3}(?:,\d{3})+|\d{2,}|\d+(?:\.\d+)?\s*(?:million|billion|thousand|percent|%)',
    caseSensitive: false);

/// True if every year and figure in [text] is also in [source]. A small model
/// invents years ("the war of 1898") that no word-overlap check can catch.
bool figuresInSource(String text, String source) {
  final src = _tightNumbers(source);
  return _figure.allMatches(_tightNumbers(text)).every((m) => src.contains(m[0]!));
}

/// True if every name in [text] (a capitalised word not at the start, or an
/// acronym) is also in [source]. A small model writes "the movement in China"
/// or "nationalism in Mindanao" for places and people the slides never mention.
bool namesInSource(String text, String source) {
  final src = source.toLowerCase();
  final inner = text.replaceFirst(RegExp(r'^\W*\w+'), ''); // the first word is capitalised anyway
  return RegExp(r'\b(?:[A-Z][a-z]{3,}|[A-Z]{3,})\b')
      .allMatches(inner)
      .every((m) => src.contains(m[0]!.toLowerCase()));
}

/// The sentences of [text] that are based on [source], so a model's made-up
/// detail is dropped: words, years and figures must all come from [source].
/// A sentence cut off at the end (no full stop) is dropped too.
String groundedSentences(String text, String source, {double minRatio = 0.4}) {
  final sentence = RegExp(r'(?:[^.!?]|[.!?](?!\s|$))+[.!?]+(?=\s|$)');
  return [
    for (final m in sentence.allMatches(text))
      if (RegExp('^[A-Z"\u201C(]').hasMatch(m[0]!.trim()) && // not the tail of a cut sentence
          isGrounded(m[0]!.trim(), source, minRatio: minRatio) &&
          figuresInSource(m[0]!, source) &&
          namesInSource(m[0]!, source))
        m[0]!.trim(),
  ].join(' ');
}

/// Per section: teach the topic instead of repeating the slide.
String buildSectionPrompt(String notes,
        {String? topic, List<String> covers = const [], List<String> terms = const []}) =>
    '''
You are a teacher explaining a lesson to a student. Below are the main terms and the most important lines from one part of their slides. Work out what this part is really about, and teach it.
${topic == null ? '' : 'These notes come from slides titled "$topic".\n'}${covers.length > 1 ? 'These notes cover: ${covers.take(6).join('; ')}.\n' : ''}Reply with JSON only: an object with a "heading", an "explanation" and "keyPoints".
Rules:
- "heading": a short title of 2 to 6 words naming the idea of this part.
- "explanation": 2 to 4 complete sentences in plain language, as you would explain it out loud. First say what the subject is and why it matters, then how it works. Combine the lines into one clear idea in your own words. Write about the subject itself ("A trade secret is..."), never about the slides ("This part introduces..."). Do not copy the slide's wording or list its bullets.
- "keyPoints": 2 to 4 points worth remembering. Each is one full sentence, not a label.
- Use only the notes. Never add facts, names, dates or numbers that are not in them. If you are unsure, leave it out.
${terms.isEmpty ? '' : '\nKEY TERMS: ${terms.join(', ')}\n'}
NOTES:
$notes
''';

Map<String, Object?> sectionSchema() => {
      'type': 'object',
      'properties': {
        'heading': {'type': 'string', 'minLength': 3, 'maxLength': 80},
        'explanation': {'type': 'string', 'minLength': 40, 'maxLength': 900},
        'keyPoints': {
          'type': 'array',
          'minItems': 1,
          'maxItems': 4,
          'items': {'type': 'string', 'minLength': 20, 'maxLength': 200},
        },
      },
      'required': ['heading', 'explanation', 'keyPoints'],
    };

/// Last pass: tie the explained sections into one big idea and what to remember.
String buildOverviewPrompt(List<SummarySection> sections, {List<String> terms = const []}) => '''
Below are the sections of a lesson, each with a short explanation. Write the lesson's overview and what the student should remember.
Reply with JSON only: an object with an "overview" and "takeaways".
Rules:
- "overview": 2 to 3 sentences saying what the whole lesson is about and the big idea that ties the sections together. Do not just list the terms: say what a student will understand after the lesson.
- "takeaways": 3 to 5 complete sentences the student should remember after the lesson. Each one states an idea, not a heading.
- Use only the sections below. Never invent facts.
${terms.isEmpty ? '' : '\nTHE LESSON KEEPS COMING BACK TO: ${terms.join(', ')}\n'}
SECTIONS:
${[for (var i = 0; i < sections.length; i++) '${i + 1}. ${sections[i].heading}: ${_clip(sections[i].explanation, 250)}'].join('\n')}
''';

String _clip(String s, int max) => s.length <= max ? s : '${s.substring(0, max).trimRight()}...';

Map<String, Object?> overviewSchema() => {
      'type': 'object',
      'properties': {
        'overview': {'type': 'string', 'minLength': 40, 'maxLength': 500},
        'takeaways': {
          'type': 'array',
          'minItems': 2,
          'maxItems': 5,
          'items': {'type': 'string', 'minLength': 20, 'maxLength': 250},
        },
      },
      'required': ['overview', 'takeaways'],
    };

/// The model sometimes echoes the format's slots (like `<heading>`): strip them.
final _placeholder = RegExp(r'<[^<>]{2,}>');

String _clean(Object? v) => v is String ? v.replaceAll(_placeholder, '').trim() : '';

List<String> _cleanList(Object? v) => [
      if (v is List)
        for (final x in v)
          if (_clean(x).isNotEmpty) _clean(x),
    ];

Map<dynamic, dynamic> _object(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const FormatException('no JSON object in model output');
  }
  final decoded = jsonDecode(raw.substring(start, end + 1));
  if (decoded is! Map) throw const FormatException('JSON is not an object');
  return decoded;
}

/// A section from the model's output. Throws [FormatException] if it has no
/// heading or no explanation.
SummarySection parseSection(String raw) {
  final o = _object(raw);
  final heading = _clean(o['heading']);
  final explanation = _clean(o['explanation']);
  if (heading.isEmpty || explanation.isEmpty) {
    throw const FormatException('no heading or explanation');
  }
  return SummarySection(
    heading: heading,
    explanation: explanation,
    keyPoints: _cleanList(o['keyPoints']),
  );
}

/// The overview and takeaways from the last pass. Throws [FormatException] if
/// there is no overview.
(String, List<String>) parseOverview(String raw) {
  final o = _object(raw);
  final overview = _clean(o['overview']);
  if (overview.isEmpty) throw const FormatException('no overview');
  return (overview, _cleanList(o['takeaways']));
}
