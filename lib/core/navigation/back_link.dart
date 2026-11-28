import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';

import 'app_navigator.dart';

/// The "‹ today" at the top of a screen: where back goes, said the same way
/// on every screen. Tapping it goes back one screen, unless [onTap] does
/// something else first (a step back inside Add medicine).
class BackLink extends StatelessWidget {
  const BackLink(this.label, {this.onTap, super.key});

  /// Where back goes: "today", "your medicines", a medicine's name.
  final String label;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'back to $label',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => AppNavigator.of(context).back(),
      child: Text(
        '‹  $label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: figtree(17, FontWeight.w700, DayLight.screen.soft),
      ),
    ),
  );
}
