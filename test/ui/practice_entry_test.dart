import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/data/repository.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/ui/library_screen.dart';
import 'package:kodigno/ui/practice_screen.dart';
import 'package:kodigno/ui/set_detail_screen.dart';
import 'package:kodigno/ui/theme.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 14; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await t.pump(const Duration(milliseconds: 80));
  }
}

Future<(AppDatabase, StudyRepository)> _env(WidgetTester t) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1200, 1400);
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() => t.runAsync(db.close));
  return (db, StudyRepository(db));
}

GeneratedSet _cards(String prefix, int n) =>
    GeneratedSet(const [], [for (var i = 1; i <= n; i++) Flashcard(front: '$prefix$i', back: 'answer $prefix$i')]);

void main() {
  testWidgets('the library shows Today\'s practice with what is waiting, and Start opens a session', (t) async {
    final (_, repo) = await _env(t);
    await t.runAsync(() => repo.saveSet('Module 3', _cards('f', 8)));
    await t.pumpWidget(MaterialApp(
      theme: kTheme(),
      home: Scaffold(body: LibraryScreen(repo: repo, tab: ValueNotifier(0))),
    ));
    await settle(t);

    expect(find.text("Today's practice"), findsOneWidget);
    expect(find.text('5 items · about 3 min'), findsOneWidget);

    await t.tap(find.text('Start'));
    await settle(t);
    expect(find.byType(PracticeScreen), findsOneWidget);
    expect(find.text('1 of 5'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('an empty library shows no practice card', (t) async {
    final (_, repo) = await _env(t);
    await t.pumpWidget(MaterialApp(
      theme: kTheme(),
      home: Scaffold(body: LibraryScreen(repo: repo, tab: ValueNotifier(0))),
    ));
    await settle(t);
    expect(find.text("Today's practice"), findsNothing);
  });

  testWidgets('the card follows the length picked: 2 minutes opens a session of 3', (t) async {
    final (_, repo) = await _env(t);
    await t.runAsync(() => repo.saveSet('Module 3', _cards('f', 8)));
    await t.pumpWidget(MaterialApp(
      theme: kTheme(),
      home: Scaffold(body: LibraryScreen(repo: repo, tab: ValueNotifier(0))),
    ));
    await settle(t);
    await t.tap(find.text('2 min'));
    await settle(t);
    await t.tap(find.text('Start'));
    await settle(t);
    expect(find.text('1 of 3'), findsOneWidget);
  });

  testWidgets('the card follows the set picked', (t) async {
    final (_, repo) = await _env(t);
    await t.runAsync(() async {
      await repo.saveSet('Alpha', _cards('alpha', 2));
      await repo.saveSet('Beta', _cards('beta', 6));
    });
    await t.pumpWidget(MaterialApp(
      theme: kTheme(),
      home: Scaffold(body: LibraryScreen(repo: repo, tab: ValueNotifier(0))),
    ));
    await settle(t);
    await t.tap(find.text('All sets'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Alpha').last);
    await settle(t);
    await t.tap(find.text('Start'));
    await settle(t);
    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.textContaining('alpha'), findsWidgets);
    expect(find.textContaining('beta'), findsNothing);
  });

  testWidgets('"Practice this set" on a set page practices only that set', (t) async {
    final (_, repo) = await _env(t);
    final mine = (await t.runAsync(() async {
      await repo.saveSet('Other', _cards('other', 7));
      return repo.saveSet('Mine', _cards('mine', 3));
    }))!;
    await t.pumpWidget(MaterialApp(theme: kTheme(), home: SetDetailScreen(repo: repo, setId: mine)));
    await settle(t);

    await t.ensureVisible(find.text('Practice this set'));
    await t.tap(find.text('Practice this set'));
    await settle(t);
    expect(find.byType(PracticeScreen), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.textContaining('mine'), findsWidgets);
    expect(find.textContaining('other'), findsNothing);
  });

  testWidgets('a set with nothing to ask has "Practice this set" turned off', (t) async {
    final (_, repo) = await _env(t);
    final empty = (await t.runAsync(() => repo.saveSet('Empty', const GeneratedSet([], []))))!;
    await t.pumpWidget(MaterialApp(theme: kTheme(), home: SetDetailScreen(repo: repo, setId: empty)));
    await settle(t);
    await t.tap(find.text('Practice this set'), warnIfMissed: false);
    await settle(t);
    expect(find.byType(PracticeScreen), findsNothing);
  });
}
