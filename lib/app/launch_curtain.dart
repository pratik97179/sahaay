import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../core/launch/launch_handoff.dart';

/// Carries the launch screen into the app (docs/design-system.md §3).
///
/// Its first frame is the native launch screen exactly: warm paper with the
/// needle and its ticks in a 240-point box at the centre. When Today lays
/// out its ruler, the needle moves and settles into the ruler's needle and
/// the ticks spread into the ruler's ticks while the paper clears. With
/// nothing to land on, or with Reduce Motion, it simply fades.
class LaunchCurtain extends ConsumerStatefulWidget {
  const LaunchCurtain({super.key});

  @override
  ConsumerState<LaunchCurtain> createState() => _LaunchCurtainState();
}

class _LaunchCurtainState extends ConsumerState<LaunchCurtain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this);
  late final LaunchHandoff _handoff = ref.read(launchHandoffProvider);
  LaunchLanding? _landing;
  bool _gone = false;
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    _handoff.reveal.value = 0;
    _handoff.landing.addListener(_onLanding);
    // A first screen that never reports (or reports late) mustn't keep the
    // curtain up.
    _fallback = Timer(const Duration(milliseconds: 2500), () {
      _handoff.land(const LaunchLanding.none());
    });
    _onLanding();
  }

  void _onLanding() {
    final landing = _handoff.landing.value;
    if (landing == null || _landing != null || !mounted) return;
    _fallback?.cancel();
    final still = MediaQuery.disableAnimationsOf(context);
    final morph = landing.needle != null && !still;
    setState(() => _landing = landing);
    _t.duration = Duration(milliseconds: morph ? 900 : 260);
    // Today's ruler is faintly there early, as if it always was, so the
    // marks visibly settle into its places; it comes up fully as they land.
    if (morph) {
      _t.addListener(
        () => _handoff.reveal.value =
            0.35 *
                const Interval(
                  0.15,
                  0.55,
                  curve: Curves.easeOut,
                ).transform(_t.value) +
            0.65 *
                const Interval(
                  0.75,
                  1,
                  curve: Curves.easeInOut,
                ).transform(_t.value),
      );
    } else {
      _handoff.reveal.value = 1;
    }
    _t.forward().whenComplete(() {
      if (mounted) setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _handoff.reveal.value = 1;
    _handoff.landing.removeListener(_onLanding);
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    return AbsorbPointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _CurtainPainter(
            t: _t.value,
            landing: _landing,
            still: MediaQuery.disableAnimationsOf(context),
          ),
        ),
      ),
    );
  }
}

class _CurtainPainter extends CustomPainter {
  _CurtainPainter({
    required this.t,
    required this.landing,
    required this.still,
  });

  final double t;
  final LaunchLanding? landing;
  final bool still;

  static const _paper = DayLight.screen;

  /// The launch mark in its 240-point box: the app icon's needle and ticks,
  /// on the icon's 108-unit grid.
  static List<LaunchLine> _splash(Offset c) {
    const u = 240 / 108;
    LaunchLine line(double x, double top, double bottom, double w, double a) =>
        LaunchLine(
          x: c.dx + x * u,
          top: c.dy + top * u,
          bottom: c.dy + bottom * u,
          width: w * u,
          alpha: a,
        );
    // Order: needle, then right ticks nearest first, then left.
    return [
      line(0, -15, 15, 46 / 12, 1),
      for (final sgn in [1, -1])
        for (var k = 1; k <= 5; k++)
          line(
            sgn * 6.0 * k,
            130 / 12 - (k.isEven ? 150 : 92) / 12,
            130 / 12,
            22 / 12,
            0.88 * (1 - (k - 1) / 5.4),
          ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final from = _splash(size.center(Offset.zero));
    final to = landing;
    final morph = to?.needle != null && !still;
    final targets = morph
        ? <LaunchLine?>[
            to!.needle,
            for (var k = 0; k < 5; k++)
              k < to.right.length ? to.right[k] : null,
            for (var k = 0; k < 5; k++) k < to.left.length ? to.left[k] : null,
          ]
        : null;

    double fade(double begin, double end) =>
        1 - Interval(begin, end, curve: Curves.easeOut).transform(t);
    // The paper clears to show the rest of Today; the ruler marks are only
    // the curtain's until they land.
    final paperAlpha = morph ? fade(0.3, 0.85) : fade(0, 1);
    final markAlpha = morph ? fade(0.85, 1) : fade(0, 1);
    final e = Curves.easeInOutCubic.transform(t);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _paper.page.withValues(alpha: paperAlpha),
    );
    for (final (i, a) in from.indexed) {
      final b = targets?[i];
      // A tick with no ruler tick to go to fades where it is.
      final line = b == null
          ? a
          : LaunchLine(
              x: lerpDouble(a.x, b.x, e)!,
              top: lerpDouble(a.top, b.top, e)!,
              bottom: lerpDouble(a.bottom, b.bottom, e)!,
              width: lerpDouble(a.width, b.width, e)!,
              alpha: lerpDouble(a.alpha, b.alpha, e)!,
            );
      final alpha = line.alpha * markAlpha * (b == null && morph ? 1 - e : 1);
      if (alpha <= 0) continue;
      canvas.drawLine(
        Offset(line.x, line.top),
        Offset(line.x, line.bottom),
        Paint()
          ..strokeWidth = line.width
          ..strokeCap = StrokeCap.round
          ..color = _paper.ink.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_CurtainPainter old) =>
      old.t != t || old.landing != landing || old.still != still;
}
