import 'package:flutter/material.dart';

/// Sahaay's screen change (`docs/design-system.md` §3): the new screen
/// grows from slightly small to full size about the screen's centre while it
/// fades in. Going back, the leaving screen shrinks and fades out, the exact
/// reverse in the same time. Only that one screen moves: the screen beneath
/// stays still.
///
/// The two screens never show through each other. A veil of page paper,
/// full size and still, washes the screen beneath out in the first half;
/// the new screen fades in over that clean paper. Going back, the leaving
/// screen fades out first and the veil clears last.
///
/// Swiping in from the left edge takes the screen back, the finger driving
/// the same motion.
class ScreenChangeTransitionsBuilder extends PageTransitionsBuilder {
  const ScreenChangeTransitionsBuilder();

  /// Forward eases out; going back plays the same curve flipped, so the
  /// motion back is the motion forward, reversed.
  static const _curve = Curves.easeOutCubic;

  static const _duration = Duration(milliseconds: 420);

  /// How small the screen is when it is fully faded.
  static const _smallest = 0.92;

  /// The veil is whole by this point of the change.
  static const _veiled = 0.5;

  /// The screen's own fade starts at this point of the change.
  static const _showing = 0.2;

  @override
  Duration get transitionDuration => _duration;

  @override
  Duration get reverseTransitionDuration => _duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final paper = Theme.of(context).scaffoldBackgroundColor;
    return _BackSwipe(
      route: route,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final gesture = route.navigator?.userGestureInProgress ?? false;
          final t = gesture
              ? animation.value
              : (animation.status == AnimationStatus.reverse
                    ? _curve.flipped.transform(animation.value)
                    : _curve.transform(animation.value));
          final veil = (t / _veiled).clamp(0.0, 1.0);
          final shown = ((t - _showing) / (1 - _showing)).clamp(0.0, 1.0);
          final faded = Opacity(opacity: shown, child: child);
          return Stack(
            fit: StackFit.passthrough,
            children: [
              // Always present, so the screen's own state is never rebuilt
              // when the change ends.
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(color: paper.withValues(alpha: veil)),
                ),
              ),
              if (reduced)
                faded
              else
                Transform.scale(
                  scale: _smallest + (1 - _smallest) * t,
                  child: faded,
                ),
            ],
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
