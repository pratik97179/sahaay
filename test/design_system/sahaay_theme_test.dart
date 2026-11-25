import 'package:flutter/material.dart';
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
}
