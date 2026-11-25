import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// An action that removes data (`docs/design-system.md` §3.7, §11.4).
///
/// Uses the destructive action colours so it is never mistaken for the
/// primary action; the label always states what will be removed.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final destructive = context.colors.actionDestructive.background;
    final style = OutlinedButton.styleFrom(
      foregroundColor: destructive,
      side: BorderSide(color: destructive),
    );
    final text = Text(label);
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: text)
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: text,
          );
  }
}
