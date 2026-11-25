import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// A field whose control is not a text input, such as a photo or a choice
/// (`docs/design-system.md` §3.4, §11.3).
///
/// Owns the label, the label-to-control spacing, validation feedback and the
/// separation from the next field. Named to avoid clashing with Flutter's
/// `FormField`.
class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    required this.child,
    this.errorText,
    super.key,
  });

  final String label;
  final Widget child;

  /// Validation feedback shown below the control, or `null` when valid.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final error = errorText;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.fieldSeparation),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: context.typography.fieldLabel),
          SizedBox(height: spacing.fieldLabelControl),
          child,
          if (error != null) ...[
            SizedBox(height: spacing.fieldLabelControl),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: context.colors.stateDanger.foreground,
                  ),
                  SizedBox(width: spacing.inlineSeparation),
                  Expanded(
                    child: Text(
                      error,
                      style: context.typography.supporting.copyWith(
                        color: context.colors.stateDanger.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
