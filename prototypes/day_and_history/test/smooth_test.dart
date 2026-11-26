import 'package:day_and_history_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every card's position and opacity, by day.
Map<Object, (Rect, double)> snapshot(WidgetTester tester) {
  final out = <Object, (Rect, double)>{};
  for (final e in find.byWidgetPredicate((w) => w is Positioned && w.key is ValueKey<int>).evaluate()) {
    final w = e.widget as Positioned;
    final op = (e.findAncestorWidgetOfExactType<Opacity>() == null)
        ? tester.widget<Opacity>(find.descendant(of: find.byWidget(w), matching: find.byType(Opacity)).first).opacity
        : 1.0;
    out[(w.key! as ValueKey<int>).value] = (Rect.fromLTWH(w.left!, w.top!, w.width!, w.height!), op);
  }
  return out;
}

void main() {
  for (final dx in [180.0, -180.0]) {
    testWidgets('a swipe ${dx > 0 ? 'right' : 'left'} has no sudden jumps', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: HistoryPage()));
      await tester.pumpAndSettle();

      final g = await tester.startGesture(const Offset(195, 420));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(Offset(dx / 12, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      var prev = snapshot(tester);
      var worstMove = 0.0, worstFade = 0.0;
      String where = '';
      for (var f = 0; f < 60; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        final now = snapshot(tester);
        for (final k in now.keys) {
          final a = prev[k], b = now[k]!;
          if (a == null) continue;
          final visible = a.$2 > 0.02 || b.$2 > 0.02;
          if (!visible) continue;
          final move = (a.$1.center - b.$1.center).distance;
          final fade = (a.$2 - b.$2).abs();
          if (move > worstMove) { worstMove = move; where = 'day $k frame $f move'; }
          if (fade > worstFade) { worstFade = fade; }
        }
        prev = now;
      }
      // ignore: avoid_print
      print('worst per-frame move ${worstMove.toStringAsFixed(1)} px ($where), worst fade ${worstFade.toStringAsFixed(2)}');
      expect(worstFade, lessThan(0.2), reason: 'a card popped in or out');
      expect(worstMove, lessThan(40), reason: 'a card jumped');
    });
  }
}
