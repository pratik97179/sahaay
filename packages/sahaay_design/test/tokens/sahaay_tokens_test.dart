import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_design/sahaay_design.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// Every text style a component draws, with the surface it is drawn on.
List<(String, TextStyle, Color)> textOnSurface(SahaayTokens t) => [
  ('screen.title', t.screen.title, t.screen.background),
  ('screen.subtitle', t.screen.subtitle, t.screen.background),
  ('section.title', t.section.title, t.screen.background),
  ('photoTile.name', t.photoTile.name, t.screen.background),
  ('photoTile.detail', t.photoTile.detail, t.screen.background),
  ('timeCard.time', t.timeCard.time, t.timeCard.background),
  ('timeCard.schedule', t.timeCard.schedule, t.timeCard.background),
  ('timeCard.note', t.timeCard.note, t.timeCard.background),
  ('takePanel.name', t.takePanel.name, t.takePanel.background),
  ('takePanel.instruction', t.takePanel.instruction, t.takePanel.background),
  ('field.label', t.field.label, t.screen.background),
  ('field.value', t.field.value, t.field.background),
  ('field.placeholder', t.field.placeholder, t.field.background),
  ('field.errorText', t.field.errorText, t.screen.background),
  ('button.label', t.button.label, t.button.background),
  ('row.label', t.row.label, t.row.background),
  ('switchRow.stateNote', t.switchRow.stateNote, t.row.background),
  ('dangerRow.label', t.dangerRow.label, t.row.background),
  ('tag.label', t.tag.label, t.tag.background),
  ('dialog.title', t.dialog.title, t.dialog.background),
  ('dialog.message', t.dialog.message, t.dialog.background),
  ('dialog.confirmLabel', t.dialog.confirmLabel, t.dialog.confirmBackground),
  (
    'dialog.confirmLabel pressed',
    t.dialog.confirmLabel,
    t.dialog.confirmPressedBackground,
  ),
  ('snackbar.message', t.snackbar.message, t.snackbar.background),
  ('emptyState.message', t.emptyState.message, t.screen.background),
  ('errorState.message', t.errorState.message, t.screen.background),
];

/// Text roles allowed to use the condensed (identifying) face.
const condensedRoles = {
  'screen.title',
  'section.title',
  'photoTile.name',
  'timeCard.time',
  'takePanel.name',
  'dialog.title',
};

void main() {
  for (final (appearance, tokens) in [
    ('light', SahaayTokens.light),
    ('dark', SahaayTokens.dark),
  ]) {
    group('$appearance tokens', () {
      for (final (name, style, surface) in textOnSurface(tokens)) {
        test('$name meets WCAG AA on its surface', () {
          expect(contrast(style.color!, surface), greaterThanOrEqualTo(4.5));
        });

        test('$name is at least 15 points', () {
          expect(style.fontSize, greaterThanOrEqualTo(15));
        });

        test('$name uses the right voice', () {
          final condensed = style.fontFamily!.endsWith('BarlowCondensed');
          expect(condensed, condensedRoles.contains(name));
        });
      }

      test('reading styles set the variable weight axis', () {
        for (final (name, style, _) in textOnSurface(tokens)) {
          if (condensedRoles.contains(name)) continue;
          expect(style.fontVariations, [
            FontVariation.weight(style.fontWeight!.value.toDouble()),
          ], reason: name);
        }
      });

      test('touch targets are at least 48 points', () {
        expect(tokens.button.minHeight, greaterThanOrEqualTo(48));
        expect(tokens.row.minHeight, greaterThanOrEqualTo(48));
      });
    });
  }

  test('only light appearance casts shadows', () {
    expect(SahaayTokens.light.sheet.shadow, isNotEmpty);
    expect(SahaayTokens.dark.sheet.shadow, isEmpty);
  });

  group('accessibility settings', () {
    final tokens = SahaayTokens.light;

    test('no settings leave the tokens unchanged', () {
      expect(
        tokens.resolve(reduceMotion: false, highContrast: false),
        same(tokens),
      );
    });

    test('reduced motion: no movement, short cross-fades, no spring', () {
      final r = tokens.resolve(reduceMotion: true, highContrast: false);
      expect(r.motion.reduced, isTrue);
      expect(r.motion.press.duration, Duration.zero);
      expect(r.motion.expand.duration, Duration.zero);
      expect(
        r.motion.appear.duration,
        lessThanOrEqualTo(const Duration(milliseconds: 150)),
      );
      expect(r.sheet.spring, isNull);
      expect(r.topBar.frost, isNotNull);
    });

    test('high contrast: the top bar is solid', () {
      final r = tokens.resolve(reduceMotion: false, highContrast: true);
      expect(r.topBar.frost, isNull);
      expect(r.motion.reduced, isFalse);
    });
  });

  test('lerp reaches each appearance at its ends', () {
    final light = SahaayTokens.light;
    final dark = SahaayTokens.dark;
    expect(light.lerp(dark, 0).screen.background, light.screen.background);
    expect(light.lerp(dark, 1).screen.background, dark.screen.background);
    expect(light.lerp(dark, 1).brightness, Brightness.dark);
  });

  testWidgets('context.sahaay reads the theme and the user settings', (
    tester,
  ) async {
    late SahaayTokens seen;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true, highContrast: true),
        child: Theme(
          data: ThemeData(extensions: [SahaayTokens.dark]),
          child: Builder(
            builder: (context) {
              seen = context.sahaay;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(seen.brightness, Brightness.dark);
    expect(seen.motion.reduced, isTrue);
    expect(seen.topBar.frost, isNull);
  });
}
