/// Relative sizing rules (`docs/design-system.md` §12).
///
/// Components size themselves from the space available, the user's text
/// size and these ratios — not from fixed dimensions — so nothing overflows
/// or clips on any device at any text size.
abstract final class Sizing {
  /// The smallest comfortable touch target. Controls grow beyond it with
  /// text size; they never shrink below it unless the layout itself has
  /// less room (a 7-column calendar on a very narrow phone).
  static const double minTouchTarget = 48;

  /// An icon beside text is this many times the text's size, so icons grow
  /// with the user's text size.
  static const double iconToText = 1.25;

  /// A placeholder icon fills this share of the photo it stands in for.
  static const double placeholderShare = 0.3;

  /// Picker wheels show at most this many rows, and at least [minWheelRows]
  /// when space is short.
  static const int maxWheelRows = 5;
  static const int minWheelRows = 3;

  /// The most of the screen's height a picker wheel takes.
  static const double wheelScreenShare = 0.4;
}
