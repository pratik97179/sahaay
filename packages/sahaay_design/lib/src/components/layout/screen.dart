import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../tokens/sahaay_tokens.dart';

/// One navigable destination: a Page in the content hierarchy
/// (`docs/design-system.md` §3.1, §11.1).
///
/// Owns the page background, the side insets, the screen title and an
/// optional subtitle, and the frosted top bar. The bar stays empty while
/// the title is on screen and repeats it once it scrolls away, so people
/// always know where they are. With high contrast on, the bar is solid.
class Screen extends StatefulWidget {
  const Screen({
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.floatingAction,
    super.key,
  });

  /// Names the screen, such as "Medicines" or a medicine's name.
  final String title;

  /// A short line under the title giving context.
  final String? subtitle;

  /// The screen's sections, top to bottom.
  final List<Widget> children;

  /// Icon actions shown at the end of the top bar.
  final List<Widget> actions;

  /// An action that floats above the content, such as "Add medicine".
  final Widget? floatingAction;

  /// Content wider than this is centred rather than stretched.
  static const double maxContentWidth = 720;

  @override
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  final _titleKey = GlobalKey();
  bool _titleHidden = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final title = _titleKey.currentContext?.findRenderObject();
    final height = title is RenderBox ? title.size.height : 0.0;
    final hidden = notification.metrics.pixels > height;
    if (hidden != _titleHidden) setState(() => _titleHidden = hidden);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final padding = MediaQuery.paddingOf(context);
    final barHeight = padding.top + kToolbarHeight;
    final bottomRoom = widget.floatingAction == null ? 0.0 : 96.0;
    return Scaffold(
      backgroundColor: t.screen.background,
      extendBodyBehindAppBar: true,
      floatingActionButton: widget.floatingAction,
      appBar: _TopBar(
        title: widget.title,
        showTitle: _titleHidden,
        actions: widget.actions,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Screen.maxContentWidth),
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                t.screen.edge + padding.left,
                barHeight,
                t.screen.edge + padding.right,
                t.screen.edge + padding.bottom + bottomRoom,
              ),
              children: [
                _ScreenHeader(
                  key: _titleKey,
                  title: widget.title,
                  subtitle: widget.subtitle,
                ),
                SizedBox(height: t.screen.sectionGap),
                ...widget.children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final subtitle = this.subtitle;
    // The title grows with the user's text size, but more gently than
    // reading text, and wraps rather than clipping.
    final titleScaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: t.screen.titleMaxScale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: t.screen.title, textScaler: titleScaler),
        ),
        if (subtitle != null) ...[
          SizedBox(height: t.screen.subtitleGap),
          Text(subtitle, style: t.screen.subtitle),
        ],
      ],
    );
  }
}

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar({
    required this.title,
    required this.showTitle,
    required this.actions,
  });

  final String title;
  final bool showTitle;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final frost = t.topBar.frost;
    final motion = showTitle ? t.motion.appear : t.motion.disappear;
    final bar = AppBar(
      backgroundColor: frost?.tint ?? t.topBar.solidBackground,
      foregroundColor: t.topBar.icon,
      actions: actions,
      title: AnimatedOpacity(
        opacity: showTitle ? 1 : 0,
        duration: motion.duration,
        curve: motion.curve,
        child: ExcludeSemantics(
          excluding: !showTitle,
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
    if (frost == null) return bar;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: frost.blur / 2,
          sigmaY: frost.blur / 2,
        ),
        child: bar,
      ),
    );
  }
}
