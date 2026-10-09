import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ui/app_shell.dart';
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
  // 'Kulay screen goes back to Kodigno' moved to test/reading/kulay_ui_test.dart: KulayScreen now needs a ReadingController.
}
