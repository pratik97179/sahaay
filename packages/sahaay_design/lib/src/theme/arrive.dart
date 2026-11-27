import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// How a piece of a screen joins the screen change (`docs/design-system.md`
/// §18.3). Each piece has its own small motion, so the screen assembles
/// rather than appearing at once.
enum ArriveStyle {
  /// Rises a little and comes into focus from a soft blur: titles.
  focus,

  /// Slides in from the leading edge: the way back.
  slide,

  /// Drops in from slightly above and settles: buttons in a corner.
  drop,

  /// Rises from low down, a little small, like a print set on the table.
  rise,
}

/// Plays [child]'s part in its route's transition, in turn [order]: later
/// pieces start later, so the screen fills in top to bottom. On the way
/// back every piece leaves together, quickly, so nothing lingers.
///
/// Outside a route transition it draws [child] untouched.
class Arrive extends StatelessWidget {
  const Arrive({
    required this.child,
    this.order = 0,
    this.style = ArriveStyle.rise,
    super.key,
  });

  final Widget child;
  final int order;
  final ArriveStyle style;

  static const _step = 0.07;
  static const _span = 0.55;
  static const _curve = Cubic(0.2, 0.9, 0.25, 1);

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = animation.value;
        if (v >= 1) return child!;
        final double t;
        if (animation.status == AnimationStatus.reverse) {
          t = Curves.easeIn.transform(((v - 0.4) / 0.6).clamp(0.0, 1.0));
        } else {
          final start = (0.12 + order * _step).clamp(0.0, 1 - _span);
          t = _curve.transform(((v - start) / _span).clamp(0.0, 1.0));
        }
        final u = 1 - t;
        Widget out = child!;
        switch (style) {
          case ArriveStyle.focus:
            final sigma = 8 * u;
            if (sigma > 0.05) {
              out = ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: out,
              );
            }
            out = Transform.translate(offset: Offset(0, 14 * u), child: out);
          case ArriveStyle.slide:
            final dx = Directionality.of(context) == TextDirection.rtl
                ? 28.0
                : -28.0;
            out = Transform.translate(offset: Offset(dx * u, 0), child: out);
          case ArriveStyle.drop:
            out = Transform.translate(
              offset: Offset(0, -12 * u),
              child: Transform.rotate(angle: -0.25 * u, child: out),
            );
          case ArriveStyle.rise:
            out = Transform.translate(
              offset: Offset(0, 36 * u),
              child: Transform.scale(scale: 1 - 0.06 * u, child: out),
            );
        }
        return Opacity(opacity: t, child: out);
      },
    );
  }
}
