import 'package:flutter/material.dart';

import '../../tokens/sahaay_tokens.dart';
import 'pressable.dart';

/// A card on the page (`docs/design-system.md` §11.2): a warm surface one
/// step off the page, with soft continuous corners and no border.
///
/// When [onTap] is given the whole card is one button, and pressing it
/// deepens its tint. Named `ItemCard` so it never clashes with Material's
/// `Card`.
class ItemCard extends StatelessWidget {
  const ItemCard({
    required this.child,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Read by screen readers in place of the card's text, when the text
  /// alone would not make sense.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    return CardSurface(
      background: t.card.background,
      pressedBackground: t.card.pressedBackground,
      shape: t.card.shape,
      padding: t.card.padding,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}

/// The surface shared by [ItemCard] and other cards such as the time card.
class CardSurface extends StatelessWidget {
  const CardSurface({
    required this.background,
    required this.pressedBackground,
    required this.shape,
    required this.padding,
    required this.child,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Color background;
  final Color pressedBackground;
  final OutlinedBorder shape;
  final EdgeInsets padding;
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final press = context.sahaay.motion.press;
    final surface = Pressable(
      onTap: onTap,
      shape: shape,
      builder: (context, pressed) => AnimatedContainer(
        duration: press.duration,
        curve: press.curve,
        decoration: ShapeDecoration(
          color: pressed ? pressedBackground : background,
          shape: shape,
        ),
        padding: padding,
        child: child,
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: surface,
    );
  }
}
