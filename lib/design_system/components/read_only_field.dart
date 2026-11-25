import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// A field shown for reading, not editing: its label above its value
/// (`docs/design-system.md` §3.4). Owns the label-to-value spacing and the
/// separation from the next field.
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    required this.label,
    required this.value,
    this.supporting,
    super.key,
  });

  final String label;
  final String value;

  /// Optional explanation below the value, such as a month-end note.
  final String? supporting;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final supporting = this.supporting;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.fieldSeparation),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: typography.fieldLabel),
            SizedBox(height: spacing.fieldLabelControl),
            Text(value, style: typography.fieldValue),
            if (supporting != null) ...[
              SizedBox(height: spacing.fieldLabelControl),
              Text(supporting, style: typography.supporting),
            ],
          ],
        ),
      ),
    );
  }
}
