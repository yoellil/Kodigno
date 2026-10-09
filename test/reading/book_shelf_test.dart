import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/reading/levels.dart';
import 'package:kodigno/reading/ui/book3d.dart';

void main() {
  Future<void> pumpShelf(WidgetTester t, void Function(String) onOpen) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(1000, 800);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(width: 820, child: BookShelf(topics: topics, onOpen: onOpen))),
    ));
  }

  testWidgets('hovering other books never moves the last book', (t) async {
    await pumpShelf(t, (_) {});
    final last = find.widgetWithText(BookSpine, topics.last);
    final rest = t.getTopLeft(last);
    final g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: Offset.zero);
    for (final topic in [topics[2], topics[5], topics[1], topics[8], topics[3]]) {
      await g.moveTo(t.getCenter(find.widgetWithText(BookSpine, topic)));
      for (var f = 0; f < 8; f++) {
        await t.pump(const Duration(milliseconds: 40));
        expect(t.getTopLeft(last), rest, reason: 'while hovering $topic');
      }
    }
    // The hovered book itself did lift.
    final hovered = find.widgetWithText(BookSpine, topics[3]);
    expect(t.getTopLeft(hovered).dy, lessThan(t.getTopLeft(last).dy + 200));
    await g.removePointer();
  });

  testWidgets('clicking a book flies it open, then opens the topic once', (t) async {
    final opened = <String>[];
    await pumpShelf(t, opened.add);
    await t.tap(find.widgetWithText(BookSpine, topics[4]));
    for (var f = 0; f < 50; f++) {
      await t.pump(const Duration(milliseconds: 40));
    }
    expect(opened, [topics[4]]);
    expect(t.takeException(), isNull);
  });
}
