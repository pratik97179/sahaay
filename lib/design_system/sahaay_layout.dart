import 'package:flutter/material.dart';

/// Spacing relationships from `docs/design-system.md` §6.
///
/// Feature code should rarely read these directly; layout components own
/// spacing. Values are placeholders.
@immutable
class SahaaySpacing extends ThemeExtension<SahaaySpacing> {
  const SahaaySpacing({
    this.pageInset = 16,
    this.sectionSeparation = 32,
    this.sectionHeadingContent = 12,
    this.itemSeparation = 12,
    this.itemInset = 16,
    this.fieldSeparation = 16,
    this.fieldLabelControl = 8,
    this.inlineSeparation = 8,
    this.contentInset = 16,
  });

  final double pageInset;
  final double sectionSeparation;
  final double sectionHeadingContent;
  final double itemSeparation;
  final double itemInset;
  final double fieldSeparation;
  final double fieldLabelControl;
  final double inlineSeparation;
  final double contentInset;

  @override
  SahaaySpacing copyWith() => this;

  @override
  SahaaySpacing lerp(SahaaySpacing? other, double t) => this;
}

/// Shape roles from `docs/design-system.md` §7. Values are placeholders.
@immutable
class SahaayShapes extends ThemeExtension<SahaayShapes> {
  const SahaayShapes({
    this.card = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    this.panel = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    this.control = const StadiumBorder(),
    this.input = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.chip = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.dialog = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
    this.sheet = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    this.media = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    this.pill = const StadiumBorder(),
  });

  final ShapeBorder card;
  final ShapeBorder panel;
  final OutlinedBorder control;
  final OutlinedBorder input;
  final OutlinedBorder chip;
  final ShapeBorder dialog;
  final ShapeBorder sheet;
  final ShapeBorder media;
  final OutlinedBorder pill;

  @override
  SahaayShapes copyWith() => this;

  @override
  SahaayShapes lerp(SahaayShapes? other, double t) => this;
}
