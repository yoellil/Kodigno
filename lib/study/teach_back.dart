import '../domain/nlp.dart';
import '../domain/source_ref.dart';
import '../domain/summary.dart';
import '../domain/topics.dart' show headingKey, headingKeyByPage, isHeadingLine, looksLikeLabel;
import 'teach_judge.dart';

/// One idea a student should be able to explain: a line from the slides about the
/// topic, and where it is.
class Idea {
  const Idea(this.text, {this.source});
  final String text;
  final SourceRef? source;
}

/// What the check found that is worth a second look, apart from what is missing.
enum FlagKind {
  /// A sentence that may say the opposite of a slide.
  opposite,

  /// A year or figure the slides do not have.
  number,

  /// A name the slides do not have.
  name,
}

class Flag {
  const Flag(this.kind, this.sentence, this.detail);
  final FlagKind kind;

  /// The sentence of the student's explanation it is about.
  final String sentence;

  /// The number or name, or the slide line that it may be the opposite of.
  final String detail;

  /// Said as a thing to check, not as a verdict: the check can be wrong.
  String get message => switch (kind) {
        FlagKind.opposite => 'This might not match your slides. Compare it with: "$detail"',
        FlagKind.number => 'Your slides do not have the number $detail. Check it.',
        FlagKind.name => 'Your slides do not mention $detail. Check it.',
      };
}

/// How well the explanation covers one idea.
enum Coverage {
  /// A sentence of the explanation says it.
  covered,

  /// Some of its words are there, but not the whole idea.
  partly,

  /// Nothing like it was found.
  missing,
}

class IdeaResult {
  const IdeaResult(this.idea, {required this.coverage, required this.score, this.matched});
  final Idea idea;
  final Coverage coverage;

  /// How alike the best sentence of the explanation is to the idea, 0 to 1.
  final double score;

  /// The sentence of the explanation that covers it.
  final String? matched;

  bool get covered => coverage == Coverage.covered;
}

/// What did the checking.
enum CheckedBy {
  /// Only a comparison of words with the slides.
  words,

  /// The AI model read the explanation, backed by the words.
  model,
}

/// What a check of one explanation found.
class TeachBackResult {
  const TeachBackResult({
    required this.ideas,
    required this.missingTerms,
    required this.flags,
    required this.copied,
    required this.words,
    this.checkedBy = CheckedBy.words,
  });

  final CheckedBy checkedBy;
  final List<IdeaResult> ideas;

  /// Words from the slides about this topic that the explanation did not use.
  final List<String> missingTerms;
  final List<Flag> flags;

  /// True if the explanation is mostly lifted from the slides.
  final bool copied;
  final int words;

  int get covered => ideas.where((i) => i.coverage == Coverage.covered).length;
  int get partly => ideas.where((i) => i.coverage == Coverage.partly).length;
  int get total => ideas.length;

  /// One line that says how it went, in counts and never a grade.
  String get headline {
    if (copied) return 'Mostly copied from the slides. Try again in your own words.';
    if (total == 0) return 'Nothing to compare with.';
    if (covered == total) return 'You covered all $total ideas.';
    if (covered + partly == 0) return 'I could not find any of the $total ideas yet.';
    if (partly == 0) return 'You covered $covered of $total ideas.';
    return 'You covered $covered of $total ideas, and $partly partly.';
  }
}

/// Shorter than this is not an explanation yet.
const minExplanationWords = 8;

int wordCount(String text) =>
    RegExp('[A-Za-z0-9À-ɏ]+(?:[\'’-][A-Za-z0-9À-ɏ]+)*').allMatches(text).length;

/// The sentences of [text]. A last sentence with no full stop counts too.
List<String> splitSentences(String text) => [
      for (final s in text.split(RegExp(r'(?<=[.!?])\s+|\n+'))) if (s.trim().isNotEmpty) s.trim(),
    ];

/// A sentence this alike an idea covers it; this alike covers part of it.
const _coveredScore = 0.3;
const _partlyScore = 0.15;

/// Or the explanation as a whole using this share of an idea's words, at least 2.
const _coveredWordShare = 0.6;

/// How many ideas a topic is checked against, at most.
const maxIdeas = 4;

/// The pages that the material of [section] came from.
Set<int> _referencedPages(SummarySection section, LessonSummary lesson) {
  final numbers = <int>{};
  for (final text in [section.explanation, ...section.keyPoints, ...section.facts]) {
    final ref = lesson.sourceOf(text);
    if (ref != null && ref.kind != SourceKind.unmatched) numbers.addAll(ref.pages);
  }
  return numbers;
}

/// The pages a topic is about: the ones under its heading in the slides, narrowed
/// to the ones its material came from if it is one part of a long topic. A topic
/// with no heading of its own (it was joined, or named by the model) uses the
/// pages its material came from.
Set<int> pagesOfTopic(SummarySection section, LessonSummary lesson, List<PageText> pages) {
  final referenced = _referencedPages(section, lesson);
  final base = section.heading.replaceFirst(RegExp(r'\s*\(\d+ of \d+\)\s*$'), '');
  final key = headingKey(base);
  final byHeading = {
    for (final e in headingKeyByPage(pages).entries)
      if (e.value == key) e.key,
  };
  if (byHeading.isEmpty) return referenced;
  // Only one part of a long topic ("2 of 3") is narrowed to its own pages.
  if (!RegExp(r'\(\d+ of \d+\)\s*$').hasMatch(section.heading)) return byHeading;
  final narrowed = byHeading.intersection(referenced);
  return narrowed.isNotEmpty ? narrowed : byHeading;
}

/// A heading the PDF ran together, stuck to the front of a line
/// ("PrivacyProtectionandtheLaw(US) In addition, ..."), removed.
String _withoutGluedHeading(String line) {
  final m = RegExp(r'^(\S+)\s+(.*)$', dotAll: true).firstMatch(line);
  if (m == null) return line;
  final seams = RegExp(r'[a-z][A-Z]').allMatches(m[1]!).length;
  return seams >= 2 || RegExp(r'[A-Za-z]\(').hasMatch(m[1]!) ? m[2]! : line;
}

/// True if [line] reads as a complete statement: it starts with a capital letter
/// and does not trail off with a comma.
bool _isStatement(String line) =>
    RegExp('^["“(]?[A-Z0-9]').hasMatch(line) && !RegExp(r'[,;:]$').hasMatch(line);

/// The ideas of [section]. They come from the slides themselves: the most central
/// lines of the pages behind the topic, which the model cannot get wrong. Only if
/// the notes have no pages are they the lesson's key points, or its explanation.
List<Idea> ideasOf(SummarySection section, LessonSummary lesson, [List<PageText> pages = const []]) {
  final seen = <String>{};
  final out = <Idea>[];
  void add(String text, SourceRef? source) {
    final t = text.trim();
    if (wordCount(t) < 4 || !seen.add(t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim())) return;
    out.add(Idea(t, source: source));
  }

  final numbers = pagesOfTopic(section, lesson, pages);
  final onPages = [for (final p in pages) if (numbers.contains(p.number)) p];
  if (onPages.isNotEmpty) {
    final lines = <(String, int)>[];
    for (final p in onPages) {
      for (final raw in textItems(p.text)) {
        final it = _withoutGluedHeading(raw);
        final w = wordCount(it);
        if (w >= 5 && w <= 45 && _isStatement(it) && !isHeadingLine(it) && !looksLikeLabel(it)) {
          lines.add((it, p.number));
        }
      }
    }
    final texts = [for (final (t, _) in lines) t];
    final core = condense(texts,
        maxChars: 900, keyTerms: section.terms, idf: idfOf([for (final p in onPages) p.text]));
    for (final t in core) {
      if (out.length >= maxIdeas) break;
      final page = lines.firstWhere((l) => l.$1 == t).$2;
      add(t, SourceRef(kind: SourceKind.copied, pages: [page], score: 1, quote: t));
    }
  }
  if (out.length < 2) {
    for (final p in section.keyPoints.take(maxIdeas)) {
      add(p, lesson.sourceOf(p));
    }
  }
  if (out.length < 2) {
    for (final s in splitSentences(section.explanation)) {
      if (out.length >= maxIdeas) break;
      add(s, lesson.sourceOf(s));
    }
  }
  return out;
}

/// The words of the slides behind [section], to check an explanation against: the
/// pages of the topic, or if the notes have no pages, its own text.
String sourceTextOf(SummarySection section, LessonSummary lesson, List<PageText> pages) {
  final numbers = pagesOfTopic(section, lesson, pages);
  final fromPages = [for (final p in pages) if (numbers.contains(p.number)) p.text];
  if (fromPages.isNotEmpty) return fromPages.join('\n\n');
  return [section.explanation, ...section.keyPoints, ...section.facts].where((s) => s.isNotEmpty).join('\n');
}

/// The stems of the meaningful words of [s].
Set<String> _stemsOf(String s) => terms(s).toSet();

/// Checks [answer], a student's explanation of a topic, against [ideas] and the
/// words of the slides in [sourceText]. [terms] are the topic's key phrases.
TeachBackResult checkTeachBack({
  required String answer,
  required List<Idea> ideas,
  required String sourceText,
  List<String> terms = const [],
}) {
  final sentences = splitSentences(answer);
  final words = wordCount(answer);
  final idf = idfOf([...ideas.map((i) => i.text), ...sentences, sourceText]);
  final answerStems = _stemsOf(answer);
  final vectors = [for (final s in sentences) vectorOf(s, idf)];

  final results = <IdeaResult>[];
  for (final idea in ideas) {
    final stems = _stemsOf(idea.text);
    final v = vectorOf(idea.text, idf);
    var best = 0.0;
    String? matched;
    for (var i = 0; i < sentences.length; i++) {
      final c = cosineOf(v, vectors[i]);
      if (c > best) {
        best = c;
        matched = sentences[i];
      }
    }
    final shared = stems.where(answerStems.contains).length;
    final share = stems.isEmpty ? 0.0 : shared / stems.length;
    final Coverage coverage;
    if (best >= _coveredScore ||
        (stems.length >= 2 && shared >= 2 && share >= _coveredWordShare) ||
        (stems.length == 1 && shared == 1)) {
      coverage = Coverage.covered;
    } else if (best >= _partlyScore || shared >= 2) {
      coverage = Coverage.partly;
    } else {
      coverage = Coverage.missing;
    }
    results.add(IdeaResult(idea,
        coverage: coverage, score: best, matched: coverage == Coverage.missing ? null : matched));
  }

  // Words of the slides that go with this topic and were not used.
  final ideaStems = {for (final i in ideas) ..._stemsOf(i.text)};
  final missingTerms = [
    for (final t in terms)
      if (_stemsOf(t).isNotEmpty &&
          _stemsOf(t).every(ideaStems.contains) &&
          !_stemsOf(t).every(answerStems.contains))
        t,
  ].take(3).toList();

  final items = textItems(sourceText);
  final flags = <Flag>[];
  for (final s in sentences) {
    if (wordCount(s) < 4) continue;
    final opposite = oppositeLine(s, items);
    if (opposite != null) flags.add(Flag(FlagKind.opposite, s, opposite));
    for (final n in figuresNotIn(s, sourceText)) {
      flags.add(Flag(FlagKind.number, s, n));
    }
    for (final n in namesNotIn(s, sourceText)) {
      flags.add(Flag(FlagKind.name, s, n));
    }
  }

  return TeachBackResult(
    ideas: results,
    missingTerms: missingTerms,
    flags: _distinct(flags).take(4).toList(),
    copied: words >= minExplanationWords && copyRatio(answer, sourceText) >= 0.5,
    words: words,
  );
}

/// The result of the word comparison, [words], with the AI model's [judgement]
/// brought in. The model decides whether an explanation expresses an idea in other
/// words, which a comparison of words cannot; the words keep it honest.
///
/// A "yes" is covered and a "partly" is partly. A "no" is missing, unless the words
/// found some of it, in which case it is partly: the two disagree, so neither is
/// taken as certain. A verdict with no verified evidence is already gone from
/// [judgement], and that idea keeps the words' result. If the judgement is not about
/// the same ideas, [words] is returned as it was.
TeachBackResult combineWithModel(TeachBackResult words, TeachBackJudgement judgement) {
  if (judgement.concepts.length != words.ideas.length) return words;
  final ideas = <IdeaResult>[];
  for (var i = 0; i < words.ideas.length; i++) {
    final w = words.ideas[i];
    final v = judgement.concepts[i];
    final l = w.coverage;
    final Coverage c;
    switch (v.verdict) {
      case null:
        c = l;
      case Verdict.yes:
        c = Coverage.covered;
      case Verdict.partly:
        c = Coverage.partly;
      case Verdict.no:
        c = l == Coverage.covered ? Coverage.partly : Coverage.missing;
    }
    final fromModel = v.verdict == Verdict.yes || v.verdict == Verdict.partly;
    ideas.add(IdeaResult(
      w.idea,
      coverage: c,
      score: w.score,
      matched: c == Coverage.missing ? null : (fromModel && v.evidence.isNotEmpty ? v.evidence : w.matched),
    ));
  }
  final flags = _distinct([
    for (final o in judgement.opposites) Flag(FlagKind.opposite, o.said, o.slides),
    ...words.flags,
  ]).take(4).toList();
  return TeachBackResult(
    ideas: ideas,
    missingTerms: words.missingTerms,
    flags: flags,
    copied: words.copied,
    words: words.words,
    checkedBy: CheckedBy.model,
  );
}

List<Flag> _distinct(List<Flag> flags) {
  final seen = <String>{};
  return [
    for (final f in flags)
      if (seen.add('${f.kind.name}|${f.detail.toLowerCase()}')) f,
  ];
}
