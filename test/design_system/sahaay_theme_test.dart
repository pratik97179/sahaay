import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/design_system/design_system.dart';

void main() {
  for (final (name, theme) in [
    ('light', SahaayTheme.light()),
    ('dark', SahaayTheme.dark()),
  ]) {
    test('$name theme provides every design-system extension', () {
      expect(theme.extension<SahaayTypography>(), isNotNull);
      expect(theme.extension<SahaayColors>(), isNotNull);
      expect(theme.extension<SahaaySpacing>(), isNotNull);
      expect(theme.extension<SahaayShapes>(), isNotNull);
    });
  }

  test(
    'light and dark resolve the same roles to different content colours',
    () {
      final light = SahaayTheme.light().extension<SahaayColors>()!;
      final dark = SahaayTheme.dark().extension<SahaayColors>()!;
      expect(light.contentPrimary, isNot(dark.contentPrimary));
    },
  );

  testWidgets('roles are reachable from BuildContext', (tester) async {
    late SahaayTypography typography;
    await tester.pumpWidget(
      MaterialApp(
        theme: SahaayTheme.light(),
        home: Builder(
          builder: (context) {
            typography = context.typography;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      typography.pageHeading.fontSize,
      greaterThan(typography.sectionHeading.fontSize!),
    );
  });

  for (final (name, theme) in [
    ('light', SahaayTheme.light()),
    ('dark', SahaayTheme.dark()),
  ]) {
    testWidgets('$name: a selected option is marked and keeps strong text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('One')),
                ButtonSegment(value: 2, label: Text('Two')),
              ],
              selected: const {1},
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      );

      final colors = theme.extension<SahaayColors>()!;
      Color? textColor(String label) =>
          DefaultTextStyle.of(tester.element(find.text(label))).style.color;

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(textColor('One'), colors.contentPrimary);
      expect(textColor('Two'), colors.contentPrimary);
    });
  }

  for (final (name, theme) in [
    ('light', SahaayTheme.light()),
    ('dark', SahaayTheme.dark()),
  ]) {
    testWidgets('$name: chip labels use full-strength text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Row(
              children: [
                ChoiceChip(
                  label: const Text('On'),
                  selected: true,
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Off'),
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      final colors = theme.extension<SahaayColors>()!;
      Color? renderedColor(String label) => tester
          .renderObject<RenderParagraph>(find.text(label))
          .text
          .style
          ?.color;

      expect(renderedColor('On'), colors.contentPrimary);
      expect(renderedColor('Off'), colors.contentPrimary);
    });
  }
}
