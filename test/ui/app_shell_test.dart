import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ui/app_shell.dart';
import 'package:kodigno/ui/theme.dart';

void main() {
  testWidgets('wide = sidebar, narrow = bottom bar, tab switches page', (t) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(1200, 800);
    addTearDown(t.view.reset);
    final tab = ValueNotifier(0);
    await t.pumpWidget(MaterialApp(
      theme: kTheme(),
      home: AppShell(
        tab: tab,
        pages: const [
          Text('page-library'),
          Text('page-create'),
          Text('page-kulay'),
          Text('page-settings'),
        ],
      ),
    ));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Library'), findsOneWidget); // sidebar entry
    expect(find.text('page-library'), findsOneWidget);

    await t.tap(find.text('Create'));
    await t.pump();
    expect(tab.value, 1);

    t.view.physicalSize = const Size(500, 800);
    await t.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
