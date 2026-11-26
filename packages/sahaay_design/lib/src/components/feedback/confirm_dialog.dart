import 'package:flutter/material.dart';

import '../../tokens/sahaay_tokens.dart';

/// Asks people to confirm a destructive action, such as deleting a
/// medicine (`docs/design-system.md` §11.5). Resolves to `true` only when
/// they confirm; dismissing or cancelling resolves to `false`.
///
/// The confirm button is a filled brick button; Cancel is a quiet text
/// button below it. Buttons are stacked full width, so long labels and
/// large text always fit. With reduced motion the dialog appears at once.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final t = context.sahaay;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: t.dialog.scrim,
    animationStyle: t.motion.reduced ? AnimationStyle.noAnimation : null,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return confirmed ?? false;
}

/// The dialog shown by [showConfirmDialog].
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final d = t.dialog;
    final edge = t.screen.edge;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(edge),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: d.background,
            shape: d.shape,
            shadows: d.shadow,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(edge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: d.title),
                SizedBox(height: t.section.titleGap),
                Text(message, style: d.message),
                SizedBox(height: t.field.gap),
                FilledButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.pressed)
                          ? d.confirmPressedBackground
                          : d.confirmBackground,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      d.confirmLabel.color,
                    ),
                    textStyle: WidgetStatePropertyAll(d.confirmLabel),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel, textAlign: TextAlign.center),
                ),
                SizedBox(height: t.field.labelGap),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
