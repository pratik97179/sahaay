import 'package:flutter/material.dart';

import '../../foundations/spacing.dart';
import '../../tokens/sahaay_tokens.dart';
import 'photo.dart';
import 'pressable.dart';

/// One medicine in the grid (`docs/design-system.md` §11.2, §11.7): a
/// square photo, then the name in the identifying voice and a detail such
/// as the form. Names wrap and are never cut off.
///
/// The whole tile is one button. While pressed, the tile dims slightly —
/// it has no card surface to tint.
class PhotoTile extends StatelessWidget {
  const PhotoTile({
    required this.photo,
    required this.name,
    this.detail,
    this.onTap,
    super.key,
  });

  final ImageProvider photo;
  final String name;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final detail = this.detail;
    final press = t.motion.press;
    return Semantics(
      container: true,
      button: onTap != null,
      label: [name, ?detail].join(', '),
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        shape: t.photoTile.photoShape,
        builder: (context, pressed) => AnimatedOpacity(
          opacity: pressed ? 0.72 : 1,
          duration: press.duration,
          curve: press.curve,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShapedPhoto(
                image: photo,
                shape: t.photoTile.photoShape,
                aspectRatio: 1,
              ),
              const SizedBox(height: Spacing.underLabel),
              Text(name, style: t.photoTile.name),
              if (detail != null) Text(detail, style: t.photoTile.detail),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays out [PhotoTile]s in as many columns as fit.
///
/// A tile is never narrower than `photoTile.minWidth` scaled by the user's
/// text size, so names always have room: phones show one or two columns,
/// wider screens more.
class PhotoTileGrid extends StatelessWidget {
  const PhotoTileGrid({required this.children, super.key});

  final List<Widget> children;

  /// How many columns fit in [width] for the given minimum tile width.
  static int columnsFor({
    required double width,
    required double minTileWidth,
    required double gap,
  }) => ((width + gap) / (minTileWidth + gap)).floor().clamp(1, 1 << 16);

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final gap = t.photoTile.gap;
    final minTileWidth = MediaQuery.textScalerOf(context)
        .scale(t.photoTile.minWidth);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = columnsFor(
          width: width,
          minTileWidth: minTileWidth,
          gap: gap,
        );
        final tileWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap * 2,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
