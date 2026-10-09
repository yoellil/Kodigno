import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/card_assist.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/ui/card_editor.dart';
import 'package:kodigno/ui/flashcards_screen.dart';
import 'package:kodigno/ui/theme.dart';

late AppDatabase _db;
late StudyRepository _repo;

/// The database answers on the real clock, so give it time between frames.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pump(const Duration(milliseconds: 120));
  }
}

Future<int> _makeSet(WidgetTester t, List<Flashcard> cards) async =>
    (await t.runAsync(() => _repo.saveSet('Bio', GeneratedSet(const [], cards))))!;

Future<void> _open(WidgetTester t, int setId, {CardSuggester? suggest}) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1000, 1000);
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: kTheme(),
    home: FlashcardsScreen(repo: _repo, setId: setId, suggest: suggest),
  ));
  await _settle(t);
}

Finder get _term => find.byKey(const ValueKey('card-term'));
Finder get _def => find.byKey(const ValueKey('card-definition'));

void main() {
  setUp(() {
    _db = AppDatabase(NativeDatabase.memory());
    _repo = StudyRepository(_db);
  });
  tearDown(() async => _db.close());

  testWidgets('a correction to an AI-written card is saved to the database and shown', (t) async {
    final id = await _makeSet(t, const [Flashcard(front: 'Who wrote it?', back: 'A wrong answer')]);
    await _open(t, id);
    await t.tap(find.byTooltip('Edit card'));
    await t.pumpAndSettle();
    await t.enterText(_def, 'Rizal');
    await t.pump();
    await t.tap(find.text('Save changes'));
    await _settle(t);

    final saved = (await t.runAsync(() => _repo.getSet(id)))!.flashcards.single;
    expect((saved.front, saved.back), ('Who wrote it?', 'Rizal'));
    await t.tap(find.text('Flip'));
    await t.pumpAndSettle();
    expect(find.text('Rizal'), findsOneWidget);
  });

  testWidgets('Add card writes a new card and lands on it', (t) async {
    final id = await _makeSet(t, const [Flashcard(front: 'F1', back: 'B1')]);
    await _open(t, id);
    await t.tap(find.text('Add card'));
    await t.pumpAndSettle();
    await t.enterText(_term, 'Nucleus');
    await t.enterText(_def, 'Holds the DNA.');
    await t.pump();
    await t.tap(find.text('Save card'));
    await _settle(t);

    final cards = (await t.runAsync(() => _repo.getSet(id)))!.flashcards;
    expect(cards.map((c) => c.front), ['F1', 'Nucleus']);
    expect(find.text('Add a card'), findsNothing); // dialog closed
    expect(find.text('Nucleus'), findsOneWidget); // the deck is on the new card
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('an empty set offers to write the first card, with Ask AI filling the definition', (t) async {
    final id = await _makeSet(t, const []);
    final asked = <(AssistField, String, String)>[];
    await _open(t, id, suggest: (want, term, def) async {
      asked.add((want, term, def));
      return const CardSuggestion('Holds the DNA.');
    });
    expect(find.text('No flashcards in this set yet.'), findsOneWidget);
    await t.tap(find.text('Write your first card'));
    await t.pumpAndSettle();
    await t.enterText(_term, 'Nucleus');
    await t.pump();
    await t.tap(find.byTooltip('Suggest the definition from this term'));
    await t.pumpAndSettle();
    expect(asked.single, (AssistField.definition, 'Nucleus', ''));
    await t.tap(find.text('Save card'));
    await _settle(t);

    final cards = (await t.runAsync(() => _repo.getSet(id)))!.flashcards;
    expect((cards.single.front, cards.single.back), ('Nucleus', 'Holds the DNA.'));
    expect(find.text('No flashcards in this set yet.'), findsNothing);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('cancelling the Add card dialog adds nothing', (t) async {
    final id = await _makeSet(t, const [Flashcard(front: 'F1', back: 'B1')]);
    await _open(t, id);
    await t.tap(find.text('Add card'));
    await t.pumpAndSettle();
    await t.enterText(_term, 'Unsaved');
    await t.tap(find.text('Cancel'));
    await _settle(t);
    expect((await t.runAsync(() => _repo.getSet(id)))!.flashcards, hasLength(1));
  });
}
