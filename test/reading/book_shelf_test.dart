import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/reading/levels.dart';
import 'package:kodigno/reading/ui/book3d.dart';
import 'package:kodigno/reading/ui/book_carousel.dart';

void main() {
  Future<void> pumpRing(WidgetTester t, void Function(String) onOpen) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(1000, 800);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(width: 820, child: BookCarousel(topics: topics, onOpen: onOpen))),
    ));
  }

  Future<void> frames(WidgetTester t, int n) async {
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 40));
    }
  }

  String frontTitle(WidgetTester t) {
    // The caption names the front book.
    final caption = find.descendant(of: find.byType(AnimatedSwitcher), matching: find.byType(Text)).first;
    return (t.widget<Text>(caption)).data!;
  }

  testWidgets('the ring revolves by itself, all the way round', (t) async {
    await pumpRing(t, (_) {});
    final seen = <String>{frontTitle(t)};
    // About 40 s at the idle speed covers a full turn.
    for (var i = 0; i < 1000; i++) {
      await t.pump(const Duration(milliseconds: 40));
      seen.add(frontTitle(t));
    }
    expect(seen.length, topics.length);
    expect(t.takeException(), isNull);
  });

  testWidgets('pointing settles it; the arrows step one book', (t) async {
    await pumpRing(t, (_) {});
    final g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: const Offset(10, 10));
    await g.moveTo(const Offset(410, 150)); // over the ring
    await frames(t, 30);
    final settled = frontTitle(t);
    await frames(t, 30);
    expect(frontTitle(t), settled); // stays put while pointed at

    final i = topics.indexOf(settled);
    await t.tap(find.bySemanticsLabel('Next book'));
    await frames(t, 40);
    expect(frontTitle(t), topics[(i + 1) % topics.length]);
    await g.removePointer();
  }, semanticsEnabled: true);

  testWidgets('clicking the front book flies it open once', (t) async {
    final opened = <String>[];
    await pumpRing(t, opened.add);
    final g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: const Offset(410, 150));
    await frames(t, 40);
    final front = frontTitle(t);
    await t.tap(find.widgetWithText(BookCoverFace, front));
    await frames(t, 50);
    expect(opened, [front]);
    expect(t.takeException(), isNull);
    await g.removePointer();
  });
}
