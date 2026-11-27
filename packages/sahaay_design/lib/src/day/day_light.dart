import 'package:flutter/painting.dart';

import '../foundations/typefaces.dart';

/// The colour of the day at one hour, for the ruler screen only
/// (`docs/design-system.md` §18.3): peach in the morning, light in the
/// afternoon, lilac in the evening, deep blue at night. Never a health or
/// status colour.
///
/// Values are provisional, from the first Today design; contrast checks
/// are still open (§18.6).
final class DayLight {
  const DayLight._(this.page, this.ink, this.soft);

  /// The colour of the day at [hour] (0–24, fractions allowed), blended
  /// smoothly between the stops.
  factory DayLight.at(double hour) {
    final h = hour.clamp(0.0, 24.0);
    var page = _stops.last.$2;
    for (var i = 0; i < _stops.length - 1; i++) {
      final (a, ca) = _stops[i];
      final (b, cb) = _stops[i + 1];
      if (h >= a && h <= b) {
        page = Color.lerp(ca, cb, (h - a) / (b - a))!;
        break;
      }
    }
    final dark = page.computeLuminance() < 0.2;
    return DayLight._(
      page,
      dark ? const Color(0xFFF4F2EE) : const Color(0xFF141414),
      dark ? const Color(0xFFB4B3C4) : const Color(0xFF5F6166),
    );
  }

  /// The one colour every day screen uses for now: the 1 pm light. The
  /// colour that follows the hour is on hold (§18.3).
  static final screen = DayLight.at(13);

  static const _stops = <(double, Color)>[
    (0, Color(0xFF101327)),
    (5.5, Color(0xFF1B1F3D)),
    (7.5, Color(0xFFF6E3D3)),
    (12, Color(0xFFEEF1F0)),
    (17, Color(0xFFF1EBE4)),
    (19.5, Color(0xFFE7DEEC)),
    (21, Color(0xFF1B1F3D)),
    (24, Color(0xFF101327)),
  ];

  /// The screen's colour.
  final Color page;

  /// Main text and marks.
  final Color ink;

  /// Quieter text and marks.
  final Color soft;

  /// The same page with other ink, for a screen with its own text colours.
  DayLight withInk({required Color ink, required Color soft}) =>
      DayLight._(page, ink, soft);

  /// Whether the page is dark, so system chrome can match it.
  bool get isDark => page.computeLuminance() < 0.2;
}

/// Figtree at [size] and [weight] in [color]: the makeover's text style.
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
