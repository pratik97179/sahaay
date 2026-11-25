import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// Shown when a collection has no content yet.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.message, this.icon, super.key});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sectionSeparation),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 48, color: context.colors.contentQuiet),
            SizedBox(height: spacing.inlineSeparation),
          ],
          Text(
            message,
            style: context.typography.supporting,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
