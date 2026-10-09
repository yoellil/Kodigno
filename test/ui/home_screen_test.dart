import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ui/home_screen.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, {required VoidCallback onOpen}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(onOpen: onOpen)));
    await tester.pump(const Duration(seconds: 3)); // intro
  }

  testWidgets('clicking the brain blooms color, then opens Kodigno once', (tester) async {
    var opened = 0;
    await pumpHome(tester, onOpen: () => opened++);
    expect(find.text('Kodigno'), findsOneWidget);

    await tester.tapAt(const Offset(640, 340));
    await tester.tapAt(const Offset(600, 360)); // second click is ignored
    await tester.pump(const Duration(milliseconds: 600));
    expect(opened, 0); // still blooming
    await tester.pump(const Duration(milliseconds: 700));
    expect(opened, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); // stop the ticker
  });

  testWidgets('brain reacts to hover without errors', (tester) async {
    await pumpHome(tester, onOpen: () {});
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(600, 300));
    await gesture.moveTo(const Offset(700, 400));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    await gesture.removePointer();
    await tester.pumpWidget(const SizedBox());
  });
}
