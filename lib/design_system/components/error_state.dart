import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// Shown in place of content that could not be loaded.
class ErrorState extends StatelessWidget {
  const ErrorState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sectionSeparation),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: context.colors.stateDanger.foreground,
          ),
          SizedBox(height: spacing.inlineSeparation),
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
