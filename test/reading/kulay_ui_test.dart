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
    expect(find.text('Reading check'), findsOneWidget);
    expect(find.text('The Red Kite'), findsOneWidget);

    // Answer every question with a wrong choice.
    final p = placement[0];
    for (final q in p.questions) {
      final choice = find.text(q.choices[(q.answer + 1) % 4]);
      await t.ensureVisible(choice);
      await t.tap(choice);
      await t.pump();
    }
    await t.ensureVisible(find.text('Check my answers'));
    await t.tap(find.text('Check my answers'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Not quite. The answer is "Red"'), findsOneWidget);
    expect(find.text(p.sentences[p.questions[0].evidence]), findsOneWidget); // the proof, quoted
    expect(find.text('Your starting color is'), findsOneWidget);
    expect(find.text('Aqua'), findsWidgets);
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
