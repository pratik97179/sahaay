import 'package:flutter/material.dart';

import '../../foundations/spacing.dart';
import '../../tokens/sahaay_tokens.dart';
import 'photo.dart';

/// The raised panel at the top of a reminder screen
/// (`docs/design-system.md` §11.2, §11.7): what to take, in one block —
/// the photo first, then the name, then the quantity and instruction.
///
/// It never says "missed" or "late". When there is no quantity or
/// instruction, that line is simply left out.
class TakePanel extends StatelessWidget {
  const TakePanel({
    required this.photo,
    required this.name,
    this.instruction,
    this.photoSemanticLabel,
    super.key,
  });

  final ImageProvider photo;
  final String name;

  /// The quantity and instruction, such as "2 tablets · after food".
  final String? instruction;

  /// Describes the photo for screen readers, such as "Photo of Test 2".
  final String? photoSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final p = t.takePanel;
    final instruction = this.instruction;
    return DecoratedBox(
      decoration: ShapeDecoration(color: p.background, shape: p.shape),
      child: Padding(
        padding: p.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShapedPhoto(
              image: photo,
              shape: p.photoShape,
              aspectRatio: 4 / 3,
              semanticLabel: photoSemanticLabel,
            ),
            const SizedBox(height: Spacing.betweenItems),
            Text(name, style: p.name),
            if (instruction != null) ...[
              const SizedBox(height: Spacing.underLabel),
              Text(instruction, style: p.instruction),
            ],
          ],
        ),
      ),
    );
  }
}
