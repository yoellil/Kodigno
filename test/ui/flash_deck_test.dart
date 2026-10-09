import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/ui/flash_deck.dart';
import 'package:kodigno/ui/theme.dart';

const _cards = [
  Flashcard(front: 'F1', back: 'B1'),
  Flashcard(front: 'F2', back: 'B2'),
];

Future<void> _pump(WidgetTester t, {List<Flashcard> cards = _cards}) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1000, 900);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: kTheme(),
      home: Scaffold(body: FlashDeck(cards: cards)),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  group('swipeDirection', () {
    test('far drag left/right', () {
      expect(swipeDirection(dx: -200, velocity: 0), -1);
      expect(swipeDirection(dx: 200, velocity: 0), 1);
    });
    test('short slow drag does nothing', () {
      expect(swipeDirection(dx: 50, velocity: 0), 0);
      expect(swipeDirection(dx: -100, velocity: 0), 0);
    });
    test('short fast fling counts', () {
      expect(swipeDirection(dx: 30, velocity: 1000), 1);
      expect(swipeDirection(dx: -30, velocity: -1000), -1);
      expect(swipeDirection(dx: 0, velocity: -1000), -1);
    });
    test('drag one way, fling the other cancels', () {
      expect(swipeDirection(dx: 40, velocity: -900), 0);
    });
  });

  testWidgets('tap flips to the answer, tap again flips back', (t) async {
    await _pump(t);
    expect(find.text('F1'), findsOneWidget);
    await t.tap(find.text('F1'));
    await t.pumpAndSettle();
    expect(find.text('B1'), findsOneWidget);
    expect(find.text('F1'), findsNothing);
    await t.tap(find.text('B1'));
    await t.pumpAndSettle();
    expect(find.text('F1'), findsOneWidget);
  });

  testWidgets('Space flips; arrows move between cards and reset the flip', (
    t,
  ) async {
    await _pump(t);
    expect(find.text('1 / 2'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pumpAndSettle();
    expect(find.text('B1'), findsOneWidget);

    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('F2'), findsOneWidget); // new card starts on its front

    await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await t.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('F1'), findsOneWidget);
  });

  testWidgets('swipe left goes to the next card, swipe right goes back', (
    t,
  ) async {
    await _pump(t);
    await t.fling(find.text('F1'), const Offset(-500, 0), 2000);
    await t.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await t.fling(find.text('F2'), const Offset(500, 0), 2000);
    await t.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('swiping past the end snaps back and stays on the last card', (
    t,
  ) async {
    await _pump(t);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pumpAndSettle();
    await t.fling(find.text('F2'), const Offset(-500, 0), 2000);
    await t.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('F2'), findsOneWidget);
  });

  testWidgets(
    'next card rises toward the top slot while the top card is dragged away',
    (t) async {
      await _pump(
        t,
        cards: const [
          Flashcard(front: 'F1', back: 'B1'),
          Flashcard(front: 'F2', back: 'B2'),
          Flashcard(front: 'F3', back: 'B3'),
        ],
      );
      final rest = t.getRect(find.byKey(const ValueKey('under1')));
      final g = await t.startGesture(t.getCenter(find.text('F1')));
      await g.moveBy(const Offset(-30, 0)); // past the touch slop
      await g.moveBy(const Offset(-270, 0));
      await t.pump();
      final mid = t.getRect(find.byKey(const ValueKey('under1')));
      expect(mid.width, greaterThan(rest.width));
      expect(mid.top, lessThan(rest.top));
      await g.up();
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'the card that took the top slot continues where the stack card left off',
    (t) async {
      await _pump(
        t,
        cards: const [
          Flashcard(front: 'F1', back: 'B1'),
          Flashcard(front: 'F2', back: 'B2'),
          Flashcard(front: 'F3', back: 'B3'),
        ],
      );
      final g = await t.startGesture(t.getCenter(find.text('F1')));
      await g.moveBy(const Offset(-30, 0));
      await g.moveBy(const Offset(-670, 0));
      await t.pump();
      final risen = t.getRect(find.byKey(const ValueKey('under1')));
      await g.up();
      await t.pumpAndSettle();
      final top = t.getRect(find.byType(FlipCard));
      expect((top.top - risen.top).abs(), lessThan(1));
      expect((top.width - risen.width).abs(), lessThan(1));
    },
  );

  testWidgets('a single card has no stack and no crash', (t) async {
    await _pump(
      t,
      cards: const [Flashcard(front: 'only', back: 'one')],
    );
    expect(find.text('1 / 1'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pumpAndSettle();
    expect(find.text('only'), findsOneWidget);
  });

  testWidgets('a long answer shrinks to fit the card with no overflow', (t) async {
    final long = List.filled(14, 'each party agrees to provide something of value').join(', ');
    await _pump(t, cards: [Flashcard(front: 'Professionals and Employers', back: long)]);
    await t.tap(find.byType(FlashDeck));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(faceFontSize(long), lessThan(faceFontSize('Short')));
  });

  testWidgets('a numbered list answer keeps its lines', (t) async {
    await _pump(t, cards: const [Flashcard(front: 'Principles', back: '1. Be fair\n2. Be kind\n3. Be honest')]);
    await t.tap(find.byType(FlashDeck));
    await t.pumpAndSettle();
    expect(find.text('1. Be fair\n2. Be kind\n3. Be honest'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
