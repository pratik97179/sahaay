import 'package:flutter/material.dart';

import '../../tokens/sahaay_tokens.dart';

/// A medicine photo clipped to the photo shape, at a fixed aspect ratio.
///
/// If the image can't be loaded, a quiet placeholder takes its place so the
/// layout never jumps or shows a broken image.
class ShapedPhoto extends StatelessWidget {
  const ShapedPhoto({
    required this.image,
    required this.shape,
    required this.aspectRatio,
    this.semanticLabel,
    super.key,
  });

  final ImageProvider image;
  final OutlinedBorder shape;
  final double aspectRatio;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Image(
          image: image,
          fit: BoxFit.cover,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: t.card.background,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: t.emptyState.icon,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
