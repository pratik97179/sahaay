import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'day_light.dart';

/// The sky over Today's ruler when the day has nothing on it
/// (`docs/design-system.md` §3): a faint horizon, the day's path rising
/// over it and dipping under it, and the sun or moon on that path at
/// [hour]. Midnight is at either end, noon at the top in the middle.
///
/// It only draws [hour]; whatever moves [hour] (the ruler) is the one
/// control. Each change repaints the sky and nothing else.
class DaySky extends StatelessWidget {
  const DaySky({required this.hour, required this.light, super.key});

  /// The hour of the day, 0–24, as a fraction.
  final ValueListenable<double> hour;
  final DayLight light;

  /// The sun's warm colour.
  static const sun = Color(0xFFE8B04B);

  /// The moon's pale cool disc.
  static const moon = Color(0xFFC9D3E2);

  /// The moon's blue halo.
  static const moonGlow = Color(0xFF7F9CCB);

  /// The sun's halo follows the light of the day: reddish low by the
  /// horizon, orange as it climbs, yellow at noon.
  static const sunLow = Color(0xFFE2643C);
  static const sunMid = Color(0xFFF0903A);
  static const sunHigh = Color(0xFFF4C24A);

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AspectRatio(
      aspectRatio: 2.2,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SkyPainter(hour, light),
      ),
    ),
  );
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.hour, this.light) : super(repaint: hour);

  final ValueListenable<double> hour;
  final DayLight light;

  /// How far the horizon sits below the middle of the path's swing: the
  /// path spends longer over it than under it, crossing it a little before
  /// half past five and after half past six.
  static const _lift = 0.2;

  /// The height (the horizon at 0, noon at 1) over which the sun turns
  /// into the moon and back.
  static const _dusk = 0.2;

  /// The path's height at [h]: one smooth swing of the day, 1 at noon, 0 at
  /// the horizon, lowest at midnight.
  static double _height(double h) =>
      (_lift - math.cos(2 * math.pi * h / 24)) / (1 + _lift);

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.width * 0.04).clamp(11.0, 17.0);
    final inset = r * 2.2;
    final left = inset;
    final width = size.width - inset * 2;
    final rise = (size.height - inset * 2) / (1 + (1 - _lift) / (1 + _lift));
    final horizon = inset + rise;
    Offset at(double h) =>
        Offset(left + width * h / 24, horizon - rise * _height(h));

    // Both lines fade out softly over a third of the width at each end.
    Shader fade(Color c) => LinearGradient(
      colors: [c.withValues(alpha: 0), c, c, c.withValues(alpha: 0)],
      stops: const [0, 0.36, 0.64, 1],
    ).createShader(Offset.zero & size);

    canvas.drawLine(
      Offset(0, horizon),
      Offset(size.width, horizon),
      Paint()
        ..strokeWidth = 1
        ..shader = fade(light.soft.withValues(alpha: 0.3)),
    );

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i <= 240; i++) {
      final p = at(i / 10);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = fade(light.soft.withValues(alpha: 0.55)),
    );

    // Pulled past either end of the day, the ruler stretches and the body
    // goes with it, sideways off the end of the path.
    final h = hour.value.clamp(0.0, 24.0);
    final c = Offset(left + width * hour.value / 24, at(h).dy);
    final up = _height(h).clamp(0.0, 1.0);
    final sunlight = up < 0.5
        ? Color.lerp(DaySky.sunLow, DaySky.sunMid, up * 2)!
        : Color.lerp(DaySky.sunMid, DaySky.sunHigh, up * 2 - 1)!;
    // 0 in the day, 1 at night, easing through dusk and dawn.
    final night = 1 - _smooth((_height(h) + _dusk) / (2 * _dusk));
    final color = Color.lerp(DaySky.sun, DaySky.moon, night)!;
    final glow = Color.lerp(sunlight, DaySky.moonGlow, night)!;

    canvas.drawCircle(
      c,
      r * 1.8,
      Paint()
        ..color = glow.withValues(alpha: 0.4 - 0.05 * night)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9),
    );

    // The sun's rays: four longer on the axes, four shorter between them.
    // They draw back into the disc as night comes, and out again at dawn.
    final day = 1 - night;
    if (day > 0) {
      final ray = Paint()
        ..color = DaySky.sun.withValues(alpha: day)
        ..strokeWidth = r * 0.14
        ..strokeCap = StrokeCap.round;
      final from = r * 1.3;
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final length = (i.isEven ? r * 0.3 : r * 0.17) * day;
        final dir = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(c + dir * from, c + dir * (from + length), ray);
      }
    }

    canvas.drawCircle(c, r, Paint()..color = color);
  }

  static double _smooth(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.hour != hour || old.light != light;
}
