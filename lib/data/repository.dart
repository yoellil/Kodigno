import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/models.dart';
import 'database.dart';
import 'stats.dart';

class LibraryStats {
  const LibraryStats(
      {required this.sets, required this.answeredThisWeek, required this.streakDays});
  final int sets, answeredThisWeek, streakDays;
}

class LibraryData {
  const LibraryData(this.sets, this.lastPercent, this.stats);
  final List<StudySet> sets;
  final Map<int, int> lastPercent;
  final LibraryStats stats;
}

class StudySetDetail {
  const StudySetDetail(this.set, this.questions, this.flashcards);
  final StudySet set;
  final List<QuestionRow> questions;
  final List<FlashcardRow> flashcards;
}

class StudyRepository {
  StudyRepository(this.db);
  final AppDatabase db;

  Future<int> saveSet(
    String title,
    GeneratedSet set, {
    String sourceType = 'text',
    String sourceText = '',
    List<String> sourcePaths = const [],
  }) {
    return db.transaction(() async {
      final id = await db.into(db.studySets).insert(StudySetsCompanion.insert(
            title: title,
            sourceType: Value(sourceType),
            sourceText: Value(sourceText),
            sourcePaths: Value(jsonEncode(sourcePaths)),
          ));
      for (final q in set.questions) {
        await db.into(db.questionRows).insert(QuestionRowsCompanion.insert(
              studySetId: id,
              prompt: q.prompt,
              choices: jsonEncode(q.choices),
              answerIndex: q.answerIndex,
              explanation: Value(q.explanation),
            ));
      }
      for (final c in set.flashcards) {
        await db.into(db.flashcardRows).insert(FlashcardRowsCompanion.insert(
            studySetId: id, front: c.front, back: c.back));
      }
      return id;
    });
  }

  Future<LibraryData> libraryData({DateTime? now}) async {
    now ??= DateTime.now();
    final sets = await (db.select(db.studySets)
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
    final attempts =
        await (db.select(db.attempts)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final last = <int, int>{};
    for (final a in attempts) {
      if (a.total > 0) last[a.studySetId] = (a.score * 100 / a.total).round();
    }
    final weekAgo = now.subtract(const Duration(days: 7));
    final answered = attempts
        .where((a) => a.takenAt.isAfter(weekAgo))
        .fold<int>(0, (sum, a) => sum + a.total);
    return LibraryData(
      sets,
      last,
      LibraryStats(
        sets: sets.length,
        answeredThisWeek: answered,
        streakDays: computeStreak(attempts.map((a) => a.takenAt), now),
      ),
    );
  }

  /// Emits on subscribe and after any table change.
  Stream<LibraryData> watchLibrary() async* {
    yield await libraryData();
    await for (final _ in db.tableUpdates(TableUpdateQuery.onAllTables(db.allTables))) {
      yield await libraryData();
    }
  }

  Future<StudySetDetail> getSet(int id) async {
    final set = await (db.select(db.studySets)..where((t) => t.id.equals(id))).getSingle();
    final qs = await (db.select(db.questionRows)..where((t) => t.studySetId.equals(id))).get();
    final cs = await (db.select(db.flashcardRows)..where((t) => t.studySetId.equals(id))).get();
    return StudySetDetail(set, qs, cs);
  }

  Future<void> deleteSet(int id) =>
      (db.delete(db.studySets)..where((t) => t.id.equals(id))).go();

  Future<void> saveAttempt({
    required int setId,
    required int score,
    required int total,
    required int durationSeconds,
    required List<Map<String, Object>> results,
    DateTime? takenAt,
  }) =>
      db.into(db.attempts).insert(AttemptsCompanion.insert(
            studySetId: setId,
            score: score,
            total: total,
            durationSeconds: durationSeconds,
            results: jsonEncode(results),
            takenAt: takenAt == null ? const Value.absent() : Value(takenAt),
          ));

  Future<List<Attempt>> attemptsFor(int setId) => (db.select(db.attempts)
        ..where((t) => t.studySetId.equals(setId))
        ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .get();
}
