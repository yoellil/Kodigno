import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/reading/levels.dart' show topics;
import 'package:kodigno/reading/reading_controller.dart';
import 'package:kodigno/reading/reading_repository.dart';
import 'package:kodigno/reading/story_engine.dart';
import 'package:kodigno/reading/ui/book3d.dart';
import 'package:kodigno/ui/kulay.dart';
import 'package:kodigno/ui/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A model that never answers, so the story stays "being written".
class _Hang implements LlmRuntime {
  final never = Completer<String>();
  @override
  Future<String> chat(List<Map<String, String>> messages,
          {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) =>
      never.future;
  @override
  Future<String> complete(String prompt, {int maxTokens = 1024, Map<String, Object?>? schema}) => never.future;
  @override
  Future<void> dispose() async {}
}

void main() {
  for (final typed in [false, true]) {
    testWidgets('writing a new story shows the opening-book loader (${typed ? 'typed topic' : 'shelf book'})', (t) async {
      t.view.devicePixelRatio = 1.0;
      t.view.physicalSize = const Size(1400, 900);
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final c = ReadingController(
        repo: ReadingRepository(db),
        engine: StoryEngine(() async => _Hang()),
        prefs: await SharedPreferences.getInstance(),
      );
      await c.open();
      await c.addReader('Ana');
      await c.repo.setLevel(c.reader!.id, 1);
      await c.pickReader(c.reader!);
      await t.pumpWidget(ChangeNotifierProvider.value(
        value: c,
        child: MaterialApp(theme: kTheme(), home: KulayScreen(onBack: () {})),
      ));
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(BookShelf), findsOneWidget);

      if (typed) {
        await t.scrollUntilVisible(find.byType(TextField), 300, scrollable: find.byType(Scrollable).first);
        await t.enterText(find.byType(TextField), 'my pet cat');
        await t.tap(find.text('Write my story'));
      } else {
        final book = find.widgetWithText(BookSpine, topics[4]);
        await t.scrollUntilVisible(book, 300, scrollable: find.byType(Scrollable).first);
        await t.tap(book);
      }
      for (var i = 0; i < 60; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(c.screen, KulayScreenId.writing);
      expect(find.byType(OpeningBookLoader), findsOneWidget);
      expect(find.textContaining('Step '), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  }
}
