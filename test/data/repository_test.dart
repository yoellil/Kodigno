import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/models.dart';

void main() {
  late AppDatabase db;
  late StudyRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StudyRepository(db);
  });
  tearDown(() => db.close());

  const set = GeneratedSet(
    [QuizQuestion(prompt: 'Q', choices: ['a', 'b'], answerIndex: 1, explanation: 'e')],
    [Flashcard(front: 'f', back: 'b')],
  );

  test('save then load a set with source info', () async {
    final id = await repo.saveSet('Bio', set,
        sourceType: 'pdf', sourceText: 'cells', sourcePaths: ['C:/n.pdf']);
    final d = await repo.getSet(id);
    expect(d.set.title, 'Bio');
    expect(d.set.sourceType, 'pdf');
    expect(d.set.sourceText, 'cells');
    expect(d.questions.single.answerIndex, 1);
    expect(d.questions.single.choices, '["a","b"]');
    expect(d.flashcards.single.back, 'b');
  });

  test('library lists newest first with stats and last score percent', () async {
    final now = DateTime(2026, 10, 9, 12);
    final a = await repo.saveSet('One', set);
    final b = await repo.saveSet('Two', set);
    await repo.saveAttempt(setId: a, score: 3, total: 5, durationSeconds: 9,
        results: const [], takenAt: DateTime(2026, 9, 20)); // outside the week
    await repo.saveAttempt(setId: a, score: 4, total: 5, durationSeconds: 9,
        results: const [], takenAt: DateTime(2026, 10, 9, 9));
    await repo.saveAttempt(setId: b, score: 1, total: 4, durationSeconds: 9,
        results: const [], takenAt: DateTime(2026, 10, 8, 9));
    final lib = await repo.libraryData(now: now);
    expect(lib.sets.map((s) => s.title), ['Two', 'One']);
    expect(lib.lastPercent[a], 80);
    expect(lib.lastPercent[b], 25);
    expect(lib.stats.sets, 2);
    expect(lib.stats.answeredThisWeek, 9); // 5 + 4
    expect(lib.stats.streakDays, 2);
  });

  test('watchLibrary emits current data', () async {
    await repo.saveSet('One', set);
    final lib = await repo.watchLibrary().first;
    expect(lib.sets, hasLength(1));
  });

  test('deleting a set cascades to questions, cards and attempts', () async {
    final id = await repo.saveSet('Bio', set);
    await repo.saveAttempt(setId: id, score: 1, total: 1, durationSeconds: 5,
        results: [{'q': 0, 'chosen': 1, 'correct': true}]);
    expect((await repo.attemptsFor(id)).single.score, 1);
    await repo.deleteSet(id);
    expect(await repo.attemptsFor(id), isEmpty);
    expect(await db.select(db.questionRows).get(), isEmpty);
    expect(await db.select(db.flashcardRows).get(), isEmpty);
  });
}
