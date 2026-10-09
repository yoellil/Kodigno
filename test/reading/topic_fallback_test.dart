import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/data/database.dart';
import 'package:kodigno/reading/levels.dart';
import 'package:kodigno/reading/reading_controller.dart';
import 'package:kodigno/reading/reading_repository.dart';
import 'package:kodigno/reading/story_engine.dart';
import 'package:kodigno/reading/ui/book_carousel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'story_engine_test.dart' show ScriptedRuntime;

/// A Lime reader with the starter stories, and a model that always fails.
Future<(ReadingController, AppDatabase)> limeReader(Object failure) async {
  SharedPreferences.setMockInitialValues({});
  final db = AppDatabase(NativeDatabase.memory());
  final c = ReadingController(
    repo: ReadingRepository(db),
    engine: StoryEngine(() async => ScriptedRuntime((_, _) => throw failure)),
    prefs: await SharedPreferences.getInstance(),
  );
  await c.open(starters: File('assets/kulay/starter_stories.json').readAsStringSync());
  await c.setMode(KulayMode.personal);
  await c.addReader('Friend');
  await c.setReaderLevel(c.reader!.id, 1); // Lime
  await c.pickReader(c.reader!);
  return (c, db);
}

void main() {
  testWidgets('every book in the ring opens its own topic', (t) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(1000, 800);
    addTearDown(t.view.reset);
    final opened = <String>[];
    await t.pumpWidget(MaterialApp(
        home: Scaffold(body: SizedBox(width: 820, child: BookCarousel(topics: topics, onOpen: opened.add)))));
    String front() =>
        t.widget<Text>(find.descendant(of: find.byType(AnimatedSwitcher), matching: find.byType(Text)).first).data!;
    for (final topic in topics) {
      for (var k = 0; k < topics.length && front() != topic; k++) {
        await t.tap(find.bySemanticsLabel('Next book'));
        for (var f = 0; f < 25; f++) {
          await t.pump(const Duration(milliseconds: 40));
        }
      }
      await t.tap(find.text(topic).first);
      for (var f = 0; f < 50; f++) {
        await t.pump(const Duration(milliseconds: 40));
      }
    }
    expect(opened, topics);
  }, semanticsEnabled: true);

  test('when the AI fails, no other topic is swapped in; a ready one is offered', () async {
    final (c, db) = await limeReader(StateError('model gave up'));
    addTearDown(db.close);
    for (final topic in topics) {
      await c.readTopic(topic);
      if (c.screen == KulayScreenId.story) {
        // A saved story on this very topic: fine, it is what was asked for.
        expect((c.passage! as Story).topic, topic);
      } else {
        expect(c.screen, KulayScreenId.writing, reason: topic);
        expect(c.error, contains(topic));
        expect(c.fallbackTopic, isNotNull);
        expect(c.fallbackTopic, isNot(topic));
      }
      await c.goHome();
    }

    // A typed topic has no saved story: the AI failing means a different
    // topic is offered, opens only when chosen, and says what it is.
    await c.readTopic('my pet cat');
    expect(c.screen, KulayScreenId.writing);
    expect(c.error, contains('my pet cat'));
    final offered = c.fallbackTopic!;
    await c.readFallback();
    expect(c.screen, KulayScreenId.story);
    expect((c.passage! as Story).topic, offered);
    expect(c.notice, contains('my pet cat'));
    expect(c.notice, contains(offered));
  });

  test('when the AI cannot start, it says so and points to Standard quality', () async {
    final (c, db) = await limeReader(ModelUnavailableException('out of memory'));
    addTearDown(db.close);
    await c.readTopic('my pet cat');
    expect(c.screen, KulayScreenId.writing);
    expect(c.error, contains('my pet cat'));
    expect(c.error, contains('Standard quality'));
    expect(c.fallbackTopic, isNotNull);
  });
}
