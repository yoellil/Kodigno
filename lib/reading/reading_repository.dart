import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/database.dart';
import 'levels.dart';
import 'nlp.dart';
import 'story_engine.dart';

/// A saved story, ready to read.
class Story extends Passage {
  const Story(this.id, super.level, this.topic, super.title, super.paras, super.questions, this.checks);
  final int id;
  final String topic;
  final Map<String, dynamic> checks;

  factory Story.fromRow(StoryRow r) => Story(
        r.id,
        r.level,
        r.topic,
        r.title,
        [for (final p in jsonDecode(r.paras) as List) List<String>.from(p as List)],
        [for (final q in jsonDecode(r.questions) as List) Question.fromJson(q as Map<String, dynamic>)],
        jsonDecode(r.checks) as Map<String, dynamic>,
      );
}

class DuplicateReader implements Exception {
  DuplicateReader(this.name);
  final String name;
  @override
  String toString() => '$name is already here. Pick your name from the list, or add your last initial.';
}

/// Right and total per reading skill.
typedef SkillTotals = Map<String, (int, int)>;

class AnswerResult {
  const AnswerResult(this.correct, this.total, this.from, this.level, this.up, this.down);
  final int correct, total, from, level;

  /// Streaks at the new level after this answer.
  final int up, down;
  int get pct => (correct * 100 / total).round();
}

class ReaderReport {
  const ReaderReport(this.reader, this.stories, this.avg, this.recent, this.up, this.down, this.skills, this.needs);
  final Reader reader;
  final int stories;
  final int? avg;
  final List<Score> recent; // newest first
  final int up, down;
  final SkillTotals skills;
  final ({String skill, int right, int total})? needs;
}

class ClassReport {
  const ClassReport(this.readers, this.skills, this.focus);
  final List<ReaderReport> readers;
  final SkillTotals skills;
  final ({String skill, int right, int total})? focus;
}

/// The skill to work on next: the lowest score under 70%, counting only skills with 3+ answers.
({String skill, int right, int total})? weakest(SkillTotals s) {
  final ranked = s.entries.where((e) => e.value.$2 >= 3).toList()
    ..sort((a, b) => (a.value.$1 / a.value.$2).compareTo(b.value.$1 / b.value.$2));
  if (ranked.isEmpty) return null;
  final (right, total) = ranked.first.value;
  return right / total < 0.7 ? (skill: ranked.first.key, right: right, total: total) : null;
}

class ReadingRepository {
  ReadingRepository(this.db);
  final AppDatabase db;

  // ---------- readers ----------

  Future<List<Reader>> readers() =>
      (db.select(db.readers)..orderBy([(r) => OrderingTerm(expression: r.name.lower())])).get();

  Future<Reader?> reader(int id) => (db.select(db.readers)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<Reader> addReader(String name) async {
    final clean = name.replaceAll(RegExp(r'[\u0000-\u001f<>]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) throw ArgumentError('Type your name');
    final taken = await (db.select(db.readers)..where((r) => r.name.lower().equals(clean.toLowerCase()))).getSingleOrNull();
    if (taken != null) throw DuplicateReader(taken.name);
    final id = await db.into(db.readers).insert(ReadersCompanion.insert(name: clean.length > 40 ? clean.substring(0, 40) : clean));
    return (await reader(id))!;
  }

  /// Placement result or the teacher's override.
  Future<void> setLevel(int readerId, int level) => (db.update(db.readers)..where((r) => r.id.equals(readerId)))
      .write(ReadersCompanion(level: Value(level), placed: const Value(true)));

  Future<void> deleteReader(int readerId) => (db.delete(db.readers)..where((r) => r.id.equals(readerId))).go();

  // ---------- stories ----------

  Future<int> saveStory(WrittenStory s, {String source = 'ai'}) => db.into(db.stories).insert(StoriesCompanion.insert(
        level: s.level,
        topic: s.topic,
        title: s.title,
        paras: jsonEncode(s.paras),
        questions: jsonEncode([for (final q in s.questions) q.toJson()]),
        checks: Value(jsonEncode(s.checks)),
        pipeline: pipelineVersion,
        source: Value(source),
      ));

  Future<Story?> story(int id) async {
    final r = await (db.select(db.stories)..where((s) => s.id.equals(id))).getSingleOrNull();
    return r == null ? null : Story.fromRow(r);
  }

  /// The oldest current story at [level] the reader has not read, on [topic] (any topic if null).
  Future<int?> unread(int readerId, int level, String? topic) async {
    final row = await db.customSelect(
      'SELECT id FROM stories WHERE level = ? AND pipeline = ? AND (? IS NULL OR topic = ? COLLATE NOCASE) '
      'AND id NOT IN (SELECT story_id FROM reading_attempts WHERE reader_id = ?) ORDER BY id LIMIT 1',
      variables: [Variable(level), Variable(pipelineVersion), Variable(topic), Variable(topic), Variable(readerId)],
      readsFrom: {db.stories, db.readingAttempts},
    ).getSingleOrNull();
    return row?.read<int>('id');
  }

  /// Any current story at [level], read or not: the last resort when the AI is down.
  Future<int?> anyStory(int level) async {
    final row = await db.customSelect(
      'SELECT id FROM stories WHERE level = ? AND pipeline = ? ORDER BY RANDOM() LIMIT 1',
      variables: [Variable(level), Variable(pipelineVersion)],
      readsFrom: {db.stories},
    ).getSingleOrNull();
    return row?.read<int>('id');
  }

  /// Copies the bundled starter stories in once.
  Future<void> loadStarters(String json) async {
    final have = await (db.select(db.stories)..where((s) => s.source.equals('starter'))..limit(1)).get();
    if (have.isNotEmpty) return;
    await db.batch((b) {
      for (final s in jsonDecode(json) as List) {
        final m = s as Map<String, dynamic>;
        b.insert(
            db.stories,
            StoriesCompanion.insert(
              level: m['level'] as int,
              topic: m['topic'] as String,
              title: m['title'] as String,
              paras: jsonEncode(m['paras']),
              questions: jsonEncode(m['questions']),
              checks: Value(jsonEncode(m['checks'] ?? {})),
              pipeline: pipelineVersion,
              source: const Value('starter'),
            ));
      }
    });
  }

  // ---------- scores ----------

  Future<List<Score>> recent(int readerId, [int limit = 3]) async {
    final rows = await (db.select(db.readingAttempts)
          ..where((a) => a.readerId.equals(readerId))
          ..orderBy([(a) => OrderingTerm.desc(a.id)])
          ..limit(limit))
        .get();
    return [for (final a in rows) (level: a.level, pct: (a.correct * 100 / a.total).round())];
  }

  Future<({int up, int down})> progress(Reader r) async => streaks(r.level, await recent(r.id));

  /// Saves the reader's answers to [story] and moves their color if earned.
  Future<AnswerResult> answer(Reader r, Story story, List<int> answers) => db.transaction(() async {
        final right = [for (final (i, q) in story.questions.indexed) answers[i] == q.answer];
        final correct = right.where((x) => x).length;
        final total = story.questions.length;
        final attempt = await db.into(db.readingAttempts).insert(ReadingAttemptsCompanion.insert(
              readerId: r.id,
              storyId: story.id,
              level: r.level,
              correct: correct,
              total: total,
              skills: Value(jsonEncode([
                for (final (i, q) in story.questions.indexed) {'skill': skillOf(q.question), 'correct': right[i]}
              ])),
            ));
        final level = nextLevel(r.level, await recent(r.id));
        if (level != r.level) {
          await (db.update(db.readers)..where((x) => x.id.equals(r.id))).write(ReadersCompanion(level: Value(level)));
          await (db.update(db.readingAttempts)..where((a) => a.id.equals(attempt)))
              .write(ReadingAttemptsCompanion(moved: Value((level - r.level).sign)));
        }
        final p = streaks(level, await recent(r.id));
        return AnswerResult(correct, total, r.level, level, p.up, p.down);
      });

  // ---------- teacher ----------

  /// Right and total per skill over the reader's last 10 stories.
  SkillTotals _skillTotals(List<ReadingAttempt> newestFirst) {
    final t = {for (final k in skills) k: (0, 0)};
    for (final a in newestFirst.take(10)) {
      for (final s in jsonDecode(a.skills) as List) {
        final k = s['skill'] as String;
        final (right, total) = t[k] ?? (0, 0);
        if (t.containsKey(k)) t[k] = (right + (s['correct'] == true ? 1 : 0), total + 1);
      }
    }
    return t;
  }

  Future<ClassReport> classReport() async {
    final all = await (db.select(db.readingAttempts)..orderBy([(a) => OrderingTerm.desc(a.id)])).get();
    final reports = <ReaderReport>[];
    for (final r in await readers()) {
      final mine = all.where((a) => a.readerId == r.id).toList();
      final recent = [for (final a in mine.take(6)) (level: a.level, pct: (a.correct * 100 / a.total).round())];
      final s = streaks(r.level, recent.take(3).toList());
      final sk = _skillTotals(mine);
      final avg = mine.isEmpty ? null : (mine.fold(0.0, (n, a) => n + a.correct * 100 / a.total) / mine.length).round();
      reports.add(ReaderReport(r, mine.length, avg, recent, s.up, s.down, sk, weakest(sk)));
    }
    final total = {
      for (final k in skills)
        k: reports.fold((0, 0), (acc, rr) => (acc.$1 + rr.skills[k]!.$1, acc.$2 + rr.skills[k]!.$2)),
    };
    return ClassReport(reports, total, weakest(total));
  }
}
