import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/database.dart';
import 'levels.dart';
import 'nlp.dart';
import 'story_engine.dart';

/// A saved story, ready to read.
class Story extends Passage {
  const Story(this.id, super.level, this.topic, super.title, super.paras, super.questions, this.checks, {this.source = 'ai'});
  final int id;

  /// ai, starter, or teacher (a teacher's own text: extra practice, no topic to write more of).
  final String source;
  bool get byTeacher => source == 'teacher';
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
        source: r.source,
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
  const ReaderReport(this.reader, this.stories, this.avg, this.recent, this.up, this.down, this.skills, this.needs, [
    this.wpm,
  ]);
  final Reader reader;
  final int stories;
  final int? avg;

  /// Average words a minute over timed stories, if any.
  final int? wpm;
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

/// One line on where a reader stands, for the teacher.
String readerStatus(ReaderReport r) {
  if (!r.reader.placed) return 'Reading check not done';
  if (r.down >= 1 && r.reader.level > 0) return 'Needs help: last score under 60%';
  if (r.up == 2 && r.reader.level < levels.length - 1) return 'One strong score from moving up';
  if (r.stories == 0) return 'Has not read yet';
  return 'On track';
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
      "SELECT id FROM stories WHERE level = ? AND pipeline = ? AND source <> 'teacher' AND (? IS NULL OR topic = ? COLLATE NOCASE) "
      'AND id NOT IN (SELECT story_id FROM reading_attempts WHERE reader_id = ?) ORDER BY id LIMIT 1',
      variables: [Variable(level), Variable(pipelineVersion), Variable(topic), Variable(topic), Variable(readerId)],
      readsFrom: {db.stories, db.readingAttempts},
    ).getSingleOrNull();
    return row?.read<int>('id');
  }

  /// Any current story at [level], read or not: the last resort when the AI is down.
  Future<int?> anyStory(int level) async {
    final row = await db.customSelect(
      "SELECT id FROM stories WHERE level = ? AND pipeline = ? AND source <> 'teacher' ORDER BY RANDOM() LIMIT 1",
      variables: [Variable(level), Variable(pipelineVersion)],
      readsFrom: {db.stories},
    ).getSingleOrNull();
    return row?.read<int>('id');
  }

  /// Teacher stories this reader has not read, oldest first: ones made for them,
  /// and ones for everyone at their color.
  Future<List<({int id, String title})>> teacherStories(
    int readerId,
    int level,
  ) async {
    final rows = await db
        .customSelect(
          "SELECT id, title, level, checks FROM stories WHERE source = 'teacher' "
          'AND id NOT IN (SELECT story_id FROM reading_attempts WHERE reader_id = ?) ORDER BY id',
          variables: [Variable(readerId)],
          readsFrom: {db.stories, db.readingAttempts},
        )
        .get();
    return [
      for (final r in rows)
        if (assignedTo(r.read<String>('checks')) case final who
            when who == null ? r.read<int>('level') == level : who == readerId)
          (id: r.read<int>('id'), title: r.read<String>('title')),
    ];
  }

  /// The reader a teacher story was made for, or null for everyone at its color.
  static int? assignedTo(String checksJson) {
    try {
      return (jsonDecode(checksJson) as Map)['for'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// Every teacher story, newest first, for the teacher's list.
  Future<List<StoryRow>> allTeacherStories() =>
      (db.select(db.stories)
            ..where((s) => s.source.equals('teacher'))
            ..orderBy([(s) => OrderingTerm.desc(s.id)]))
          .get();

  /// Deletes a teacher story nobody has read yet. False = it has scores, so it stays.
  Future<bool> deleteTeacherStory(int id) async {
    final n = await db.customUpdate(
      "DELETE FROM stories WHERE id = ? AND source = 'teacher' AND id NOT IN (SELECT story_id FROM reading_attempts)",
      variables: [Variable(id)],
      updateKind: UpdateKind.delete,
      updates: {db.stories},
    );
    return n > 0;
  }

  // ---------- my words ----------

  /// Remembers a word the reader asked about. Asking again adds to [SavedWord.times].
  Future<void> saveWord(
    int readerId,
    String word,
    String meaning,
    String? synonym,
    String sentence,
  ) async {
    final w = word.toLowerCase();
    final have =
        await (db.select(db.savedWords)
              ..where((x) => x.readerId.equals(readerId) & x.word.equals(w)))
            .getSingleOrNull();
    if (have == null) {
      await db
          .into(db.savedWords)
          .insert(
            SavedWordsCompanion.insert(
              readerId: readerId,
              word: w,
              meaning: meaning,
              synonym: Value(synonym),
              sentence: sentence,
            ),
          );
    } else {
      await (db.update(
        db.savedWords,
      )..where((x) => x.id.equals(have.id))).write(
        SavedWordsCompanion(
          times: Value(have.times + 1),
          meaning: Value(meaning),
          synonym: Value(synonym),
          sentence: Value(sentence),
        ),
      );
    }
  }

  /// The reader's words, ones still being learned first.
  Future<List<SavedWord>> words(int readerId) =>
      (db.select(db.savedWords)
            ..where((x) => x.readerId.equals(readerId))
            ..orderBy([
              (x) => OrderingTerm.asc(x.known),
              (x) => OrderingTerm.desc(x.id),
            ]))
          .get();

  /// Practice result: right adds to the streak, wrong starts it over. 3 in a row = learned.
  Future<void> markWord(int id, {required bool right}) async {
    final w = await (db.select(
      db.savedWords,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    if (w == null) return;
    await (db.update(db.savedWords)..where((x) => x.id.equals(id))).write(
      SavedWordsCompanion(known: Value(right ? w.known + 1 : 0)),
    );
  }

  /// Copies the bundled starter stories in. Safe to run on every start: a story
  /// already there (same color and title) is skipped, so new releases add new ones.
  Future<void> loadStarters(String json) async {
    final have = {
      for (final r in await (db.select(db.stories)..where((s) => s.source.equals('starter'))).get())
        '${r.level}|${r.title}',
    };
    await db.batch((b) {
      for (final s in jsonDecode(json) as List) {
        final m = s as Map<String, dynamic>;
        if (!have.add('${m['level']}|${m['title']}')) continue;
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

  /// The reader's latest scores, newest first. A teacher's own story is extra
  /// practice (it can be any color), so it never counts toward moving a color.
  Future<List<Score>> recent(int readerId, [int limit = 3]) async {
    final rows = await db.customSelect(
      'SELECT a.level, a.correct, a.total FROM reading_attempts a JOIN stories s ON s.id = a.story_id '
      "WHERE a.reader_id = ? AND s.source <> 'teacher' ORDER BY a.id DESC LIMIT ?",
      variables: [Variable(readerId), Variable(limit)],
      readsFrom: {db.readingAttempts, db.stories},
    ).get();
    return [
      for (final r in rows) (level: r.read<int>('level'), pct: (r.read<int>('correct') * 100 / r.read<int>('total')).round()),
    ];
  }

  Future<({int up, int down})> progress(Reader r) async => streaks(r.level, await recent(r.id));

  /// The highest color the reader has reached, for the badge shelf. A color
  /// earned stays earned even if a bad run moves the reader down.
  Future<int> bestLevel(Reader r) async {
    final row = await db
        .customSelect(
          'SELECT MAX(level + CASE WHEN moved > 0 THEN 1 ELSE 0 END) AS best FROM reading_attempts WHERE reader_id = ?',
          variables: [Variable(r.id)],
          readsFrom: {db.readingAttempts},
        )
        .getSingle();
    final best = row.read<int?>('best') ?? 0;
    return best > r.level ? best : r.level;
  }

  /// Days in a row the reader has finished a story, counting back from today
  /// (or from yesterday, if they have not read yet today).
  Future<({int days, bool today})> dayStreak(
    int readerId, {
    DateTime? now,
  }) async {
    final rows = await (db.select(
      db.readingAttempts,
    )..where((a) => a.readerId.equals(readerId))).get();
    DateTime day(DateTime t) => DateTime(t.year, t.month, t.day);
    final days = {for (final a in rows) day(a.takenAt)};
    final today = day(now ?? DateTime.now());
    final readToday = days.contains(today);
    var d = readToday
        ? today
        : DateTime(today.year, today.month, today.day - 1);
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return (days: n, today: readToday);
  }

  /// Words a minute from the reader's last [limit] timed stories, oldest first.
  Future<List<int>> speeds(int readerId, {int limit = 10}) async {
    final rows =
        await (db.select(db.readingAttempts)
              ..where((a) => a.readerId.equals(readerId) & a.wpm.isNotNull())
              ..orderBy([(a) => OrderingTerm.desc(a.id)])
              ..limit(limit))
            .get();
    return [for (final a in rows.reversed) a.wpm!];
  }

  /// The teacher asks for the reading check again. The color stays until it is done.
  Future<void> resetPlacement(int readerId) =>
      (db.update(db.readers)..where((r) => r.id.equals(readerId))).write(
        const ReadersCompanion(placed: Value(false)),
      );

  /// Saves the reader's answers to [story] and moves their color if earned.
  Future<AnswerResult> answer(Reader r, Story story, List<int> answers, {
    int? wpm,
  }) => db.transaction(() async {
        final right = [for (final (i, q) in story.questions.indexed) answers[i] == q.answer];
        final correct = right.where((x) => x).length;
        final total = story.questions.length;
        final attempt = await db.into(db.readingAttempts).insert(ReadingAttemptsCompanion.insert(
              readerId: r.id,
              storyId: story.id,
              level: r.level,
              correct: correct,
              total: total,
            wpm: Value(wpm),
              skills: Value(jsonEncode([
                for (final (i, q) in story.questions.indexed) {'skill': skillOf(q.question), 'correct': right[i]}
              ])),
            ));
        final extra = (await (db.select(db.stories)..where((s) => s.id.equals(story.id))).getSingleOrNull())?.source == 'teacher';
        final level = extra ? r.level : nextLevel(r.level, await recent(r.id));
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
    final extraIds = {for (final s in await (db.select(db.stories)..where((s) => s.source.equals('teacher'))).get()) s.id};
    final reports = <ReaderReport>[];
    for (final r in await readers()) {
      final mine = all.where((a) => a.readerId == r.id).toList();
      final recent = [for (final a in mine.take(6)) (level: a.level, pct: (a.correct * 100 / a.total).round())];
      // Same rule as moving a color: a teacher's story does not count.
      final s = streaks(r.level, [
        for (final a in mine.where((a) => !extraIds.contains(a.storyId)).take(3)) (level: a.level, pct: (a.correct * 100 / a.total).round()),
      ]);
      final sk = _skillTotals(mine);
      final avg = mine.isEmpty ? null : (mine.fold(0.0, (n, a) => n + a.correct * 100 / a.total) / mine.length).round();
      final timed = [
        for (final a in mine.take(10))
          if (a.wpm != null) a.wpm!,
      ];
      final wpm = timed.isEmpty
          ? null
          : (timed.reduce((a, b) => a + b) / timed.length).round();
      reports.add(ReaderReport(r, mine.length, avg, recent, s.up, s.down, sk, weakest(sk),
          wpm));
    }
    final total = {
      for (final k in skills)
        k: reports.fold((0, 0), (acc, rr) => (acc.$1 + rr.skills[k]!.$1, acc.$2 + rr.skills[k]!.$2)),
    };
    return ClassReport(reports, total, weakest(total));
  }
}
