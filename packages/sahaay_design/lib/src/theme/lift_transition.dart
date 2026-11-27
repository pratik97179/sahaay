import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Sahaay's screen change (`docs/design-system.md` §3): the new screen
/// rises as a rounded card, a little small, low and clear, and settles flat
/// while its corners square off; the screen behind sinks back and dims. One
/// continuous springy motion, mirrored on the way back.
///
/// Swiping in from the left edge takes the screen back, the finger driving
/// the same motion.
class LiftPageTransitionsBuilder extends PageTransitionsBuilder {
  const LiftPageTransitionsBuilder();

  /// A soft spring: quick to start, a long gentle settle.
  static const _curve = Cubic(0.2, 0.9, 0.25, 1);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 520);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 380);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return _BackSwipe(
      route: route,
      child: AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation]),
        child: child,
        builder: (context, child) {
          final gesture = route.navigator?.userGestureInProgress ?? false;
          double eased(Animation<double> a) => gesture
              ? a.value
              : (a.status == AnimationStatus.reverse
                    ? Curves.easeInCubic.flipped.transform(a.value)
                    : _curve.transform(a.value));
          final t = eased(animation); // this screen coming in
          final s = eased(secondaryAnimation); // a screen over this one
          if (reduced) {
            return Opacity(opacity: t.clamp(0.0, 1.0), child: child);
          }
          final radius = 34 * (1 - t) + 26 * s;
          return Transform.translate(
            offset: Offset(0, 48 * (1 - t)),
            child: Transform.scale(
              scale: (0.9 + 0.1 * t) * (1 - 0.06 * s),
              child: Opacity(
                opacity: (t * 1.6).clamp(0.0, 1.0),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18 * s),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        if (t < 1)
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.22 * math.sin(math.pi * t),
                            ),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      clipBehavior: radius > 0.5 ? Clip.antiAlias : Clip.none,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A strip along the left edge: dragging right pulls the screen back, and
/// letting go finishes or undoes the going back.
class _BackSwipe<T> extends StatefulWidget {
  const _BackSwipe({required this.route, required this.child});
  final PageRoute<T> route;
  final Widget child;

  @override
  State<_BackSwipe<T>> createState() => _BackSwipeState<T>();
}

class _BackSwipeState<T> extends State<_BackSwipe<T>> {
  bool _dragging = false;

  // The route's own controller drives the transition; there is no public
  // way to reach it, the same as Flutter's Cupertino back swipe.
  // ignore: invalid_use_of_protected_member
  AnimationController? get _controller => widget.route.controller;

  bool get _canSwipe =>
      !widget.route.isFirst &&
      widget.route.isCurrent &&
      widget.route.popDisposition != RoutePopDisposition.doNotPop &&
      !(widget.route.navigator?.userGestureInProgress ?? false);

  void _start(DragStartDetails d) {
    if (!_canSwipe) return;
    _dragging = true;
    widget.route.navigator?.didStartUserGesture();
  }

  void _update(DragUpdateDetails d) {
    if (!_dragging) return;
    final width = context.size?.width ?? 1;
    final c = _controller;
    if (c != null) c.value -= d.primaryDelta! / width;
  }

  void _end(DragEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    final c = _controller;
    final nav = widget.route.navigator;
    final width = context.size?.width ?? 1;
    final velocity = d.primaryVelocity! / width;
    final back = velocity > 1 || (velocity > -1 && (c?.value ?? 1) < 0.6);
    if (back) {
      nav?.pop();
    } else {
      c?.animateTo(1, curve: Curves.easeOutCubic);
    }
    if (c != null && c.isAnimating) {
      late AnimationStatusListener done;
      done = (status) {
        nav?.didStopUserGesture();
        c.removeStatusListener(done);
      };
      c.addStatusListener(done);
    } else {
      nav?.didStopUserGesture();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      widget.child,
      PositionedDirectional(
        start: 0,
        top: 0,
        bottom: 0,
        width: 20,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _start,
          onHorizontalDragUpdate: _update,
          onHorizontalDragEnd: _end,
          onHorizontalDragCancel: () =>
              _end(DragEndDetails(primaryVelocity: 0)),
        ),
      ),
    ],
  );
}
