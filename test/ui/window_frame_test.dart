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
}
