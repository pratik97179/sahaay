import 'package:flutter/material.dart';

/// Makes a surface pressable with Sahaay's press feedback: no ripple, just
/// a pressed state the surface uses to change its tint
/// (`docs/design-system.md` §9). Keyboard focus and activation come from
/// [InkWell]; the focus highlight follows the theme's focus colour.
///
/// When [onTap] is `null` the child is shown as-is and is not a button.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.onTap,
    required this.shape,
    required this.builder,
    super.key,
  });

  final VoidCallback? onTap;
  final ShapeBorder shape;

  /// Builds the surface for the current pressed state.
  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    if (onTap == null) return widget.builder(context, false);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: widget.shape,
        onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
        child: widget.builder(context, _pressed),
      ),
    );
  }
}
