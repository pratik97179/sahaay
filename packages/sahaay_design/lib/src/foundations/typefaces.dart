/// The bundled typefaces (`docs/design-system.md` §3).
abstract final class Typefaces {
  /// The package that bundles the font files, needed when an app resolves
  /// a font family declared by a package.
  static const package = 'sahaay_design';

  /// The rounded reading face, for small labels on paper. A variable font,
  /// so its weight is set with the `wght` axis.
  static const reading = 'Nunito';

  /// The single typeface: bold for titles, a gentle lowercase voice
  /// elsewhere. A variable font, set with the `wght` axis.
  static const figtree = 'Figtree';

  /// Handwriting, for what the person writes themselves. One regular
  /// weight, Latin only.
  static const handwriting = 'QEDavidReid';
}
