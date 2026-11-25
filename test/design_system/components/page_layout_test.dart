import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/design_system/design_system.dart';

void main() {
  Finder titleInTopBar(String text) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(text));

  testWidgets('repeats the heading in the top bar once it scrolls away', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SahaayTheme.light(),
        home: PageLayout(
          heading: 'Paracetamol',
          children: [for (var i = 0; i < 40; i++) Text('Row $i')],
        ),
      ),
    );

    expect(titleInTopBar('Paracetamol'), findsNothing);
    expect(find.text('Paracetamol'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(titleInTopBar('Paracetamol'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(titleInTopBar('Paracetamol'), findsNothing);
  });
}
