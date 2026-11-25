import 'package:flutter/material.dart';

/// Typography roles from `docs/design-system.md` §4.
///
/// Concrete values are placeholders derived from the Material text theme and
/// will be tuned iteratively; feature code must only reference the roles.
@immutable
class SahaayTypography extends ThemeExtension<SahaayTypography> {
  const SahaayTypography({
    required this.pageHeading,
    required this.sectionHeading,
    required this.itemHeading,
    required this.primaryValue,
    required this.body,
    required this.bodyEmphasis,
    required this.supporting,
    required this.fieldLabel,
    required this.fieldValue,
    required this.metadata,
    required this.actionLabel,
    required this.statusLabel,
  });

  factory SahaayTypography.from(TextTheme text, ColorScheme scheme) {
    final secondary = scheme.onSurfaceVariant;
    return SahaayTypography(
      pageHeading: text.headlineMedium!,
      sectionHeading: text.titleLarge!,
      itemHeading: text.titleMedium!,
      primaryValue: text.titleLarge!.copyWith(fontWeight: FontWeight.w600),
      body: text.bodyLarge!,
      bodyEmphasis: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
      supporting: text.bodyMedium!.copyWith(color: secondary),
      fieldLabel: text.labelLarge!.copyWith(color: secondary),
      fieldValue: text.bodyLarge!,
      metadata: text.bodySmall!.copyWith(color: secondary),
      actionLabel: text.labelLarge!,
      statusLabel: text.labelMedium!.copyWith(fontWeight: FontWeight.w600),
    );
  }

  final TextStyle pageHeading;
  final TextStyle sectionHeading;
  final TextStyle itemHeading;
  final TextStyle primaryValue;
  final TextStyle body;
  final TextStyle bodyEmphasis;
  final TextStyle supporting;
  final TextStyle fieldLabel;
  final TextStyle fieldValue;
  final TextStyle metadata;
  final TextStyle actionLabel;
  final TextStyle statusLabel;

  @override
  SahaayTypography copyWith() => this;

  @override
  SahaayTypography lerp(SahaayTypography? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return SahaayTypography(
      pageHeading: l(pageHeading, other.pageHeading),
      sectionHeading: l(sectionHeading, other.sectionHeading),
      itemHeading: l(itemHeading, other.itemHeading),
      primaryValue: l(primaryValue, other.primaryValue),
      body: l(body, other.body),
      bodyEmphasis: l(bodyEmphasis, other.bodyEmphasis),
      supporting: l(supporting, other.supporting),
      fieldLabel: l(fieldLabel, other.fieldLabel),
      fieldValue: l(fieldValue, other.fieldValue),
      metadata: l(metadata, other.metadata),
      actionLabel: l(actionLabel, other.actionLabel),
      statusLabel: l(statusLabel, other.statusLabel),
    );
  }
}
