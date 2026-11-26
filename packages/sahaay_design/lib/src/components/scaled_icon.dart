import 'package:flutter/widgets.dart';

import '../foundations/sizing.dart';

/// An icon sized from the text it sits beside, so it grows with the user's
/// text size instead of staying at a fixed size.
class ScaledIcon extends StatelessWidget {
  const ScaledIcon(
    this.icon, {
    required this.besideText,
    this.color,
    super.key,
  });

  final IconData icon;

  /// The text style the icon accompanies.
  final TextStyle besideText;
  final Color? color;

  /// The icon size for [style] at the user's text size.
  static double sizeFor(BuildContext context, TextStyle style) =>
      MediaQuery.textScalerOf(context)
          .scale(style.fontSize! * Sizing.iconToText);

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: sizeFor(context, besideText), color: color);
}
