import 'dart:io';

import 'package:day_and_history_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final l = FontLoader('Figtree')..addFont(File('assets/Figtree.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
    await l.load();
  });
  testWidgets('quick swipes in a row each move the card you see on top', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HistoryPage()));
    await tester.pumpAndSettle();
    expect(find.text('Nov 25'), findsWidgets);

    Future<void> flick(double dx) async {
      await tester.flingFrom(const Offset(195, 420), Offset(dx, 0), 900);
      await tester.pump(const Duration(milliseconds: 60)); // still flying
    }

    await flick(160);
    await flick(-160); // starts while the first card is still flying
    await flick(160);
    await tester.pumpAndSettle();

    // 25 → 23 → 22 → 21: three swipes, three cards to the bottom.
    final caption = tester.widgetList<Text>(find.textContaining('Nov ')).where((t) {
      final o = tester.element(find.byWidget(t)).findAncestorWidgetOfExactType<Opacity>();
      return o != null && o.opacity > 0.9;
    }).map((t) => t.data).toList();
    expect(caption, contains('Nov 21'));

  });
}
