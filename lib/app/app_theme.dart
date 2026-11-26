import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../design_system/design_system.dart' as legacy;

/// The app's themes: Sahaay's design system (`packages/sahaay_design`).
///
/// While screens move to the package one slice at a time
/// (`docs/design-system.md` §14.2, step 7), the old design system's theme
/// extensions ride along so screens that have not moved yet still find
/// their values. Remove them, and this note, with `lib/design_system/`.
abstract final class AppTheme {
  static ThemeData light() =>
      _withLegacy(SahaayTheme.light(), legacy.SahaayTheme.light());

  static ThemeData dark() =>
      _withLegacy(SahaayTheme.dark(), legacy.SahaayTheme.dark());

  static ThemeData _withLegacy(ThemeData theme, ThemeData old) =>
      theme.copyWith(
        extensions: [...old.extensions.values, ...theme.extensions.values],
      );
}
