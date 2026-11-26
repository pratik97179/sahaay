import 'package:flutter/material.dart';

/// The one main action of a form, such as "Save reminder"
/// (`docs/design-system.md` §3.7, §11.4): a full-width filled sage pill.
///
/// Its colours, pressed tint, shape and height come from the theme's
/// button tokens. Use one per screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final text = Text(label, textAlign: TextAlign.center);
    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? FilledButton(onPressed: onPressed, child: text)
          : FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: text,
            ),
    );
  }
}
