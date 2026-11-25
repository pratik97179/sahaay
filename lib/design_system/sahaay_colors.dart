import 'package:flutter/material.dart';

/// A foreground/background pair for roles that need both (§5.3, §5.5).
@immutable
class ColorPair {
  const ColorPair({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static ColorPair lerp(ColorPair a, ColorPair b, double t) => ColorPair(
    background: Color.lerp(a.background, b.background, t)!,
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
  );
}

/// Semantic colour roles from `docs/design-system.md` §5.
///
/// Values are placeholders mapped from the Material colour scheme; light and
/// dark appearances resolve the same roles.
@immutable
class SahaayColors extends ThemeExtension<SahaayColors> {
  const SahaayColors({
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentQuiet,
    required this.contentDisabled,
    required this.contentInverse,
    required this.surfacePage,
    required this.surfaceContent,
    required this.surfaceContainer,
    required this.surfaceRaised,
    required this.surfaceInput,
    required this.surfaceSelected,
    required this.surfaceDisabled,
    required this.surfaceOverlay,
    required this.actionPrimary,
    required this.actionSecondary,
    required this.actionDestructive,
    required this.actionDisabled,
    required this.boundarySubtle,
    required this.boundaryDefault,
    required this.boundaryEmphasized,
    required this.boundaryFocus,
    required this.stateSuccess,
    required this.stateWarning,
    required this.stateDanger,
    required this.stateInformation,
  });

  factory SahaayColors.from(ColorScheme s) {
    final disabledContent = s.onSurface.withValues(alpha: 0.38);
    final disabledSurface = s.onSurface.withValues(alpha: 0.12);
    final dark = s.brightness == Brightness.dark;
    return SahaayColors(
      contentPrimary: s.onSurface,
      contentSecondary: s.onSurfaceVariant,
      contentQuiet: s.outline,
      contentDisabled: disabledContent,
      contentInverse: s.onInverseSurface,
      surfacePage: s.surface,
      surfaceContent: s.surface,
      surfaceContainer: s.surfaceContainer,
      surfaceRaised: s.surfaceContainerHigh,
      surfaceInput: s.surfaceContainerHighest,
      surfaceSelected: s.secondaryContainer,
      surfaceDisabled: disabledSurface,
      surfaceOverlay: s.surfaceContainerHigh,
      actionPrimary: ColorPair(background: s.primary, foreground: s.onPrimary),
      actionSecondary: ColorPair(
        background: s.secondaryContainer,
        foreground: s.onSecondaryContainer,
      ),
      actionDestructive: ColorPair(background: s.error, foreground: s.onError),
      actionDisabled: ColorPair(
        background: disabledSurface,
        foreground: disabledContent,
      ),
      boundarySubtle: s.outlineVariant,
      boundaryDefault: s.outline,
      boundaryEmphasized: s.onSurface,
      boundaryFocus: s.primary,
      stateSuccess: dark
          ? const ColorPair(
              background: Color(0xFF1E4620),
              foreground: Color(0xFFB8F0B9),
            )
          : const ColorPair(
              background: Color(0xFFD7F5D8),
              foreground: Color(0xFF0F3D12),
            ),
      stateWarning: dark
          ? const ColorPair(
              background: Color(0xFF4D3800),
              foreground: Color(0xFFFFDEA6),
            )
          : const ColorPair(
              background: Color(0xFFFFEFC9),
              foreground: Color(0xFF3F2E00),
            ),
      stateDanger: ColorPair(
        background: s.errorContainer,
        foreground: s.onErrorContainer,
      ),
      stateInformation: ColorPair(
        background: s.tertiaryContainer,
        foreground: s.onTertiaryContainer,
      ),
    );
  }

  final Color contentPrimary;
  final Color contentSecondary;
  final Color contentQuiet;
  final Color contentDisabled;
  final Color contentInverse;
  final Color surfacePage;
  final Color surfaceContent;
  final Color surfaceContainer;
  final Color surfaceRaised;
  final Color surfaceInput;
  final Color surfaceSelected;
  final Color surfaceDisabled;
  final Color surfaceOverlay;
  final ColorPair actionPrimary;
  final ColorPair actionSecondary;
  final ColorPair actionDestructive;
  final ColorPair actionDisabled;
  final Color boundarySubtle;
  final Color boundaryDefault;
  final Color boundaryEmphasized;
  final Color boundaryFocus;
  final ColorPair stateSuccess;
  final ColorPair stateWarning;
  final ColorPair stateDanger;
  final ColorPair stateInformation;

  @override
  SahaayColors copyWith() => this;

  @override
  SahaayColors lerp(SahaayColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    ColorPair p(ColorPair a, ColorPair b) => ColorPair.lerp(a, b, t);
    return SahaayColors(
      contentPrimary: c(contentPrimary, other.contentPrimary),
      contentSecondary: c(contentSecondary, other.contentSecondary),
      contentQuiet: c(contentQuiet, other.contentQuiet),
      contentDisabled: c(contentDisabled, other.contentDisabled),
      contentInverse: c(contentInverse, other.contentInverse),
      surfacePage: c(surfacePage, other.surfacePage),
      surfaceContent: c(surfaceContent, other.surfaceContent),
      surfaceContainer: c(surfaceContainer, other.surfaceContainer),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceInput: c(surfaceInput, other.surfaceInput),
      surfaceSelected: c(surfaceSelected, other.surfaceSelected),
      surfaceDisabled: c(surfaceDisabled, other.surfaceDisabled),
      surfaceOverlay: c(surfaceOverlay, other.surfaceOverlay),
      actionPrimary: p(actionPrimary, other.actionPrimary),
      actionSecondary: p(actionSecondary, other.actionSecondary),
      actionDestructive: p(actionDestructive, other.actionDestructive),
      actionDisabled: p(actionDisabled, other.actionDisabled),
      boundarySubtle: c(boundarySubtle, other.boundarySubtle),
      boundaryDefault: c(boundaryDefault, other.boundaryDefault),
      boundaryEmphasized: c(boundaryEmphasized, other.boundaryEmphasized),
      boundaryFocus: c(boundaryFocus, other.boundaryFocus),
      stateSuccess: p(stateSuccess, other.stateSuccess),
      stateWarning: p(stateWarning, other.stateWarning),
      stateDanger: p(stateDanger, other.stateDanger),
      stateInformation: p(stateInformation, other.stateInformation),
    );
  }
}
