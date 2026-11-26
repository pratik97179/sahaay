import 'package:flutter/material.dart';

import '../../foundations/spacing.dart';
import '../../tokens/sahaay_tokens.dart';
import '../scaled_icon.dart';

/// A small, neutral label for a state, such as "Paused"
/// (`docs/design-system.md` §11.5). Always an icon and a word — never
/// colour alone — and never urgent.
class Tag extends StatelessWidget {
  const Tag({required this.label, required this.icon, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay.tag;
    return DecoratedBox(
      decoration: ShapeDecoration(color: t.background, shape: t.shape),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.besideIcon,
          vertical: Spacing.betweenRows * 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaledIcon(icon, besideText: t.label, color: t.icon),
            const SizedBox(width: Spacing.underLabel),
            Flexible(child: Text(label, style: t.label)),
          ],
        ),
      ),
    );
  }
}
