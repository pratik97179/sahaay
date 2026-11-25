/// The two bundled typefaces (`docs/design-system.md` §4).
abstract final class Typefaces {
  /// The package that bundles the font files, needed when an app resolves
  /// a font family declared by a package.
  static const package = 'sahaay_design';

  /// The identifying voice: bold, large and condensed. Weights 700 and 800.
  static const condensed = 'BarlowCondensed';

  /// The reading voice: softer, rounded and wider. A variable font, so its
  /// weight is set with the `wght` axis.
  static const reading = 'Nunito';
}
