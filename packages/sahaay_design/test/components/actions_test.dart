import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_design/sahaay_design.dart';

Future<void> pumpHost(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? SahaayTheme.light(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
}

Color rowColor(WidgetTester tester, Finder row) => tester
    .widget<AnimatedContainer>(
      find.descendant(of: row, matching: find.byType(AnimatedContainer)),
    )
    .decoration
    .let((d) => (d! as BoxDecoration).color!);

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

void main() {
  final tokens = SahaayTokens.light;

  group('PrimaryButton', () {
    testWidgets('fills the width and is at least the button height', (
      tester,
    ) async {
      var taps = 0;
      await pumpHost(
        tester,
        PrimaryButton(label: 'Save reminder', onPressed: () => taps++),
      );
      final size = tester.getSize(find.byType(FilledButton));
      expect(size.width, 390 - 48);
      expect(size.height, greaterThanOrEqualTo(tokens.button.minHeight));
      await tester.tap(find.text('Save reminder'));
      expect(taps, 1);
    });

    testWidgets('can be disabled', (tester) async {
      await pumpHost(
        tester,
        const PrimaryButton(label: 'Save reminder', onPressed: null),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('ActionRow', () {
    testWidgets('is a 56pt button that deepens its tint while pressed', (
      tester,
    ) async {
      var taps = 0;
      await pumpHost(
        tester,
        ActionGroup(
          children: [
            ActionRow(
              icon: Icons.edit_outlined,
              label: 'Edit reminder',
              onTap: () => taps++,
            ),
          ],
        ),
      );
      final row = find.byType(ActionRow);
      expect(
        tester.getSize(row).height,
        greaterThanOrEqualTo(tokens.row.minHeight),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(rowColor(tester, row), tokens.row.background);

      final gesture = await tester.startGesture(tester.getCenter(row));
      await tester.pumpAndSettle();
      expect(rowColor(tester, row), tokens.row.pressedBackground);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);

      final semantics = tester.getSemantics(row);
      expect(semantics.label, 'Edit reminder');
      expect(semantics.flagsCollection.isButton, isTrue);
    });
  });

  group('SwitchRow', () {
    Widget notifyMe(bool value, ValueChanged<bool> onChanged) => SwitchRow(
      label: 'Notify me',
      value: value,
      onChanged: onChanged,
      offNote: "Paused — won't notify until you turn it back on",
    );

    testWidgets('tapping the row toggles it', (tester) async {
      bool? changed;
      await pumpHost(tester, notifyMe(true, (v) => changed = v));
      await tester.tap(find.text('Notify me'));
      expect(changed, isFalse);
    });

    testWidgets('when off, says so in words', (tester) async {
      await pumpHost(tester, notifyMe(false, (_) {}));
      await tester.pumpAndSettle();
      expect(
        find.text("Paused — won't notify until you turn it back on"),
        findsOneWidget,
      );
      final semantics = tester.getSemantics(find.byType(SwitchRow));
      expect(semantics.label, 'Notify me');
      expect(semantics.hint, contains('Paused'));
    });

    testWidgets('when on, the note is gone', (tester) async {
      await pumpHost(tester, notifyMe(true, (_) {}));
      await tester.pumpAndSettle();
      expect(find.textContaining('Paused'), findsNothing);
    });
  });

  group('DangerRow', () {
    testWidgets('is brick, and sits in its own group', (tester) async {
      await pumpHost(
        tester,
        Column(
          children: [
            ActionGroup(
              children: [
                ActionRow(
                  icon: Icons.edit_outlined,
                  label: 'Edit reminder',
                  onTap: () {},
                ),
              ],
            ),
            ActionGroup(
              children: [
                DangerRow(
                  icon: Icons.delete_outline,
                  label: 'Delete reminder',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      );
      final label = tester.widget<Text>(find.text('Delete reminder'));
      expect(label.style!.color, tokens.dangerRow.label.color);

      final editBottom = tester.getBottomLeft(find.byType(ActionRow)).dy;
      final deleteTop = tester.getTopLeft(find.byType(DangerRow)).dy;
      expect(deleteTop - editBottom, tokens.row.groupGap);
    });
  });

  for (final dark in [false, true]) {
    testWidgets(
      'rows fit 200% text on a small phone (${dark ? 'dark' : 'light'})',
      (tester) async {
        await pumpHost(
          tester,
          ActionGroup(
            children: [
              ActionRow(
                icon: Icons.edit_outlined,
                label: 'Edit this reminder and its schedule',
                onTap: () {},
              ),
              SwitchRow(
                label: 'Notify me',
                value: false,
                onChanged: (_) {},
                offNote: "Paused — won't notify until you turn it back on",
              ),
              DangerRow(
                icon: Icons.delete_outline,
                label: 'Delete this reminder',
                onTap: () {},
              ),
            ],
          ),
          theme: dark ? SahaayTheme.dark() : null,
          textScale: 2,
          size: const Size(320, 640),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
