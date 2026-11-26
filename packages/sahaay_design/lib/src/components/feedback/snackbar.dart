import 'package:flutter/material.dart';

import '../../tokens/sahaay_tokens.dart';

/// A quiet confirmation, such as "Reminder saved" or "The medicine couldn't
/// be deleted." (`docs/design-system.md` §11.5). It floats above the
/// content, wraps long messages, and leaves on its own.
void showSahaaySnackbar(BuildContext context, String message) {
  final t = context.sahaay;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: t.snackbar.message),
        backgroundColor: t.snackbar.background,
        margin: EdgeInsets.all(t.screen.edge),
      ),
    );
}
