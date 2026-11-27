import 'package:flutter/painting.dart';

import '../foundations/typefaces.dart';

/// The colours of every screen: one warm off-white paper with warm ink
/// (`docs/design-system.md` §3). They do not change with the time of
/// day. Never a health or status colour.
final class DayLight {
  const DayLight._(this.page, this.ink, this.soft);

  /// The one set every screen uses.
  static const screen = DayLight._(
    Color(0xFFF4F1EA),
    Color(0xFF1F1C18),
    Color(0xFF6E6862),
  );

  /// The screen's colour.
  final Color page;

  /// Main text and marks.
  final Color ink;

  /// Quieter text and marks.
  final Color soft;
}

/// Figtree at [size] and [weight] in [color]: the app's text style.
/// Sizes are at 100% text size; the platform's text scaling applies on top.
TextStyle figtree(
  double size,
  FontWeight weight,
  Color color, {
  double height = 1.2,
  double letterSpacing = 0,
}) => TextStyle(
  fontFamily: Typefaces.figtree,
  package: Typefaces.package,
  fontSize: size,
  fontWeight: weight,
  fontVariations: [FontVariation('wght', weight.value.toDouble())],
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

/// Handwriting, for what the person writes themselves, such as a note.
TextStyle handwritten(double size, Color color, {double height = 1.25}) =>
    TextStyle(
      fontFamily: Typefaces.handwriting,
      package: Typefaces.package,
      fontSize: size,
      color: color,
      height: height,
      // Set, not inherited: a text field would otherwise take the theme's
      // letter spacing and the writing would widen.
      letterSpacing: 0,
    );

/// The rounded reading face (Nunito), for small labels that sit on paper,
/// such as the line at the top of a note.
TextStyle rounded(double size, FontWeight weight, Color color) => TextStyle(
  fontFamily: Typefaces.reading,
  package: Typefaces.package,
  fontSize: size,
  fontWeight: weight,
  fontVariations: [FontVariation('wght', weight.value.toDouble())],
  color: color,
  letterSpacing: 0,
);
