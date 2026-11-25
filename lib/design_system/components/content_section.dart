import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// A logically independent group within a page (`docs/design-system.md` §3.2).
///
/// Owns its heading, heading-to-content spacing and separation from the next
/// section.
class ContentSection extends StatelessWidget {
  const ContentSection({
    required this.heading,
    required this.child,
    this.trailing,
    super.key,
  });

  final String heading;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sectionSeparation),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    heading,
                    style: context.typography.sectionHeading,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: spacing.sectionHeadingContent),
          child,
        ],
      ),
    );
  }
}
