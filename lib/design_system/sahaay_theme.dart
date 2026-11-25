import 'package:flutter/material.dart';

import 'sahaay_colors.dart';
import 'sahaay_layout.dart';
import 'sahaay_typography.dart';

/// Central theme configuration (`docs/design-system.md` §13).
///
/// The seed colour is a placeholder until visual values are agreed.
abstract final class SahaayTheme {
  static const Color _seed = Color(0xFF2E6B5E);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    const shapes = SahaayShapes();
    final colors = SahaayColors.from(scheme);
    final typography = SahaayTypography.from(
      base.typography
          .geometryThemeFor(ScriptCategory.englishLike)
          .merge(base.textTheme),
      scheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: shapes.control,
          minimumSize: const Size(64, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: shapes.control,
          minimumSize: const Size(64, 48),
        ),
      ),
      segmentedButtonTheme: _segmentedButtonTheme(colors, typography),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      extensions: [typography, colors, const SahaaySpacing(), shapes],
    );
  }

  /// Single-choice selections, such as the medicine form.
  ///
  /// The selected option uses the selected surface with full-strength text
  /// and a check mark, so it never looks dimmer than the unselected ones and
  /// selection does not rely on colour alone (`docs/design-system.md` §5.5).
  static SegmentedButtonThemeData _segmentedButtonTheme(
    SahaayColors colors,
    SahaayTypography typography,
  ) {
    bool selected(Set<WidgetState> states) =>
        states.contains(WidgetState.selected);
    return SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => selected(states) ? colors.surfaceSelected : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.contentDisabled
              : colors.contentPrimary,
        ),
        textStyle: WidgetStateProperty.resolveWith(
          (states) => selected(states)
              ? typography.actionLabel.copyWith(fontWeight: FontWeight.w700)
              : typography.actionLabel,
        ),
      ),
    );
  }
}

/// Access to design-system roles from widgets.
extension SahaayThemeContext on BuildContext {
  SahaayTypography get typography =>
      Theme.of(this).extension<SahaayTypography>()!;
  SahaayColors get colors => Theme.of(this).extension<SahaayColors>()!;
  SahaaySpacing get spacing => Theme.of(this).extension<SahaaySpacing>()!;
  SahaayShapes get shapes => Theme.of(this).extension<SahaayShapes>()!;
}
