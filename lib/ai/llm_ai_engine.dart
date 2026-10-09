import 'dart:math';

import '../domain/definitions.dart';
import '../domain/hygiene.dart';
import '../domain/lists.dart';
import '../domain/models.dart';
import '../domain/nlp.dart';
import '../domain/output_parser.dart';
import '../domain/prompt.dart';
import '../domain/summary.dart';
import '../domain/topics.dart';
import '../models/tier.dart';
import 'ai_engine.dart';

/// Builds a study set in three passes per section of the notes: the key facts,
/// one question and short answer per fact, then believable wrong answers of
/// the same kind for the quiz. Other answers from the notes and nearby numbers
/// fill in when the model's wrong answers are missing or unusable.
/// "Term - definition" lines in the notes also become cards and quiz questions
/// directly, with no model involved.
class LlmAiEngine implements AiEngine {
  LlmAiEngine(
    this.runtime,
    this.tier, {
    this.maxChunks = 12,
    this.maxAttempts = 3,
    Random? random,
  }) : _random = random ?? Random();

  final LlmRuntime runtime;
  final Tier tier;
  final int maxChunks;
  final int maxAttempts;
  final Random _random;

  /// Sections shorter than this are headings and filler, not worth a model call.
  static const _minChunkChars = 80;

  /// [text] ready for generation: one kind of line break (Windows files and
  /// PDFs bring "\r\n"), no reference lists, run-together headings spaced, no
  /// footers that repeat on every page.
  static String _cleaned(String text) => dropRepeatedLines(
      stripReferences(fixSquashedText(text.replaceAll('\r\n', '\n').replaceAll('\r', '\n'))));

  /// Enough list questions to fill a quiz without crowding out the rest.
  static const _maxListQuestions = 8;

  /// Questions whose answer is a person. Their fallback choices are other people.
  static final _who = RegExp(r'\bwho(m|se)?\b', caseSensitive: false);

  @override
  Future<GeneratedSet> generate(
    String notes, {
    String? verifyIn,
    void Function(double fraction)? onProgress,
  }) async {
    final text = _cleaned(notes);
    final original = verifyIn == null ? null : _cleaned(verifyIn);
    final source = original ?? text; // the lesson's own structure: lists and "Term - definition" lines
    // The notes' own titled lists ("General Ethical Principles" + its points).
    final lists = <NotesList>[];
    final titles = <String>{};
    for (final l in notesLists(source)) {
      if (l.heading.isEmpty || !isGoodList(l.items)) continue;
      if (titles.add(l.heading.toLowerCase())) lists.add(l);
    }
    bool usable(Definition d) =>
        !looksLikeCitation('${d.term}: ${d.definition}') && !titles.contains(d.term.toLowerCase());
    final defs = [for (final d in extractDefinitions(source)) if (usable(d)) d];
    // "Which term is this?" needs real definitions ("X - ...", "X is a ..."), not a
    // slide title with a sentence under it.
    final quizDefs = [for (final d in extractDefinitions(source, headingCards: false)) if (usable(d)) d];
    final listBacks = {for (final l in lists) formatList(l.items)};
    var all = chunkText(text, tier.chunkChars);
    final long = all.where((c) => c.length >= _minChunkChars).toList();
    if (long.isNotEmpty) all = long;
    // Spread over the whole document, not just its first pages.
    final chunks = all.length <= maxChunks
        ? all
        : [for (var i = 0; i < maxChunks; i++) all[i * all.length ~/ maxChunks]];

    final items = <QaItem>[];
    final seen = <String>{};
    for (var i = 0; i < chunks.length; i++) {
      final got = await _itemsFor(chunks[i], original);
      onProgress?.call((i + 1) / chunks.length);
      for (final it in got ?? const <QaItem>[]) {
        // One card per list: not again under a second question, nor when the
        // list already has its own titled card.
        if (it.answer.contains('\n') && (listBacks.contains(it.answer) || !seen.add(it.answer))) continue;
        if (seen.add(it.question.toLowerCase().trim())) items.add(it);
      }
    }
    if (items.isEmpty && defs.isEmpty && lists.isEmpty) throw GenerationFailed();

    // Show the definition, pick the term; the other terms are the wrong choices.
    final questions = <QuizQuestion>[];
    final terms = [for (final d in quizDefs) d.term];
    for (final d in quizDefs) {
      if (d.definition.contains('\n')) continue; // a list is for a card, not a "which term" question
      final masked = maskTerm(shortenDefinition(d.definition, max: 160), d.term);
      final wrong = pickDistractors(d.term, terms, _random,
          preferred: relatedTerms(d, quizDefs).take(3).toList(), question: masked);
      if (wrong.length < 2) continue;
      final term = normalizeChoice(d.term);
      final choices = [term, ...wrong]..shuffle(_random);
      questions.add(QuizQuestion(
        prompt: 'Which term is this? $masked',
        choices: choices,
        answerIndex: choices.indexOf(term),
        explanation: '${d.term}: ${shortenDefinition(d.definition, max: 160)}',
      ));
    }

    // "Which of these belongs under <title>?": the right choice is a point from
    // that list, the wrong ones real points from the notes' other lists. All four
    // are worded by the notes, so none is a rewording and none looks made up.
    String point(String item) =>
        shortenDefinition(item, max: 70, early: true).replaceAll(RegExp(r'[.;,…]+$'), '');
    var listQuestions = 0;
    for (var round = 0; round < 2 && listQuestions < _maxListQuestions; round++) {
      for (final l in lists) {
        if (listQuestions >= _maxListQuestions || l.items.length <= round || l.items.length < 3) continue;
        final correct = normalizeChoice(point(l.items[round]));
        if (correct.split(' ').length > 14) continue;
        // Points from the lists most like this one first (a "principles" list for a
        // "principles" list), so the wrong choices are the same kind of thing.
        // Only lists whose points are built like these (a word or two each, or a
        // short sentence each): otherwise a wrong choice is plain from its length.
        final byLikeness = [
          for (final o in lists)
            if (o.heading != l.heading && _similarShape(l, o)) o,
        ]..sort((a, b) => _likeness(l, b).compareTo(_likeness(l, a)));
        if (byLikeness.isEmpty) continue;
        var wrong = const <String>[];
        for (var take = 1; take <= byLikeness.length; take++) {
          wrong = pickDistractors(
              correct, [for (final o in byLikeness.take(take)) for (final x in o.items) point(x)], _random,
              question: l.heading, fact: l.items.join('. '));
          if (wrong.length == 3) break;
        }
        if (wrong.length < 2) continue;
        final choices = [correct, ...wrong]..shuffle(_random);
        questions.add(QuizQuestion(
          prompt: 'Which of these belongs under "${l.heading}"?',
          choices: choices,
          answerIndex: choices.indexOf(correct),
          explanation: '${l.heading}: ${l.items.take(4).map(point).join('; ')}',
        ));
        listQuestions++;
      }
    }

    // Quiz choices must be short phrases, and each answer is used once.
    final quizItems = [
      for (final it in items)
        if (!it.answer.contains('\n') && it.answer.split(RegExp(r'\s+')).length <= 14) it,
    ];
    final usedAnswers = <String>{};
    for (final it in quizItems) {
      if (!usedAnswers.add(it.answer.toLowerCase().trim())) continue;
      // ponytail: "who" vs the rest is the only kind split; add place/thing if mixes show up
      final who = _who.hasMatch(it.question);
      final pool = [
        for (final p in quizItems)
          if (_who.hasMatch(p.question) == who) p.answer,
        // Definitions from the notes are true of something else: good wrong
        // choices for a phrase answer.
        if (!who)
          for (final d in defs)
            if (!d.definition.contains('\n')) shortenDefinition(withoutTerm(d.definition, d.term), max: 80),
      ];
      final wrong = pickDistractors(it.answer, pool, _random,
          preferred: it.wrong, question: it.question, fact: it.fact);
      if (wrong.length < 2) continue; // too little to choose between
      final answer = normalizeChoice(it.answer);
      final choices = [answer, ...wrong]..shuffle(_random);
      questions.add(QuizQuestion(
        prompt: it.question,
        choices: choices,
        answerIndex: choices.indexOf(answer),
        explanation: it.fact,
      ));
    }
    return GeneratedSet(questions, [
      for (final l in lists) Flashcard(front: l.heading, back: formatList(l.items)),
      for (final d in defs)
        Flashcard(
            front: d.term,
            back: d.definition.contains('\n')
                ? d.definition
                : shortenDefinition(withoutTerm(d.definition, d.term))),
      for (final it in items)
        Flashcard(
            front: it.question,
            back: it.answer.contains('\n') ? it.answer : shortenDefinition(it.answer)),
    ]);
  }

  static double _avgWords(NotesList l) =>
      l.items.map((x) => x.split(' ').length).reduce((x, y) => x + y) / l.items.length;

  /// Points written alike: both lists start their points with lower case ("to see
  /// ...") or both with capitals, and of about the same length (within 2 words, or
  /// 40% for longer ones).
  static bool _similarShape(NotesList a, NotesList b) {
    bool lower(NotesList l) => l.items.where((x) => RegExp(r'^[a-z]').hasMatch(x)).length * 2 >= l.items.length;
    final x = _avgWords(a), y = _avgWords(b);
    return lower(a) == lower(b) && (x - y).abs() <= max(2, 0.4 * max(x, y));
  }

  /// How alike two lists are: shared title words count most, then points of similar length.
  static double _likeness(NotesList a, NotesList b) {
    Set<String> stems(String s) => {
          for (final m in RegExp(r'[a-z]{4,}').allMatches(s.toLowerCase()))
            m[0]!.endsWith('s') ? m[0]!.substring(0, m[0]!.length - 1) : m[0]!,
        };
    double avg(NotesList l) =>
        l.items.map((x) => x.split(' ').length).reduce((x, y) => x + y) / l.items.length;
    return stems(a.heading).intersection(stems(b.heading)).length * 10 - (avg(a) - avg(b)).abs();
  }

  /// Question/answer pairs for one section, or null if the model cannot
  /// produce usable ones. Only items backed by the section's text are kept.
  Future<List<QaItem>?> _itemsFor(String chunk, String? original) async {
    final n = tier.questionsPerChunk;
    List<String>? facts;
    for (var i = 0; i < maxAttempts && facts == null; i++) {
      try {
        final got = parseFacts(await runtime.complete(
          buildFactsPrompt(chunk, facts: n),
          maxTokens: 700,
          schema: factsSchema(n),
        )).where((f) => !isVague(f) && !looksLikeCitation(f) && isGrounded(f, chunk, minRatio: 0.5)).toList();
        if (got.isNotEmpty) facts = got;
      } on FormatException {
        continue; // malformed output: retry
      }
    }
    if (facts == null) return null;

    // Facts whose question was unusable (e.g. it gave the answer away) are asked again.
    final items = <QaItem>[];
    var todo = facts;
    for (var i = 0; i < maxAttempts && todo.isNotEmpty; i++) {
      try {
        final got = parseQa(await runtime.complete(
          buildQaPrompt(todo),
          maxTokens: 700,
          schema: qaSchema(todo.length),
        ));
        for (final q in got) {
          // The fact this question was written from: the closest one (the model does not
          // always keep the facts' order).
          final source = bestFact(todo, '${q.question} ${q.answer}');
          var answer = q.answer;
          var plain = q.answer; // the answer's words, without list numbering
          var grounded = answerInNotes(q.answer, chunk);
          // "What are the three principles...?" needs all three, each brief. The model
          // often gives two or runs them together, so the notes' own list is used then.
          final n = expectedCount(q.question);
          final wantsList = asksForList(q.question);
          if (wantsList) {
            // The notes' own list is the complete one; the model's is the fallback.
            var list = listFromNotes(chunk, n, '${q.question} ${q.answer}', minShared: 2);
            grounded = list != null;
            if (list == null) {
              list = numberedItems(q.answer);
              if (list != null && (n == null || list.length == n) && answerInNotes(list.join(', '), chunk)) {
                grounded = true;
              } else {
                list = null;
              }
            }
            if (list == null) continue; // a single sentence or an incomplete list would mislead
            answer = formatList(list);
            plain = list.join(', ');
          }
          final question = unleak(q.question, plain);
          // Strict fidelity: one fact, its own words. A question or answer that needs
          // more than that fact (or invents) is dropped, not shown.
          if (!wantsList &&
              question != null &&
              (!isGrounded(question, source, minRatio: 0.6) || !answerInFact(plain, source, question))) {
            continue;
          }
          if (question == null ||
              isVague(question) ||
              looksLikeCitation(question) ||
              looksLikeCitation(plain) ||
              (!wantsList && q.answer.trimRight().endsWith(',')) || // cut off mid-sentence
              !isGrounded(question, chunk) ||
              !grounded ||
              (original != null && !answerInNotes(plain, original))) {
            continue;
          }
          items.add(QaItem(question, answer, fact: source));
        }
        todo = [for (final f in todo) if (!items.any((it) => it.fact == f)) f];
      } on FormatException {
        continue;
      }
    }
    return items.isEmpty ? null : _withWrongAnswers(items);
  }

  /// [items] with the model's believable wrong answers attached. Asked once:
  /// if it fails, other answers from the notes still fill the quiz.
  Future<List<QaItem>> _withWrongAnswers(List<QaItem> items) async {
    // List answers are card-only; they get no multiple-choice wrong answers.
    final single = [for (final it in items) if (!it.answer.contains('\n')) it];
    if (single.isEmpty) return items;
    try {
      final wrong = parseWrong(await runtime.complete(
        buildWrongPrompt(single),
        maxTokens: 900,
        schema: wrongSchema(single.length),
      ));
      return [
        for (final it in items)
          if (it.answer.contains('\n'))
            it
          else
            QaItem(it.question, it.answer,
                fact: it.fact,
                wrong: single.indexOf(it) < wrong.length ? wrong[single.indexOf(it)] : const []),
      ];
    } on FormatException {
      return items;
    }
  }

  /// Longest section the summary asks the model to explain at once.
  static const _summaryChunkChars = 3000;

  /// The most topics a summary is split into.
  static const _maxSections = 14;

  /// Works out what the notes are about, then has the model teach it. Language
  /// processing comes first and costs no model time: paged slides are split
  /// into topics by their headings, each topic gets its key phrases and its
  /// most central lines, and the model is shown only those. It then explains
  /// each topic (one call per topic), and one more call ties them into an
  /// overview and takeaways. Explanations that copy the slides or are not based
  /// on them are dropped.
  @override
  Future<LessonSummary> summarize(
    String notes, {
    void Function(double fraction)? onProgress,
  }) async {
    final groups = groupSlides(notes, maxGroups: _maxSections) ?? _plainGroups(notes);
    final idf = idfOf([for (final g in groups) g.text]);

    final sections = <SummarySection>[];
    for (var i = 0; i < groups.length; i++) {
      final s = await _sectionFor(groups[i], idf);
      onProgress?.call((i + 1) / (groups.length + 1));
      if (s != null) sections.add(s);
    }
    final explained = [for (final s in sections) if (s.explanation.isNotEmpty) s];
    if (explained.isEmpty) throw GenerationFailed();

    final lessonTerms = keyTerms(notes, n: 8);
    final (overview, takeaways) = await _overviewFor(explained, lessonTerms);
    onProgress?.call(1);
    return LessonSummary(
      overview: overview,
      sections: sections,
      keyTerms: lessonTerms,
      // Without the last pass, the first key point of each section is what to remember.
      takeaways: takeaways.isNotEmpty
          ? takeaways
          : [
              for (final s in explained)
                if (s.keyPoints.isNotEmpty) s.keyPoints.first,
            ].take(5).toList(),
    );
  }

  /// [notes] cut by length for the summary, when they have no slide titles.
  List<SlideGroup> _plainGroups(String notes) {
    final text = dropRepeatedLines(notes);
    // Small sections so each topic is explained on its own; bigger only when
    // the notes are too long for maxChunks of that size.
    final size = max(tier.chunkChars ~/ 2, min(_summaryChunkChars, (text.length / maxChunks).ceil()));
    var all = chunkText(text, size);
    final long = all.where((c) => c.length >= _minChunkChars).toList();
    if (long.isNotEmpty) all = long;
    // Spread over the whole document, not just its first pages.
    final chunks = all.length <= maxChunks
        ? all
        : [for (var i = 0; i < maxChunks; i++) all[i * all.length ~/ maxChunks]];
    return [for (final c in chunks) SlideGroup(c)];
  }

  /// One explained section for [group], or null if the model cannot produce a
  /// usable one and the group has no dates or figures to show. Sentences not
  /// based on the notes are dropped, and an explanation that is copied from the
  /// notes or left with nothing is retried. The dates and figures are lifted
  /// from the notes, so they stay even when the model fails.
  Future<SummarySection?> _sectionFor(SlideGroup group, Map<String, double> idf) async {
    final chunk = group.text;
    final facts = keyFacts(chunk);
    // What the model sees: the topic's key phrases and its most central lines.
    final terms = keyTerms(chunk, n: 4, idf: idf, boost: group.titles.join(' '));
    final items = textItems(chunk);
    final core = condense(items, maxChars: tier.chunkChars, keyTerms: terms, idf: idf).join('\n');
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final s = parseSection(await runtime.complete(
          buildSectionPrompt(core, topic: group.title, covers: group.titles, terms: terms),
          maxTokens: 700,
          schema: sectionSchema(),
        ));
        final explanation =
            dropContradictions(dropSlideTalk(groundedSentences(s.explanation, chunk)), items);
        if (explanation.length < 40 || isCopy(explanation, chunk) || copyRatio(explanation, chunk) >= 0.5) {
          continue; // lifted from the slides, not explained
        }
        final points = [
          for (final p in s.keyPoints)
            if (p.split(RegExp(r'\s+')).length >= 4 &&
                _isStatement(p) &&
                !p.endsWith(',') &&
                (p.length < 190 || RegExp(r'[.!?]$').hasMatch(p)) && // not cut off at the length limit
                isGrounded(p, chunk, minRatio: 0.5) &&
                figuresInSource(p, chunk) &&
                namesInSource(p, chunk) &&
                !contradicts(p, items) &&
                copyRatio(p, chunk) < 0.9) // a bullet copied word for word is not a point of its own
              p,
        ];
        return SummarySection(
          // A topic with one heading keeps it, so sections match the deck; a joined
          // topic is named by the model.
          heading: group.title ?? _heading(s.heading, group, terms),
          explanation: explanation,
          // The model's points, topped up with the section's most central lines.
          keyPoints: _distinct(points.length >= 2 ? points : [...points, ..._centralPoints(chunk, terms, idf, points)]),
          facts: facts,
          terms: terms,
        );
      } on FormatException {
        continue; // malformed output: retry
      }
    }
    // The model could not explain this topic. It still belongs in the lesson, so
    // show it as it is: its key phrases, its most central lines, its dates and figures.
    final points = _centralPoints(chunk, terms, idf, const []);
    if (points.isEmpty && facts.isEmpty) return null;
    return SummarySection(
      heading: group.title ??
          (group.titles.isNotEmpty ? group.titles.first : null) ??
          (terms.isEmpty ? 'More from the slides' : titleCase(terms.first)),
      explanation: '',
      keyPoints: points,
      facts: facts,
      terms: terms,
    );
  }

  /// The model's heading for a joined topic on one line, or if it rambles, the
  /// slides' first heading, or the topic's first key phrase.
  String _heading(String modelHeading, SlideGroup group, List<String> terms) {
    final h = modelHeading.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (h.split(' ').length <= 9 && h.length <= 70 && !RegExp(r'[-(]$').hasMatch(h)) return h;
    if (group.titles.isNotEmpty) return group.titles.first;
    return terms.isEmpty ? 'More from the slides' : titleCase(terms.first);
  }

  /// A point that can stand alone: it starts with a capital, is not a title or
  /// label, and is not cut off ("A trade secret is...").
  bool _isStatement(String p) =>
      RegExp('^[A-Z"\u201C(\\d]').hasMatch(p) &&
      !isHeadingLine(p) &&
      !looksLikeLabel(p) &&
      !RegExp(r'(?:\.\.\.|\u2026)$').hasMatch(p);

  List<String> _distinct(List<String> points) {
    final seen = <String>{};
    return [
      for (final p in points)
        if (seen.add(p.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))) p,
    ];
  }

  /// The most central lines of [text] that read as points, for when the model
  /// gives too few: whole sentences from the notes, not labels, up to three.
  List<String> _centralPoints(
      String text, List<String> terms, Map<String, double> idf, List<String> have) {
    final lines = condense(textItems(text), maxChars: 420, keyTerms: terms, idf: idf);
    return [
      for (final l in lines)
        if (l.split(RegExp(r'\s+')).length >= 5 &&
            l.length <= 200 &&
            _isStatement(l) &&
            !have.any((h) => copyRatio(h, l) > 0.6))
          l,
    ].take(3 - have.length).toList();
  }

  /// The lesson's overview and takeaways, or empty ones if the model fails:
  /// the sections alone are still a usable lesson.
  Future<(String, List<String>)> _overviewFor(List<SummarySection> sections, List<String> terms) async {
    final source = [
      for (final s in sections)
        '${s.heading} ${s.explanation} ${s.keyPoints.join(' ')} ${s.facts.join(' ')}',
    ].join('\n');
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final (overview, takeaways) = parseOverview(await runtime.complete(
          buildOverviewPrompt(sections, terms: terms),
          maxTokens: 600,
          schema: overviewSchema(),
        ));
        final checked = groundedSentences(overview, source, minRatio: 0.3);
        if (checked.isEmpty) continue;
        // An overview that repeats one section is no overview.
        if (sections.length > 1 && sections.any((s) => copyRatio(checked, s.explanation) >= 0.7)) continue;
        return (
          checked,
          [
            for (final t in takeaways)
              if (!isVague(t) && groundedSentences(t, source).isNotEmpty) groundedSentences(t, source),
          ],
        );
      } on FormatException {
        continue;
      }
    }
    return ('', const <String>[]);
  }

  /// Room for the lesson text in the chat prompt (the context window is small).
  static const _chatNotesChars = 5000;
  static const _chatHistoryTurns = 6;

  @override
  Future<String> ask(String notes, List<ChatTurn> history) async {
    final recent = history.length > _chatHistoryTurns
        ? history.sublist(history.length - _chatHistoryTurns)
        : history;
    final query = recent.where((t) => t.role == 'user').map((t) => t.text).join(' ');
    final lesson = pickContext(notes, query, maxChars: _chatNotesChars);
    final reply = await runtime.chat([
      {
        'role': 'system',
        'content': 'You are a friendly tutor helping a student understand their lesson. '
            'Explain clearly and simply, in a few short paragraphs at most. '
            'Base your answer on the lesson notes below. If the notes do not cover the question, '
            'say so briefly, then give a short general explanation.\n\nLESSON NOTES:\n$lesson',
      },
      for (final t in recent) {'role': t.role, 'content': t.text},
    ]);
    return reply.trim();
  }

  @override
  Future<void> dispose() => runtime.dispose();
}
