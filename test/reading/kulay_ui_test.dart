import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/reading/levels.dart';
import 'package:kodigno/reading/reading_controller.dart';
import 'package:kodigno/reading/reading_repository.dart';
import 'package:kodigno/reading/story_engine.dart';
import 'package:kodigno/ui/kulay.dart';
import 'package:kodigno/ui/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'story_engine_test.dart' show ScriptedRuntime;

/// A KulayScreen over an in-memory database and a model that is not running.
Future<(ReadingController, AppDatabase)> pumpKulay(WidgetTester t, {VoidCallback? onBack}) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1400, 900);
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({});
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final c = ReadingController(
    repo: ReadingRepository(db),
    engine: StoryEngine(() async => ScriptedRuntime((_, _) => throw ModelUnavailableException('test'))),
    prefs: await SharedPreferences.getInstance(),
  );
  await c.open();
  await t.pumpWidget(ChangeNotifierProvider.value(
    value: c,
    child: MaterialApp(theme: kTheme(), home: KulayScreen(onBack: onBack ?? () {})),
  ));
  await t.pump(const Duration(seconds: 2));
  return (c, db);
}

/// Frame by frame, so switch and slide animations actually run.
Future<void> frames(WidgetTester t, [int ms = 700]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('Kulay screen goes back to Kodigno', (t) async {
    var back = 0;
    await pumpKulay(t, onBack: () => back++);
    expect(find.text('Kulay'), findsOneWidget);
    await t.tap(find.text('Back to Kodigno'));
    expect(back, 1);
    expect(t.takeException(), isNull);
  });

  testWidgets('a new reader starts the reading check; a wrong answer shows its proof sentence', (t) async {
    await pumpKulay(t);
    await t.tap(find.text('Just me'));
    await t.pump(const Duration(seconds: 2));
    await t.enterText(find.byType(TextField), 'Ana');
    await t.tap(find.text('Start reading check'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Step 1 of 2'), findsOneWidget);
    expect(find.text('The Red Kite'), findsOneWidget);
    final p = placement[0];
    expect(find.text(p.questions[0].question), findsNothing); // questions wait until the story is read

    // Done reading: confirm, and the story is gone while answering.
    await t.ensureVisible(find.text("I'm done reading"));
    await t.tap(find.text("I'm done reading"));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Go to questions'));
    await frames(t);
    expect(find.textContaining('Step 2 of 2'), findsOneWidget);
    expect(find.text('The Red Kite'), findsNothing);

    // Answer every question with a wrong choice, one at a time.
    for (final (i, q) in p.questions.indexed) {
      expect(find.text(q.question), findsOneWidget);
      await t.tap(find.text(q.choices[(q.answer + 1) % 4]));
      await frames(t);
      if (i < p.questions.length - 1) expect(find.text(q.question), findsNothing); // moved on by itself
    }
    await t.ensureVisible(find.text('Check my answers'));
    await t.tap(find.text('Check my answers'));
    await t.pump(const Duration(milliseconds: 500));
    await frames(t);
    expect(find.textContaining('Not quite. The answer is "Red"'), findsOneWidget);
    expect(find.text('The Red Kite'), findsOneWidget); // the story is back for review
    expect(find.text(p.sentences[p.questions[0].evidence]), findsOneWidget); // the proof, quoted
    expect(find.text('Your starting color is'), findsOneWidget);
    expect(find.text('Aqua'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('leaving and coming back while answering does not show the story again', (t) async {
    final (c, _) = await pumpKulay(t);
    await t.tap(find.text('Just me'));
    await t.pump(const Duration(seconds: 2));
    await t.enterText(find.byType(TextField), 'Bea');
    await t.tap(find.text('Start reading check'));
    await t.pump(const Duration(milliseconds: 500));
    await t.ensureVisible(find.text("I'm done reading"));
    await t.tap(find.text("I'm done reading"));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Go to questions'));
    await frames(t);

    // Leave Kulay entirely, then come back.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(ChangeNotifierProvider.value(
      value: c,
      child: MaterialApp(theme: kTheme(), home: KulayScreen(onBack: () {})),
    ));
    await t.pump(const Duration(seconds: 1));
    expect(find.textContaining('Step 2 of 2'), findsOneWidget);
    expect(find.text('The Red Kite'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('classroom teacher view is behind a PIN', (t) async {
    final (c, _) = await pumpKulay(t);
    await c.setMode(KulayMode.classroom);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Who is reading today?'), findsOneWidget);
    await t.tap(find.text('Teacher view'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Set a teacher PIN'), findsOneWidget);
    await t.enterText(find.byType(TextField).last, '4321');
    await t.tap(find.text('Open'));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Class progress'), findsOneWidget);
    expect(find.text('Reading skills'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
