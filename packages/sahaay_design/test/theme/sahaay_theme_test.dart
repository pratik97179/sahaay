import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_design/sahaay_design.dart';

void main() {
  for (final (appearance, theme, tokens) in [
    ('light', SahaayTheme.light(), SahaayTokens.light),
    ('dark', SahaayTheme.dark(), SahaayTokens.dark),
  ]) {
    group('$appearance theme', () {
      test('carries the matching tokens', () {
        expect(theme.extension<SahaayTokens>(), same(tokens));
        expect(theme.brightness, tokens.brightness);
      });

      test('uses the page colour behind screens', () {
        expect(theme.scaffoldBackgroundColor, tokens.screen.background);
      });

      test('has no ripple: press feedback is a tint', () {
        expect(theme.splashFactory, NoSplash.splashFactory);
      });

      test('primary button colours come from the button tokens', () {
        final style = theme.filledButtonTheme.style!;
        expect(style.backgroundColor!.resolve({}), tokens.button.background);
        expect(
          style.backgroundColor!.resolve({WidgetState.pressed}),
          tokens.button.pressedBackground,
        );
        expect(
          style.backgroundColor!.resolve({WidgetState.disabled}),
          tokens.button.disabledBackground,
        );
        expect(style.minimumSize!.resolve({})!.height, tokens.button.minHeight);
      });

      test('switch track follows the switch row tokens', () {
        final track = theme.switchTheme.trackColor!;
        expect(track.resolve({WidgetState.selected}), tokens.switchRow.trackOn);
        expect(track.resolve({}), tokens.switchRow.trackOff);
      });

      test('a focused field shows the focus ring', () {
        final border =
            theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
        expect(border.borderSide.color, tokens.focus.ring);
      });
    });
  }

  testWidgets('switching light to dark animates without errors', (
    tester,
  ) async {
    Widget app(ThemeData theme) => MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => ColoredBox(
          key: const Key('page'),
          color: context.sahaay.screen.background,
          child: Text('Medicines', style: context.sahaay.screen.title),
        ),
      ),
    );

    await tester.pumpWidget(app(SahaayTheme.light()));
    await tester.pumpWidget(app(SahaayTheme.dark()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final box = tester.widget<ColoredBox>(find.byKey(const Key('page')));
    expect(box.color, SahaayTokens.dark.screen.background);
    expect(tester.takeException(), isNull);
  });
}
