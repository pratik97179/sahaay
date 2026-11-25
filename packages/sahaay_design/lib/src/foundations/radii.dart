/// Corner radii (`docs/design-system.md` §7). Shapes built from these use
/// continuous (superellipse) corners.
abstract final class Radii {
  /// Cards and grouped areas.
  static const double card = 24;

  /// The take panel.
  static const double panel = 24;

  /// Editable fields.
  static const double field = 16;

  /// Medicine photos.
  static const double photo = 20;

  /// Dialogs.
  static const double dialog = 32;

  /// The top corners of bottom sheets.
  static const double sheet = 32;
}
