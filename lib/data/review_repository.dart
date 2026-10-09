import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/source_ref.dart';
import '../study/confusions.dart';
import '../study/diagnosis.dart';
import '../study/practice_session.dart';
import '../study/scheduler.dart';
import '../study/session_plan.dart';
import 'database.dart';

/// An answer the student gave to a quiz question.
typedef QuizAnswer = ({int questionId, int chosen, bool correct});

/// The answers in a finished quiz's [results] (a map per question with its
/// position 'q', the choice picked 'chosen', and whether it was 'correct'), tied
/// to the ids of the questions in the order they were asked. A question left
/// unanswered is not an answer.
List<QuizAnswer> quizAnswersFrom(List<Map<String, Object>> results, List<int> questionIds) => [
      for (final r in results)
        if ((r['chosen'] as int) >= 0)
          (
            questionId: questionIds[r['q'] as int],
            chosen: r['chosen'] as int,
            correct: r['correct'] == true,
          ),
    ];

/// The student's practice history: every answer given, and where each flashcard
/// and question stands in the schedule.
class ReviewRepository {
  ReviewRepository(this.db);
  final AppDatabase db;

  Schedule _scheduleOf(ReviewState s) => Schedule(
      box: s.box,
      dueDay: s.dueDay,
      streak: s.streak,
      lapses: s.lapses,
      lastDay: s.lastAt == null ? null : dayOf(s.lastAt!));

  /// Every flashcard and quiz question in the library, with its schedule (none
  /// for one that has never been answered).
  Future<List<Candidate>> candidates() async {
    final states = await db.select(db.reviewStates).get();
    final byItem = {for (final s in states) (s.kind, s.itemId): s};
    final cards = await db.select(db.flashcardRows).get();
    final questions = await db.select(db.questionRows).get();
    return [
      for (final c in cards)
        Candidate(
          kind: ItemKind.card,
          itemId: c.id,
          setId: c.studySetId,
          schedule: byItem[('card', c.id)] == null ? null : _scheduleOf(byItem[('card', c.id)]!),
          key: practiceKey(c.front),
        ),
      for (final q in questions)
        Candidate(
          kind: ItemKind.question,
          itemId: q.id,
          setId: q.studySetId,
          schedule: byItem[('question', q.id)] == null ? null : _scheduleOf(byItem[('question', q.id)]!),
          key: practiceKey(q.prompt),
        ),
    ];
  }

  /// How many items are due, new, or not due yet, in all or in one set.
  Future<PracticeCounts> counts({int? setId, DateTime? now}) async =>
      countFor(await candidates(), now ?? DateTime.now(), setId: setId);

  /// The items of a session that holds up to [size] items, in all or in one set:
  /// what is due, then new items, then items that are not due yet.
  Future<({SessionPlan plan, List<PracticeItem> items})> startSession(
      {required int size, int? setId, DateTime? now, int contrastLimit = 1}) async {
    final at = now ?? DateTime.now();
    final plan = planSession(await candidates(), now: at, size: size, setId: setId);
    final items = await _withContrast(await itemsFor(plan.items),
        size: size, setId: setId, now: at, limit: contrastLimit);
    return (plan: plan, items: items);
  }

  /// [items] with, at the front, a card that sets side by side two things the
  /// student keeps mixing up, then the question that was missed. A pair is shown
  /// once a day, and only if the slides say something about both. If the question
  /// was not already in the session it takes the place of the last item.
  Future<List<PracticeItem>> _withContrast(
    List<PracticeItem> items, {
    required int size,
    int? setId,
    required DateTime now,
    required int limit,
  }) async {
    if (limit <= 0) return items;
    final out = [...items];
    var added = 0;
    for (final c in await confusions(setId: setId)) {
      if (added >= limit) break;
      if (await contrastShownOn(c.questionId, now)) continue;
      final card = await contrastFor(c);
      if (card == null) continue;
      PracticeItem? question;
      final at = out.indexWhere((i) => i.kind == ItemKind.question && i.itemId == c.questionId);
      if (at >= 0) {
        question = out.removeAt(at);
      } else {
        question = (await itemsFor([Candidate(kind: ItemKind.question, itemId: c.questionId, setId: c.setId)]))
            .firstOrNull;
        if (question == null) continue;
        if (out.length >= size && out.isNotEmpty) out.removeLast();
      }
      out.insertAll(0, [
        PracticeItem(
          kind: ItemKind.contrast,
          itemId: c.questionId,
          setId: c.setId,
          setTitle: question.setTitle,
          prompt: 'Easy to mix up',
          answer: '',
          contrast: card,
        ),
        question,
      ]);
      added++;
    }
    return out;
  }

  /// The content of [picked], in the same order. An item whose card or question
  /// has been deleted since is left out.
  Future<List<PracticeItem>> itemsFor(List<Candidate> picked) async {
    if (picked.isEmpty) return const [];
    final cardIds = [for (final c in picked) if (c.kind == ItemKind.card) c.itemId];
    final questionIds = [for (final c in picked) if (c.kind == ItemKind.question) c.itemId];
    final cards = {
      for (final c in await (db.select(db.flashcardRows)..where((t) => t.id.isIn(cardIds))).get()) c.id: c,
    };
    final questions = {
      for (final q in await (db.select(db.questionRows)..where((t) => t.id.isIn(questionIds))).get()) q.id: q,
    };
    final titles = {
      for (final s in await db.select(db.studySets).get()) s.id: s.title,
    };
    final out = <PracticeItem>[];
    for (final c in picked) {
      if (c.kind == ItemKind.card) {
        final row = cards[c.itemId];
        if (row == null) continue;
        out.add(PracticeItem(
          kind: ItemKind.card,
          itemId: row.id,
          setId: row.studySetId,
          setTitle: titles[row.studySetId] ?? '',
          prompt: row.front,
          answer: row.back,
          source: SourceRef.decode(row.source),
        ));
      } else {
        final row = questions[c.itemId];
        if (row == null) continue;
        final List<String> choices;
        try {
          choices = [for (final x in jsonDecode(row.choices) as List) '$x'];
        } on FormatException {
          continue;
        }
        if (row.answerIndex < 0 || row.answerIndex >= choices.length) continue;
        out.add(PracticeItem(
          kind: ItemKind.question,
          itemId: row.id,
          setId: row.studySetId,
          setTitle: titles[row.studySetId] ?? '',
          prompt: row.prompt,
          answer: choices[row.answerIndex],
          choices: choices,
          answerIndex: row.answerIndex,
          explanation: row.explanation,
          source: SourceRef.decode(row.source),
        ));
      }
    }
    return out;
  }

  /// How many times each wrong choice was picked, by question id and then by the
  /// choice's position: "picked it before" for the Detective. In all, or in one set.
  Future<Map<int, Map<int, int>>> wrongPickCounts({int? setId}) async {
    final q = db.select(db.reviewLog)
      ..where((t) =>
          t.kind.equals(ItemKind.question.name) &
          t.correct.equals(false) &
          t.chosen.isNotNull() &
          (setId == null ? const Constant(true) : t.studySetId.equals(setId)));
    final out = <int, Map<int, int>>{};
    for (final e in await q.get()) {
      final byChoice = out.putIfAbsent(e.itemId, () => {});
      byChoice[e.chosen!] = (byChoice[e.chosen!] ?? 0) + 1;
    }
    return out;
  }

  /// How many times [chosen] was picked, wrongly, for question [questionId].
  Future<int> timesPicked(int questionId, int chosen) async {
    final rows = await (db.select(db.reviewLog)
          ..where((t) =>
              t.kind.equals(ItemKind.question.name) &
              t.itemId.equals(questionId) &
              t.correct.equals(false) &
              t.chosen.equals(chosen)))
        .get();
    return rows.length;
  }

  /// The study sets with these ids, by id. A set that has been deleted is not in it.
  Future<Map<int, StudySet>> setsById(Iterable<int> ids) async => {
        for (final s in await (db.select(db.studySets)..where((t) => t.id.isIn(ids.toList()))).get()) s.id: s,
      };

  /// Every wrong answer to a question, oldest first, as the choice picked and the
  /// right one.
  Future<List<WrongPick>> wrongPicks({int? setId}) async {
    final log = await (db.select(db.reviewLog)
          ..where((t) =>
              t.kind.equals(ItemKind.question.name) &
              t.correct.equals(false) &
              t.chosen.isNotNull() &
              (setId == null ? const Constant(true) : t.studySetId.equals(setId)))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    if (log.isEmpty) return const [];
    final rows = {
      for (final q in await (db.select(db.questionRows)..where((t) => t.id.isIn({for (final e in log) e.itemId}.toList()))).get())
        q.id: q,
    };
    final out = <WrongPick>[];
    for (final e in log) {
      final q = rows[e.itemId];
      if (q == null) continue;
      final List<String> choices;
      try {
        choices = [for (final x in jsonDecode(q.choices) as List) '$x'];
      } on FormatException {
        continue;
      }
      final c = e.chosen!;
      if (c < 0 || c >= choices.length || q.answerIndex < 0 || q.answerIndex >= choices.length) continue;
      out.add(WrongPick(questionId: q.id, setId: q.studySetId, picked: choices[c], answer: choices[q.answerIndex]));
    }
    return out;
  }

  /// The pairs the student keeps mixing up, in all or in one set, most often first.
  Future<List<Confusion>> confusions({int? setId, int minTimes = 2}) async {
    final picks = await wrongPicks(setId: setId);
    if (picks.isEmpty) return const [];
    final states = await (db.select(db.reviewStates)
          ..where((t) => t.kind.equals(ItemKind.question.name)))
        .get();
    return findConfusions(picks,
        streakByQuestion: {for (final s in states) s.itemId: s.streak}, minTimes: minTimes);
  }

  /// [c] as two terms side by side with what the slides say about each, or null
  /// if the set has no pages or the slides say nothing about one of them.
  Future<ContrastCard?> contrastFor(Confusion c) async {
    final set = (await setsById([c.setId]))[c.setId];
    if (set == null) return null;
    final pages = parsePages(set.sourceText);
    if (pages.isEmpty) return null;
    final index = PageIndex(pages);
    final a = whatSlidesSay(c.a, index, pages), b = whatSlidesSay(c.b, index, pages);
    if (a == null || b == null) return null;
    return ContrastCard(
      a: ContrastSide(term: c.a, text: a.text, page: a.page),
      b: ContrastSide(term: c.b, text: b.text, page: b.page),
      times: c.times,
      questionId: c.questionId,
      setId: c.setId,
    );
  }

  /// True if a contrast card for [questionId] was already shown on [day].
  Future<bool> contrastShownOn(int questionId, DateTime day) async {
    final start = dayOf(day);
    final rows = await (db.select(db.reviewLog)
          ..where((t) =>
              t.kind.equals(ItemKind.contrast.name) &
              t.itemId.equals(questionId) &
              t.at.isBiggerOrEqualValue(start)))
        .get();
    return rows.any((e) => dayOf(e.at) == start);
  }

  /// Records one answer of a practice session. Seeing a contrast card is noted in
  /// the log, so it is not shown again today, and nothing else moves.
  Future<void> recordPractice(PracticeItem item, bool correct, int? chosen, {DateTime? now}) {
    if (item.kind == ItemKind.contrast) {
      return db.into(db.reviewLog).insert(ReviewLogCompanion.insert(
            kind: ItemKind.contrast.name,
            itemId: item.itemId,
            studySetId: item.setId,
            correct: true,
            mode: 'practice',
            at: Value(now ?? DateTime.now()),
          ));
    }
    return _recordAnswer(item, correct, chosen, now: now);
  }

  Future<void> _recordAnswer(PracticeItem item, bool correct, int? chosen, {DateTime? now}) => record(
        kind: item.kind,
        itemId: item.itemId,
        setId: item.setId,
        correct: correct,
        chosen: chosen,
        mode: 'practice',
        now: now,
      );

  /// Records one answer: it goes in the log, and the item's schedule moves on.
  /// [mode] is 'practice' or 'quiz'; [chosen] is the choice picked, for a question.
  Future<void> record({
    required ItemKind kind,
    required int itemId,
    required int setId,
    required bool correct,
    required String mode,
    int? chosen,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return db.transaction(() async {
      await db.into(db.reviewLog).insert(ReviewLogCompanion.insert(
            kind: kind.name,
            itemId: itemId,
            studySetId: setId,
            correct: correct,
            chosen: Value(chosen),
            mode: mode,
            at: Value(at),
          ));
      final existing = await (db.select(db.reviewStates)
            ..where((t) => t.kind.equals(kind.name) & t.itemId.equals(itemId)))
          .getSingleOrNull();
      final next = afterAnswer(existing == null ? const Schedule() : _scheduleOf(existing), correct: correct, now: at);
      if (existing == null) {
        await db.into(db.reviewStates).insert(ReviewStatesCompanion.insert(
              kind: kind.name,
              itemId: itemId,
              studySetId: setId,
              box: Value(next.box),
              dueDay: Value(next.dueDay),
              lastAt: Value(at),
              streak: Value(next.streak),
              lapses: Value(next.lapses),
            ));
      } else {
        await (db.update(db.reviewStates)..where((t) => t.id.equals(existing.id))).write(ReviewStatesCompanion(
          box: Value(next.box),
          dueDay: Value(next.dueDay),
          lastAt: Value(at),
          streak: Value(next.streak),
          lapses: Value(next.lapses),
        ));
      }
    });
  }

  /// Records all the answers of one finished quiz, so a quiz feeds the same
  /// history and schedule as practice does.
  Future<void> recordQuiz({required int setId, required List<QuizAnswer> answers, DateTime? now}) async {
    for (final a in answers) {
      await record(
        kind: ItemKind.question,
        itemId: a.questionId,
        setId: setId,
        correct: a.correct,
        chosen: a.chosen,
        mode: 'quiz',
        now: now,
      );
    }
  }
}
