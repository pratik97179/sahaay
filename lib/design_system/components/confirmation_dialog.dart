import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// Asks the user to confirm a destructive action (`docs/design-system.md`
/// §11.5). Resolves to `true` only when the user confirms.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final destructive = context.colors.actionDestructive;
      return AlertDialog(
        title: Text(title),
        content: Text(message, style: context.typography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive.background,
              foregroundColor: destructive.foreground,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
