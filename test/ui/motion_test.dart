import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ui/anim.dart';
import 'package:kodigno/ui/motion.dart';
import 'package:kodigno/ui/theme.dart';

void main() {
  testWidgets('CountUp rolls from 0 up to the value', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: CountUp(value: 90, suffix: '%', style: display(40))),
    ));
    expect(find.text('0%'), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('CountUp shows the final value at once with Reduce Motion', (t) async {
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: CountUp(value: 90, suffix: '%', style: display(40))),
      ),
    ));
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('enter() is a no-op with Reduce Motion (no animation widgets)', (t) async {
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (c) => const Text('hi').enter(c)),
      ),
    ));
    expect(find.text('hi'), findsOneWidget);
    // settles immediately: nothing is animating
    await t.pumpAndSettle(const Duration(milliseconds: 1));
  });

  testWidgets('enter() fades and rises the child in, then it settles', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(builder: (c) => const Text('hi').enter(c, index: 2)),
    ));
    await t.pumpAndSettle();
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('Confetti plays once and finishes', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: Confetti())));
    await t.pump(const Duration(milliseconds: 500));
    await t.pumpAndSettle(); // would hang if it looped forever
  });
}
