import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ui/loaders.dart';

void main() {
  for (final art in LoaderArt.values) {
    testWidgets('${art.name} loader calls onDone once its bar fills', (tester) async {
      var done = 0;
      await tester.pumpWidget(MaterialApp(
        home: LoadingScreen(art: art, label: 'Opening', onDone: () => done++),
      ));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(done, 0);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(done, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Kulay tab plays the eye loader each time it is opened', (tester) async {
    final tab = ValueNotifier(0);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KulayPage(tab: tab, index: 2))));
    tab.value = 2;
    await tester.pump();
    expect(find.textContaining('Opening Kulay'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kulay'), findsOneWidget);

    tab.value = 0;
    tab.value = 2; // reopen
    await tester.pump();
    expect(find.textContaining('Opening Kulay'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
  });
}
