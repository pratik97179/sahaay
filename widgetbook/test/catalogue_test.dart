import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_design/sahaay_design.dart';
import 'package:sahaay_widgetbook/catalogue/catalogue.dart';
import 'package:sahaay_widgetbook/catalogue/stage.dart';
import 'package:sahaay_widgetbook/reduced_motion_addon.dart';
import 'package:widgetbook/widgetbook.dart';

/// A smoke test: every use case builds, in light and dark, without
/// throwing. It is not a device or text-size matrix.
void main() {
  final paths = [
    for (final leaf in WidgetbookRoot(children: catalogue).leaves)
      if (leaf is WidgetbookUseCase) leaf.path,
  ];

  test('the catalogue has use cases', () {
    expect(paths, isNotEmpty);
  });

  for (final (name, theme) in [
    ('light', SahaayTheme.light()),
    ('dark', SahaayTheme.dark()),
  ]) {
    for (final path in paths) {
      testWidgets('$path builds in $name', (tester) async {
        await tester.pumpWidget(
          Widgetbook.material(
            initialRoute: '/?path=${Uri.encodeQueryComponent(path)}&preview',
            directories: catalogue,
            addons: [
              MaterialThemeAddon(
                themes: [WidgetbookTheme(name: name, data: theme)],
              ),
              ReducedMotionAddon(),
            ],
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        // The use case itself rendered, not Widgetbook's home page.
        expect(
          find.byType(Stage).evaluate().length +
              find.byType(Screen).evaluate().length,
          1,
        );
      });
    }
  }
}
