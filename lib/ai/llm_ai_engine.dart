import 'dart:math';

import '../domain/definitions.dart';
import '../domain/models.dart';
import '../domain/output_parser.dart';
import '../domain/prompt.dart';
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

  /// Questions whose answer is a person. Their fallback choices are other people.
  static final _who = RegExp(r'\bwho(m|se)?\b', caseSensitive: false);

  @override
  Future<GeneratedSet> generate(
    String notes, {
    void Function(double fraction)? onProgress,
  }) async {
    final text = dropRepeatedLines(notes);
    final defs = extractDefinitions(text);
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
      final got = await _itemsFor(chunks[i]);
      onProgress?.call((i + 1) / chunks.length);
      for (final it in got ?? const <QaItem>[]) {
        if (seen.add(it.question.toLowerCase().trim())) items.add(it);
      }
    }
    if (items.isEmpty && defs.isEmpty) throw GenerationFailed();

    // Show the definition, pick the term; the other terms are the wrong choices.
    final questions = <QuizQuestion>[];
    final terms = [for (final d in defs) d.term];
    for (final d in defs) {
      final masked = maskTerm(d.definition, d.term);
      final wrong = pickDistractors(d.term, terms, _random,
          preferred: relatedTerms(d, defs).take(3).toList(), question: masked);
      if (wrong.length < 2) continue;
      final choices = [d.term, ...wrong]..shuffle(_random);
      questions.add(QuizQuestion(
        prompt: 'Which term is this? $masked',
        choices: choices,
        answerIndex: choices.indexOf(d.term),
        explanation: '${d.term}: ${d.definition}',
      ));
    }

    // Quiz choices must be short phrases, and each answer is used once.
    final quizItems = [
      for (final it in items)
        if (it.answer.split(RegExp(r'\s+')).length <= 14) it,
    ];
    final usedAnswers = <String>{};
    for (final it in quizItems) {
      if (!usedAnswers.add(it.answer.toLowerCase().trim())) continue;
      // ponytail: "who" vs the rest is the only kind split; add place/thing if mixes show up
      final who = _who.hasMatch(it.question);
      final pool = [
        for (final p in quizItems)
          if (_who.hasMatch(p.question) == who) p.answer,
      ];
      final wrong = pickDistractors(it.answer, pool, _random,
          preferred: it.wrong, question: it.question);
      if (wrong.length < 2) continue; // too little to choose between
      final choices = [it.answer, ...wrong]..shuffle(_random);
      questions.add(QuizQuestion(
        prompt: it.question,
        choices: choices,
        answerIndex: choices.indexOf(it.answer),
        explanation: it.fact,
      ));
    }
    return GeneratedSet(questions, [
      for (final d in defs) Flashcard(front: d.term, back: d.definition),
      for (final it in items) Flashcard(front: it.question, back: it.answer),
    ]);
  }

  /// Question/answer pairs for one section, or null if the model cannot
  /// produce usable ones. Only items backed by the section's text are kept.
  Future<List<QaItem>?> _itemsFor(String chunk) async {
    final n = tier.questionsPerChunk;
    List<String>? facts;
    for (var i = 0; i < maxAttempts && facts == null; i++) {
      try {
        final got = parseFacts(await runtime.complete(
          buildFactsPrompt(chunk, facts: n),
          maxTokens: 700,
          schema: factsSchema(n),
        )).where((f) => !isVague(f) && isGrounded(f, chunk, minRatio: 0.5)).toList();
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
          final question = unleak(q.question, q.answer);
          if (question == null ||
              isVague(question) ||
              q.answer.trimRight().endsWith(',') || // cut off mid-sentence
              !isGrounded(question, chunk) ||
              !answerInNotes(q.answer, chunk)) {
            continue;
          }
          items.add(QaItem(question, q.answer, fact: bestFact(todo, '$question ${q.answer}')));
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
    try {
      final wrong = parseWrong(await runtime.complete(
        buildWrongPrompt(items),
        maxTokens: 900,
        schema: wrongSchema(items.length),
      ));
      return [
        for (var i = 0; i < items.length; i++)
          QaItem(items[i].question, items[i].answer,
              fact: items[i].fact, wrong: i < wrong.length ? wrong[i] : const []),
      ];
    } on FormatException {
      return items;
    }
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
