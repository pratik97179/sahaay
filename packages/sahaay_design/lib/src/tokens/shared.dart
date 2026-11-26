import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';

import '../foundations/palette.dart';
import '../foundations/radii.dart';
import '../foundations/typefaces.dart';

/// The shared values of §4–§8, resolved for one appearance.
///
/// Private: component tokens point to these so that components which
/// should match cannot drift apart. Features never see this class.
final class Shared {
  Shared(this.palette);

  final Palette palette;

  // Text styles (§4.1). Condensed styles: tight leading (1.1), warm
  // off-black. Reading styles: generous leading (1.5).

  late final TextStyle screenTitle = _condensed(48, FontWeight.w800);
  late final TextStyle sectionTitle = _condensed(28, FontWeight.w700);
  late final TextStyle itemTitle = _condensed(24, FontWeight.w700);
  late final TextStyle time = _condensed(34, FontWeight.w700);
  late final TextStyle body = _reading(18, 500, palette.text);
  late final TextStyle bodyStrong = _reading(18, 700, palette.text);
  late final TextStyle note = _reading(16, 400, palette.textSoft);
  late final TextStyle label = _reading(16, 600, palette.textSoft);
  late final TextStyle detail = _reading(15, 400, palette.textSoft);
  late final TextStyle button = _reading(17, 700, palette.text);
  late final TextStyle tag = _reading(15, 700, palette.text);

  // Shapes (§7): continuous corners everywhere.

  late final OutlinedBorder card = _rounded(Radii.card);
  late final OutlinedBorder panel = _rounded(Radii.panel);
  late final OutlinedBorder field = _rounded(Radii.field);
  late final OutlinedBorder photo = _rounded(Radii.photo);
  late final OutlinedBorder dialog = _rounded(Radii.dialog);
  late final OutlinedBorder sheet = const RoundedSuperellipseBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
  );
  static const OutlinedBorder pill = StadiumBorder();

  // Depth (§8).

  /// The one soft, wide, warm shadow under floating things. Empty in dark
  /// appearance, where floating things use the raised surface instead.
  late final List<BoxShadow> floatingShadow =
      palette.brightness == Brightness.light
      ? [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ]
      : const [];

  /// The surface of floating things: the page in light (lifted by the
  /// shadow), the raised surface in dark.
  late final Color floatingSurface = palette.brightness == Brightness.light
      ? palette.page
      : palette.raised;

  TextStyle _condensed(double size, FontWeight weight) => TextStyle(
    fontFamily: Typefaces.condensed,
    package: Typefaces.package,
    fontSize: size,
    fontWeight: weight,
    height: 1.1,
    color: palette.text,
  );

  // Nunito is a variable font: `FontWeight` alone does not move its weight
  // axis, so the `wght` variation is set as well.
  TextStyle _reading(double size, double weight, Color color) => TextStyle(
    fontFamily: Typefaces.reading,
    package: Typefaces.package,
    fontSize: size,
    fontWeight: FontWeight.values.firstWhere((w) => w.value == weight),
    fontVariations: [FontVariation.weight(weight)],
    height: 1.5,
    color: color,
  );

  static OutlinedBorder _rounded(double radius) => RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
  );
}
