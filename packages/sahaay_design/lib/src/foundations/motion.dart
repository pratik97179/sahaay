import 'package:flutter/animation.dart';

/// Durations, curves and the sheet spring (`docs/design-system.md` §9).
abstract final class Motion {
  /// Press feedback: a tint change.
  static const press = Duration(milliseconds: 100);

  /// Content appearing.
  static const appear = Duration(milliseconds: 200);

  /// Content leaving; faster than it arrived.
  static const disappear = Duration(milliseconds: 150);

  /// Content opening or closing.
  static const expand = Duration(milliseconds: 250);

  /// Gentle ease-out for press feedback and expanding.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Strong ease-out for appearing content.
  static const Curve easeOutStrong = Cubic(0.23, 1, 0.32, 1);

  /// Ease-in for leaving content.
  static const Curve easeIn = Curves.easeInCubic;

  /// Sheets and dialogs: critically damped, so they settle without bouncing.
  static final SpringDescription sheetSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 400);
}
