import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_design/src/foundations/palette.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// Text pairs the design system actually uses (`docs/design-system.md` §5.3).
/// Sage is never used as text on the raised panel, so that pair is absent.
List<(String, Color, Color)> textPairs(Palette p) => [
  for (final (name, surface) in [
    ('page', p.page),
    ('card', p.card),
    ('raised', p.raised),
  ]) ...[
    ('text on $name', p.text, surface),
    ('textSoft on $name', p.textSoft, surface),
    ('danger on $name', p.danger, surface),
  ],
  ('action on page', p.action, p.page),
  ('action on card', p.action, p.card),
  ('onAction on action', p.onAction, p.action),
];

void main() {
  for (final (appearance, palette) in [
    ('light', Palette.light),
    ('dark', Palette.dark),
  ]) {
    group('$appearance palette meets WCAG AA for text', () {
      for (final (name, foreground, background) in textPairs(palette)) {
        test(name, () {
          expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
        });
      }
    });
  }
}
