import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// A navigable destination: owns insets, the page heading and screen-level
/// actions (`docs/design-system.md` §3.1, §11.1).
class PageLayout extends StatelessWidget {
  const PageLayout({
    required this.heading,
    required this.children,
    this.primaryAction,
    this.actions = const [],
    super.key,
  });

  final String heading;
  final List<Widget> children;
  final Widget? primaryAction;
  final List<Widget> actions;

  /// Content wider than this is centred rather than stretched.
  static const double _maxContentWidth = 720;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Scaffold(
      appBar: AppBar(actions: actions),
      floatingActionButton: primaryAction,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                spacing.pageInset,
                0,
                spacing.pageInset,
                spacing.pageInset * 6,
              ),
              children: [
                PageHeader(heading: heading),
                SizedBox(height: spacing.sectionSeparation),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page's single primary heading.
class PageHeader extends StatelessWidget {
  const PageHeader({required this.heading, super.key});

  final String heading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(heading, style: context.typography.pageHeading),
    );
  }
}
