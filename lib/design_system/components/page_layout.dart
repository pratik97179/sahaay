import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// A navigable destination: owns insets, the page heading and screen-level
/// actions (`docs/design-system.md` §3.1, §11.1).
class PageLayout extends StatefulWidget {
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
  State<PageLayout> createState() => _PageLayoutState();
}

class _PageLayoutState extends State<PageLayout> {
  final _headerKey = GlobalKey();

  /// Whether the page heading has scrolled out of view, in which case the
  /// top bar repeats it so the user always knows where they are.
  bool _headingHidden = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final header = _headerKey.currentContext?.findRenderObject();
    final headerHeight = header is RenderBox ? header.size.height : 0.0;
    final hidden = notification.metrics.pixels > headerHeight;
    if (hidden != _headingHidden) setState(() => _headingHidden = hidden);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Scaffold(
      appBar: AppBar(
        title: _headingHidden ? Text(widget.heading) : null,
        actions: widget.actions,
      ),
      floatingActionButton: widget.primaryAction,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PageLayout._maxContentWidth,
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  spacing.pageInset,
                  0,
                  spacing.pageInset,
                  spacing.pageInset * 6,
                ),
                children: [
                  PageHeader(key: _headerKey, heading: widget.heading),
                  SizedBox(height: spacing.sectionSeparation),
                  ...widget.children,
                ],
              ),
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
