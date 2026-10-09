import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/ui/set_detail_screen.dart';
import 'package:kodigno/ui/theme.dart';

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 16; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('a set with no cards still opens the flashcards, and the count follows what is added', (t) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StudyRepository(db);
    final id = (await t.runAsync(() => repo.saveSet('Bio', const GeneratedSet([], []), sourceText: 'x')))!;
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(1000, 1200);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: kTheme(), home: SetDetailScreen(repo: repo, setId: id)));
    await _settle(t);
    expect(find.text('Add your own'), findsOneWidget);

    await t.tap(find.text('Flashcards'));
    await _settle(t);
    expect(find.text('Write your first card'), findsOneWidget);
    await t.tap(find.text('Write your first card'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('card-term')), 'Nucleus');
    await t.enterText(find.byKey(const ValueKey('card-definition')), 'Holds the DNA.');
    await t.pump();
    await t.tap(find.text('Save card'));
    await _settle(t);

    await t.tap(find.byIcon(Icons.close).last); // the flashcards page's own close, back to the set
    await _settle(t);
    expect(find.text('1 card'), findsOneWidget);
    expect(find.text('Add your own'), findsNothing);
  });

  testWidgets('counts read "1 question" and "2 cards", not "1 questions"', (t) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StudyRepository(db);
    final id = (await t.runAsync(() => repo.saveSet(
        'Bio',
        const GeneratedSet(
          [QuizQuestion(prompt: 'Q?', choices: ['a', 'b'], answerIndex: 0)],
          [Flashcard(front: 'a', back: 'b'), Flashcard(front: 'c', back: 'd')],
        ),
        sourceText: 'x')))!;
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(1000, 1200);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: kTheme(), home: SetDetailScreen(repo: repo, setId: id)));
    await _settle(t);
    expect(find.text('1 question'), findsOneWidget);
    expect(find.text('2 cards'), findsOneWidget);
  });
}
