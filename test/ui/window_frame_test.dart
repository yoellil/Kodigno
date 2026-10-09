import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ui/window_frame.dart';

void main() {
  testWidgets('minimize, close and drag go to the native window; taps under the strip still work', (t) async {
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('kodigno/window'), (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('kodigno/window'), null));
    var tapped = 0;
    await t.pumpWidget(MaterialApp(
      builder: (context, child) => WindowFrame(child: child!),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 40, top: 6),
            child: TextButton(onPressed: () => tapped++, child: const Text('Under the strip')),
          ),
        ),
      ),
    ));

    await t.tap(find.text('Under the strip'));
    expect(tapped, 1);

    await t.tap(find.bySemanticsLabel('Minimize'));
    await t.tap(find.bySemanticsLabel('Close'));
    await t.dragFrom(const Offset(400, 14), const Offset(60, 0));
    expect(calls, ['minimize', 'close', 'startDrag']);
  }, semanticsEnabled: true);

  testWidgets('full screen: the button and F11 toggle it, and the button shows the state', (t) async {
    var on = false;
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('kodigno/window'), (call) async {
      calls.add(call.method);
      if (call.method == 'toggleFullscreen') return on = !on;
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('kodigno/window'), null));
    await t.pumpWidget(MaterialApp(
      builder: (context, child) => WindowFrame(child: child!),
      home: const Scaffold(body: SizedBox.expand()),
    ));

    await t.tap(find.bySemanticsLabel('Full screen'));
    await t.pump();
    expect(on, isTrue);
    expect(find.bySemanticsLabel('Exit full screen'), findsOneWidget);

    // No dragging a full-screen window.
    await t.dragFrom(const Offset(300, 14), const Offset(60, 0));
    expect(calls.where((m) => m == 'startDrag'), isEmpty);

    await t.sendKeyEvent(LogicalKeyboardKey.f11);
    await t.pump();
    expect(on, isFalse);
    expect(find.bySemanticsLabel('Full screen'), findsOneWidget);
  }, semanticsEnabled: true);
}
