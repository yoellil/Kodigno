import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ui/app_shell.dart';
import 'package:kodigno/ui/kulay.dart';
import 'package:kodigno/ui/theme.dart';

void main() {
  testWidgets('Kulay in the rail bursts, opens Kulay while covered, then clears', (t) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(1200, 800);
    addTearDown(t.view.reset);
    var opened = 0;
    await t.pumpWidget(MaterialApp(
      theme: kTheme(),
      home: AppShell(
        tab: ValueNotifier(0),
        onKulay: () => opened++,
        pages: const [Text('a'), Text('b'), Text('c')],
      ),
    ));
    await t.tap(find.text('Kulay'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(opened, 0); // still covering
    await t.pump(const Duration(milliseconds: 500));
    expect(opened, 1);
    await t.pump(const Duration(milliseconds: 1000)); // shatter away, overlay removed
    expect(t.takeException(), isNull);
  });

  testWidgets('Kulay screen goes back to Kodigno', (t) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(1200, 800);
    addTearDown(t.view.reset);
    var back = 0;
    await t.pumpWidget(MaterialApp(home: KulayScreen(onBack: () => back++)));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Kulay'), findsOneWidget);
    await t.tap(find.text('Back to Kodigno'));
    expect(back, 1);
    expect(t.takeException(), isNull);
  });
}
