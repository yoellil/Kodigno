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
}
