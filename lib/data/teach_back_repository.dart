import 'dart:convert';

import 'package:drift/drift.dart';

import '../study/teach_back.dart';
import 'database.dart';

/// A saved try, with the ideas the student then said they had covered counted in.
extension TeachBackAttemptCounts on TeachBackAttempt {
  List<int> get overruledIdeas {
    try {
      return [for (final x in jsonDecode(overruled) as List) if (x is int) x];
    } on FormatException {
      return const [];
    }
  }

  /// Ideas covered, counting the ones the student said they covered after all.
  int get coveredCounted => (covered + overruledIdeas.length).clamp(0, total);
}

/// The student's explanations of lesson topics, kept on the device.
class TeachBackRepository {
  TeachBackRepository(this.db);
  final AppDatabase db;

  /// Saves one try at topic [section] (number [sectionIndex]) of set [setId].
  Future<int> save({
    required int setId,
    required String section,
    required int sectionIndex,
    required String answer,
    required TeachBackResult result,
    DateTime? now,
  }) =>
      db.into(db.teachBackAttempts).insert(TeachBackAttemptsCompanion.insert(
            studySetId: setId,
            section: section,
            sectionIndex: Value(sectionIndex),
            answer: answer,
            covered: Value(result.covered),
            partly: Value(result.partly),
            total: Value(result.total),
            copied: Value(result.copied),
            flagCount: Value(result.flags.length),
            checkedBy: Value(result.checkedBy.name),
            takenAt: now == null ? const Value.absent() : Value(now),
          ));

  /// Notes that the student says idea number [ideaIndex] of try [attemptId] was
  /// covered after all. Said twice, it counts once; a position outside the ideas
  /// is ignored.
  Future<void> overrule(int attemptId, int ideaIndex) async {
    final a = await (db.select(db.teachBackAttempts)..where((t) => t.id.equals(attemptId))).getSingleOrNull();
    if (a == null || ideaIndex < 0 || ideaIndex >= a.total) return;
    final now = a.overruledIdeas;
    if (now.contains(ideaIndex)) return;
    await (db.update(db.teachBackAttempts)..where((t) => t.id.equals(attemptId)))
        .write(TeachBackAttemptsCompanion(overruled: Value(jsonEncode([...now, ideaIndex]))));
  }

  /// The key ideas saved for topic [section] of set [setId], or null if there are none yet.
  Future<List<String>?> conceptsFor(int setId, String section) async {
    final row = await (db.select(db.topicConcepts)
          ..where((t) => t.studySetId.equals(setId) & t.section.equals(section)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      final list = [for (final x in jsonDecode(row.concepts) as List) if (x is String && x.trim().isNotEmpty) x];
      return list.length >= 2 ? list : null;
    } on FormatException {
      return null;
    }
  }

  /// Keeps the key ideas of topic [section] of set [setId], replacing any before.
  Future<void> saveConcepts(int setId, String section, List<String> concepts) {
    final json = jsonEncode(concepts);
    return db.into(db.topicConcepts).insert(
          TopicConceptsCompanion.insert(studySetId: setId, section: section, concepts: json),
          // a topic has one row: a second save of the same topic updates it
          onConflict: DoUpdate((_) => TopicConceptsCompanion(concepts: Value(json)),
              target: [db.topicConcepts.studySetId, db.topicConcepts.section]),
        );
  }

  /// The tries at topic [section] of set [setId], the newest first.
  Future<List<TeachBackAttempt>> attemptsFor(int setId, String section) => (db.select(db.teachBackAttempts)
        ..where((t) => t.studySetId.equals(setId) & t.section.equals(section))
        ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .get();

  /// The latest try at each topic of set [setId], by the topic's heading.
  Future<Map<String, TeachBackAttempt>> latestBySection(int setId) async {
    final all = await (db.select(db.teachBackAttempts)
          ..where((t) => t.studySetId.equals(setId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return {for (final a in all) a.section: a};
  }
}
