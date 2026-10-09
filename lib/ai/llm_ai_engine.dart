import 'dart:math';

import '../domain/definitions.dart';
import '../domain/factcheck.dart';
import '../domain/hygiene.dart';
import '../domain/judge.dart';
import '../domain/lists.dart';
import '../domain/models.dart';
import '../domain/nlp.dart';
import '../domain/output_parser.dart';
import '../domain/prompt.dart';
import '../domain/source_ref.dart';
import '../domain/summary.dart';
import '../study/teach_judge.dart';
import '../domain/topics.dart';
import '../models/tier.dart';
import 'ai_engine.dart';

/// Builds a study set from each topic of the notes: language processing picks
/// the topic's most central statements (no model), the model writes one
/// question and short answer per statement, then believable wrong answers of
/// the same kind for the quiz. Other answers from the notes and nearby numbers
/// fill in when the model's wrong answers are missing or unusable.
/// "Term - definition" lines in the notes also become cards and quiz questions
/// directly, with no model involved. Last, a fact check: the model answers each
/// question it wrote from the notes passages most like it, and questions it
/// gets wrong are dropped.
class LlmAiEngine implements AiEngine {
  LlmAiEngine(
    this.runtime,
    this.tier, {
    this.maxChunks = 12,
    this.maxAttempts = 3,
    this.readBack = false,
    this.readBackBudget = const Duration(minutes: 3),
    Random? random,
  }) : _random = random ?? Random();

  final LlmRuntime runtime;
  final Tier tier;
  final int maxChunks;
  final int maxAttempts;

  /// After the cheap checks, have the model read the answer back out of the notes
  /// and keep the card only if it reads what the card says. See judge.dart.
  final bool readBack;

  /// Reading back stops after this long (slow devices): the rest rely on the cheap checks.
  final Duration readBackBudget;
  final Stopwatch _reading = Stopwatch();
  final Random _random;

  /// Sections shorter than this are headings and filler, not worth a model call.
  static const _minChunkChars = 80;

  /// [text] ready for generation: one kind of line break (Windows files and
  /// PDFs bring "\r\n"), no reference lists, run-together headings spaced, no
  /// footers that repeat on every page.
  static String _cleaned(String text) => dropRepeatedLines(
      stripReferences(fixSquashedText(stripPageMarkers(text).replaceAll('\r\n', '\n').replaceAll('\r', '\n'))));

  /// Enough list questions to fill a quiz without crowding out the rest.
  static const _maxListQuestions = 8;

  /// Questions whose answer is a person. Their fallback choices are other people.
  static final _who = RegExp(r'\bwho(m|se)?\b', caseSensitive: false);

  /// What sort of answer [question] wants, so wrong choices are the same sort.
  static String _kindOf(String question) {
    final q = question.toLowerCase();
    if (_who.hasMatch(q)) return 'who';
    if (RegExp(r'\b(?:how many|how much|how long|how old|what age|what number)\b').hasMatch(q)) return 'count';
    if (RegExp(r'\b(?:when|what year|which year|what date|what month|in what year|in which year)\b').hasMatch(q)) return 'when';
    if (RegExp(r'\b(?:where|which city|what city|which town|what town|which country|what country|which province)\b|\bin which (?:city|town|country|place|province)\b').hasMatch(q)) {
      return 'where';
    }
    return 'other';
  }

  @override
  Future<GeneratedSet> generate(String notes, {String? verifyIn, void Function(double fraction)? onProgress}) async {
    final text = _cleaned(notes);
    final original = verifyIn == null ? null : _cleaned(verifyIn);
    final source = original ?? text; // the lesson's own structure: lists and "Term - definition" lines
    // The notes' own titled lists ("General Ethical Principles" + its points).
    final lists = <NotesList>[];
    final titles = <String>{};
    for (final l in notesLists(source)) {
      if (l.heading.isEmpty || l.heading.split(' ').length < 2 || !looksLikeCategory(l.heading) || !isGoodList(l.items)) continue;
      if (_aims.hasMatch(l.heading) || _admin.hasMatch(l.heading)) continue;
      if (_looksLikeForm(l.heading) || l.items.where(_looksLikeForm).length * 2 >= l.items.length) continue;
      if (titles.add(l.heading.toLowerCase())) lists.add(l);
    }
    // Not a citation, a list's title, course admin or a filled-in form ("Address" - "PUROK 2 MARIKIT...").
    bool usable(Definition d) =>
        !looksLikeCitation('${d.term}: ${d.definition}') &&
        !titles.contains(d.term.toLowerCase()) &&
        !d.term.toLowerCase().contains('(cont') && // a slide's second page, not a term
        !_admin.hasMatch('${d.term} ${d.definition}') &&
        !_looksLikeForm('${d.term} ${d.definition}');
    // Cards from the notes alone: real definitions ("X - ...", "X is a ...") and lists under
    // a title that names a group. A slide title with one sentence under it is not kept:
    // on picture captions and wrapped lines it gave cards with no question in them.
    final patterns = {
      for (final d in extractDefinitions(source, headingCards: false)) '${d.term}\n${d.definition}',
    };
    final defs = [
      for (final d in extractDefinitions(source))
        if (usable(d) &&
            (patterns.contains('${d.term}\n${d.definition}') || d.definition.contains('\n') || d.term.endsWith('?')))
          d,
    ];
    // "Which term is this?" needs real definitions ("X - ...", "X is a ..."), not a
    // slide title with a sentence under it.
    var quizDefs = [
      for (final d in extractDefinitions(source, headingCards: false))
        if (usable(d) && d.definition.split(RegExp(r'\s+')).length >= 6) d,
    ];
    // Three or four terms cannot give a fair "which term" question: too little to choose from.
    if (quizDefs.length < 5) quizDefs = const [];
    String backOf(NotesList l) => formatList(l.items, bullets: !l.ordered);
    final listBacks = {for (final l in lists) backOf(l)};
    final index = NoteIndex(source);
    // Questions come from the notes' own lines, topic by topic: the original
    // slides, not the lesson written from them, so every answer is in their words.
    final groups =
        groupSlides(source, maxGroups: maxChunks) ?? [for (final c in _chunks(source, tier.chunkChars)) SlideGroup(c)];
    final idf = idfOf([for (final g in groups) g.text]);

    final items = <QaItem>[];
    final seen = <String>{};
    for (var i = 0; i < groups.length; i++) {
      final got = await _itemsFor(groups[i], idf, original, index);
      onProgress?.call((i + 1) / (groups.length + 1));
      for (final it in got ?? const <QaItem>[]) {
        // One card per list: not again under a second question, nor when the
        // list already has its own titled card.
        if (it.answer.contains('\n') && (listBacks.contains(it.answer) || !seen.add(it.answer))) continue;
        if (items.any((x) => sameQuestion(x.question, x.answer, it.question, it.answer))) continue;
        if (seen.add(it.question.toLowerCase().trim())) items.add(it);
      }
    }
    // Every answer the model wrote is checked before it becomes a card or a
    // question. Lists and definitions are the notes' own words.
    final failed = await _factChecked([
      for (final it in items)
        if (!it.answer.contains('\n')) it,
    ], source);
    items.removeWhere(failed.contains);
    onProgress?.call(1);
    if (items.isEmpty && defs.isEmpty && lists.isEmpty) throw GenerationFailed();

    // Show the definition, pick the term; the other terms are the wrong choices.
    final questions = <QuizQuestion>[];
    final terms = [for (final d in quizDefs) d.term];
    for (final d in quizDefs) {
      if (d.definition.contains('\n')) continue; // a list is for a card, not a "which term" question
      final masked = maskTerm(shortenDefinition(d.definition, max: 160), d.term);
      final wrong = pickDistractors(
        d.term,
        terms,
        _random,
        preferred: relatedTerms(d, quizDefs).take(3).toList(),
        question: masked,
      );
      if (wrong.length < 2) continue;
      final term = normalizeChoice(d.term);
      final choices = [term, ...wrong]..shuffle(_random);
      questions.add(
        QuizQuestion(
          prompt: 'Which term is this? $masked',
          choices: choices,
          answerIndex: choices.indexOf(term),
          explanation: '${d.term}: ${shortenDefinition(d.definition, max: 160)}',
        ),
      );
    }

    // "Which of these belongs under <title>?": the right choice is a point from
    // that list, the wrong ones real points from the notes' other lists. All four
    // are worded by the notes, so none is a rewording and none looks made up.
    String point(String item) => shortenDefinition(item, max: 70, early: true).replaceAll(RegExp(r'[.;,…]+$'), '');
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
            correct,
            [
              for (final o in byLikeness.take(take))
                for (final x in o.items) point(x),
            ],
            _random,
            question: l.heading,
            fact: l.items.join('. '),
          );
          if (wrong.length == 3) break;
        }
        if (wrong.length < 2) continue;
        final choices = [correct, ...wrong]..shuffle(_random);
        questions.add(
          QuizQuestion(
            prompt: 'Which of these belongs under "${l.heading}"?',
            choices: choices,
            answerIndex: choices.indexOf(correct),
            explanation: '${l.heading}: ${l.items.take(4).map(point).join('; ')}',
          ),
        );
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
      // Wrong choices are other answers of the same kind (a person for "who", a year for
      // "when", a place for "where", a count for "how many").
      final kind = _kindOf(it.question);
      final pool = [
        for (final p in quizItems)
          if (_kindOf(p.question) == kind) p.answer,
        // Definitions from the notes are true of something else: good wrong choices for a
        // phrase answer (only real ones, and only enough of them to be fair).
        if (kind == 'other')
          for (final d in quizDefs)
            shortenDefinition(withoutTerm(d.definition, d.term), max: 80),
      ];
      final wrong = pickDistractors(
        it.answer,
        pool,
        _random,
        preferred: it.wrong,
        question: it.question,
        fact: it.fact,
      );
      if (wrong.length < 2) continue; // too little to choose between
      final answer = normalizeChoice(it.answer);
      final choices = [answer, ...wrong]..shuffle(_random);
      questions.add(QuizQuestion(
        prompt: it.question,
        choices: choices,
        answerIndex: choices.indexOf(answer),
        explanation: it.evidence.isNotEmpty ? it.evidence : it.fact,
      ));
    }
    return GeneratedSet(questions, [
      for (final l in lists) Flashcard(front: questionForTitle(l.heading), back: backOf(l)),
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
    double avg(NotesList l) => l.items.map((x) => x.split(' ').length).reduce((x, y) => x + y) / l.items.length;
    return stems(a.heading).intersection(stems(b.heading)).length * 10 - (avg(a) - avg(b)).abs();
  }

  /// Lines that are about the course or an exercise, not the subject.
  static final _admin = RegExp(
    r'\b(?:this|next|following) (?:module|lesson|chapter|activit(?:y|ies)|section|slide|page|form)s?\b|'
    r'\b(?:answer (?:key|sheet)|photo credits?|copyright|republic act|good luck|keep it up|congratulations|let me see)\b',
    caseSensitive: false,
  );

  /// Titles of what a lesson is for, not what it teaches.
  static final _aims = RegExp(r'^(?:objectives?|learning outcomes?|outline|agenda)$', caseSensitive: false);

  /// Lines that set a task ("Discuss...", "Write only the letter...") rather than state a fact.
  static final _task = RegExp(
    r"^(?:Discuss|Describe|Differentiate|Compare|Analy[sz]e|Appraise|Explain|Identify|Choose|Write|Print|Help|Fill|Let[’']s|Tell|Visit|Click|Answer)\b",
  );

  /// A line worth a question: a statement of six words or more. Not a question,
  /// title, task, lead-in ("...three dimensions:"), line cut off mid-sentence,
  /// blank to fill in, answer options, form, table, citation or course admin.
  static bool _isStudyLine(String s) {
    final words = s.split(RegExp(r'\s+'));
    if (words.length < 6 || s.length > 300 || s.endsWith('?') || s.endsWith(':') || s.contains('__')) return false;
    if (looksLikeCitation(s) || isVague(s) || _admin.hasMatch(s) || _task.hasMatch(s) || looksLikeLabel(s)) {
      return false;
    }
    return !RegExp(r'\s(?:a|an|the|of|to|for|and|or|in|on|with|by|from|as)$', caseSensitive: false).hasMatch(s) &&
        !_looksLikeForm(s);
  }

  /// Text from a form, an exercise or a table rather than prose: answer options,
  /// an exercise's "A. Read carefully...", a form's labels ("Name: ... Age: ..."),
  /// or a quarter of its words in capitals, or a quarter numbers and signs.
  static bool _looksLikeForm(String s) {
    if (RegExp(r'(?:^|\s)[A-E][.)]\s').allMatches(s).length >= 2 || RegExp(r'^[A-E]\.\s').hasMatch(s)) return true;
    if (':'.allMatches(s).length >= 2) return true;
    final words = s.split(RegExp(r'\s+'));
    final caps = words.where((w) => w.length > 1 && w == w.toUpperCase() && RegExp('[A-Z]').hasMatch(w)).length;
    final signs = words.where((w) => !RegExp('[A-Za-z]').hasMatch(w)).length;
    return caps * 4 >= words.length || signs * 4 >= words.length;
  }

  /// A "FACT or BLUFF" statement's verdict: the statement before it is false.
  static final _falseVerdict = RegExp(r'^(?:bluff|false|myth|wrong|incorrect)\b', caseSensitive: false);

  static final _pronounStart = RegExp(r'^(?:He|She|It|They|This|These|Those)\b');

  /// [item] cut into sentences, one fact each. A sentence that starts with "He",
  /// "It", "This"... stays with the one before, which says who or what that is,
  /// or is dropped if that makes too long a line. Not cut after "Dr." or "U.S.".
  static List<String> _sentences(String item) {
    final out = <String>[];
    for (final s in item.split(RegExp(r'(?<=[.!?])\s+(?=["“(]?[A-Z])'))) {
      final abbrev =
          out.isNotEmpty &&
          RegExp(r'(?:\b(?:Mr|Mrs|Ms|Dr|Fr|St|Sta|Sr|Jr|No|vs|Gen|Prof)|\b[A-Z])\.$').hasMatch(out.last);
      if (out.isNotEmpty && (abbrev || _pronounStart.hasMatch(s))) {
        if (abbrev || out.last.length + s.length < 250) out.last = '${out.last} $s';
      } else if (!_pronounStart.hasMatch(s)) {
        out.add(s);
      }
    }
    return out;
  }

  /// Up to [n] lines of [text] worth a question, the most central first.
  static List<String> studyLines(String text, Map<String, double> idf, int n) {
    final items = textItems(text);
    final lines = <String>{
      for (var i = 0; i < items.length; i++)
        if (i + 1 == items.length || !_falseVerdict.hasMatch(items[i + 1]))
          // without stray marks before it (") Don Pablo Ramon...")
          for (final s in _sentences(items[i]).map((s) => s.replaceFirst(RegExp('^[^A-Za-z0-9"“(]+'), '')))
            if (_isStudyLine(s)) s,
    }.toList();
    final score = centrality(
      lines,
      keyTerms: keyTerms(text, n: 4, idf: idf),
      idf: idf,
    );
    final order = List.generate(lines.length, (i) => i)..sort((a, b) => score[b].compareTo(score[a]));
    return [for (final i in order.take(n)) lines[i]];
  }

  /// Question/answer pairs for one topic, or null if the model cannot produce
  /// usable ones. Each is written from one of the topic's own lines (its
  /// [QaItem.fact]), and only items backed by that line are kept.
  Future<List<QaItem>?> _itemsFor(SlideGroup group, Map<String, double> idf, String? original, NoteIndex index) async {
    // Not a picture's caption the PDF reader took for a title ("Photo credit: Wikimedia").
    final heading =
        group.titles.length == 1 &&
            !RegExp(
              r'\b(?:photo|credits?|wikimedia|flickr|courtesy|image|figure)\b',
              caseSensitive: false,
            ).hasMatch(group.titles.first)
        ? group.titles.first
        : null;
    final chunk = [?heading, group.text].join('\n');
    // A point under a heading ("Has a frail body") says what it is about only with it.
    final facts = [
      for (final l in studyLines(group.text, idf, tier.questionsPerChunk))
        heading != null && !isGrounded(heading, l, minRatio: 0.5) ? '$heading: $l' : l,
    ];
    if (facts.isEmpty) return null;

    // Facts whose question was unusable (e.g. it gave the answer away) are asked again.
    final items = <QaItem>[];
    var todo = facts;
    for (var i = 0; i < maxAttempts && todo.isNotEmpty; i++) {
      try {
        // The most likely wording first (closest to the notes); a little variety
        // only when asking again.
        final got = parseQa(
          await runtime.chat(
            [
              {'role': 'user', 'content': buildQaPrompt(todo)},
            ],
            maxTokens: 700,
            temperature: i == 0 ? 0 : 0.3,
            schema: qaSchema(todo.length),
          ),
        );
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
            // a single sentence, an incomplete list or a form's lines would mislead
            if (list == null || list.any((x) => x.split(' ').length >= 3 && _looksLikeForm(x))) continue;
            answer = formatList(list);
            plain = list.join(', ');
          }
          if (hasLooseReference(q.question)) continue; // "When did he...?" teaches nothing without the notes
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
          // The notes themselves must state the answer, in one passage with the question's
          // subject, years and names. Lists come from the notes already.
          var evidence = '';
          if (!wantsList) {
            final check = checkQa(index, question, plain);
            if (!check.ok) continue;
            evidence = check.quote ?? '';
            if (readBack && _reading.elapsed < readBackBudget) {
              _reading.start();
              try {
                final read = parseReader(
                  await runtime.complete(
                    buildReaderPrompt(passage: check.passage ?? '', question: question),
                    maxTokens: 80,
                    schema: readerSchema(),
                  ),
                  check.passage ?? '',
                );
                if (!answerWithin(plain, read)) continue; // the notes do not say what the card says
              } on FormatException {
                continue; // an unreadable reply is not a pass
              } finally {
                _reading.stop();
              }
            }
          }
          items.add(QaItem(question, answer, fact: source, evidence: evidence));
        }
        todo = [
          for (final f in todo)
            if (!items.any((it) => it.fact == f)) f,
        ];
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
    final single = [
      for (final it in items)
        if (!it.answer.contains('\n')) it,
    ];
    if (single.isEmpty) return items;
    try {
      final wrong = parseWrong(
        await runtime.complete(buildWrongPrompt(single), maxTokens: 900, schema: wrongSchema(single.length)),
      );
      return [
        for (final it in items)
          if (it.answer.contains('\n'))
            it
          else
            QaItem(it.question, it.answer,
                fact: it.fact,
                evidence: it.evidence,
                wrong: single.indexOf(it) < wrong.length ? wrong[single.indexOf(it)] : const []),
      ];
    } on FormatException {
      return items;
    }
  }

  /// Fact check with retrieval: the model answers each of [items] again,
  /// reading only the line it was made from and the lines of [source] most like
  /// the question. The items whose answer comes back different, or "none" (a
  /// wrong answer or no clear one), are returned. An item the model cannot
  /// check (bad output) passes.
  Future<Set<QaItem>> _factChecked(List<QaItem> items, String source) async {
    final lines = [
      for (final l in textItems(source))
        if (l.split(' ').length >= 3) l,
    ];
    final idf = idfOf(lines);
    final failed = <QaItem>{};
    for (final it in items) {
      final passages = {it.fact, ...retrieve(it.question, lines, idf, k: 3)}.toList();
      try {
        final answer = parseCheck(
          await runtime.chat(
            [
              {'role': 'user', 'content': buildCheckPrompt(it.question, passages)},
            ],
            maxTokens: 80,
            temperature: 0,
            schema: checkSchema(),
          ),
        );
        if (answer == null || !sameAnswer(answer, it.answer)) failed.add(it);
      } on FormatException {
        continue;
      }
    }
    return failed;
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
    notes = stripPageMarkers(notes); // page markers are for the viewer, not the model
    final groups = groupSlides(notes, maxGroups: _maxSections) ?? _plainGroups(notes);
    final idf = idfOf([for (final g in groups) g.text]);

    final sections = <SummarySection>[];
    for (var i = 0; i < groups.length; i++) {
      final s = await _sectionFor(groups[i], idf);
      onProgress?.call((i + 1) / (groups.length + 1));
      if (s != null) sections.add(s);
    }
    final explained = [
      for (final s in sections)
        if (s.explanation.isNotEmpty) s,
    ];
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
    return [for (final c in _chunks(text, size)) SlideGroup(c)];
  }

  /// [text] in chunks of up to [size] characters without the short ones
  /// (headings, filler): at most [maxChunks], spread over the whole document,
  /// not just its first pages.
  List<String> _chunks(String text, int size) {
    var all = chunkText(text, size);
    final long = all.where((c) => c.length >= _minChunkChars).toList();
    if (long.isNotEmpty) all = long;
    return all.length <= maxChunks ? all : [for (var i = 0; i < maxChunks; i++) all[i * all.length ~/ maxChunks]];
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
        final s = parseSection(
          await runtime.complete(
            buildSectionPrompt(core, topic: group.title, covers: group.titles, terms: terms),
            maxTokens: 700,
            schema: sectionSchema(),
          ),
        );
        final explanation = dropContradictions(dropSlideTalk(groundedSentences(s.explanation, chunk)), items);
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
      heading:
          group.title ??
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
  List<String> _centralPoints(String text, List<String> terms, Map<String, double> idf, List<String> have) {
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
      for (final s in sections) '${s.heading} ${s.explanation} ${s.keyPoints.join(' ')} ${s.facts.join(' ')}',
    ].join('\n');
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final (overview, takeaways) = parseOverview(
          await runtime.complete(buildOverviewPrompt(sections, terms: terms), maxTokens: 600, schema: overviewSchema()),
        );
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

  /// The most central lines of [text] that fit in [maxChars], for a prompt.
  String _core(String text, int maxChars) => condense(textItems(text), maxChars: maxChars).join('\n');

  /// The key ideas of a topic, written by the model from its slides and kept only
  /// if the slides back them up. None if the model could not write at least two.
  @override
  Future<List<String>> topicConcepts(String slideText, {String? topic}) async {
    final core = _core(slideText, min(tier.chunkChars * 2, 1800));
    for (var i = 0; i < maxAttempts; i++) {
      try {
        // First try with no randomness: the same slides give the same ideas.
        final concepts = parseConcepts(
          await runtime.chat([
            {'role': 'user', 'content': buildConceptsPrompt(core, topic: topic)},
          ], maxTokens: 450, temperature: i == 0 ? 0 : 0.3, schema: conceptsSchema()),
          slideText,
        );
        if (concepts.length >= 2) return concepts;
      } on FormatException {
        continue; // malformed output: retry
      }
    }
    return const [];
  }

  /// What the model makes of a student's explanation against the topic's key ideas.
  /// Every verdict is checked against the student's own words. Throws
  /// [GenerationFailed] if the model gives nothing usable.
  @override
  Future<TeachBackJudgement> judgeExplanation({
    required List<String> concepts,
    required String answer,
    required String slideText,
  }) async {
    final shown = answer.length > 1500 ? answer.substring(0, 1500) : answer;
    final core = _core(slideText, 900);
    for (var i = 0; i < maxAttempts; i++) {
      try {
        // No randomness: the same explanation gets the same verdict.
        return parseJudgement(
          await runtime.chat([
            {'role': 'user', 'content': buildJudgePrompt(concepts: concepts, answer: shown, slideText: core)},
          ], maxTokens: 550, temperature: i == 0 ? 0 : 0.3, schema: judgeSchema(concepts.length)),
          conceptCount: concepts.length,
          answer: answer,
          slideText: slideText,
        );
      } on FormatException {
        continue;
      }
    }
    throw GenerationFailed();
  }

  /// Room for the lesson text in the chat prompt (the context window is small).
  static const _chatNotesChars = 5000;
  static const _chatHistoryTurns = 6;

  @override
  Future<String> ask(String notes, List<ChatTurn> history) async {
    notes = stripPageMarkers(notes);
    final recent = history.length > _chatHistoryTurns
        ? history.sublist(history.length - _chatHistoryTurns)
        : history;
    final query = recent.where((t) => t.role == 'user').map((t) => t.text).join(' ');
    final lesson = pickContext(notes, query, maxChars: _chatNotesChars);
    final reply = await runtime.chat([
      {
        'role': 'system',
        'content':
            'You are a friendly tutor helping a student understand their lesson. '
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
