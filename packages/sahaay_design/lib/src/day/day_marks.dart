import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'day_light.dart';

/// The cream paper of prints and cards, with the ink drawn on it
/// (`docs/design-system.md` §18.3).
abstract final class Paper {
  /// The paper itself.
  static const sheet = Color(0xFFFBFAF6);

  /// Main text and marks on paper.
  static const ink = Color(0xFF2A2622);

  /// Quieter text and marks on paper.
  static const soft = Color(0xFF6B6660);
}

/// A time as the app writes it: "7:30 am", or "19:30" when the phone uses
/// a 24-hour clock.
String clockText(BuildContext context, int hour, int minute) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(
          TimeOfDay(hour: hour, minute: minute),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        )
        .toLowerCase();

/// The medicine photo: a soft-cornered frame, never a circle.
class MedPhoto extends StatelessWidget {
  const MedPhoto({required this.image, this.radius = 36, super.key});
  final ImageProvider image;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Image(
          image: image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) =>
              const ColoredBox(color: Color(0x22000000)),
        ),
      ),
    );
  }
}

/// A whole day on one line, midnight to midnight: quiet marks at 6 am, noon
/// and 6 pm, a faint tick at now, and a dot at each reminder's time (a ring
/// when paused).
class DayStrip extends StatelessWidget {
  const DayStrip({
    required this.marks,
    required this.now,
    required this.ink,
    required this.soft,
    required this.background,
    super.key,
  });

  /// Each reminder: its hour (0–24) and whether it is paused.
  final List<(double, bool)> marks;
  final double? now;
  final Color ink, soft, background;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return SizedBox(
      height: 22 + scaler.scale(10) * 1.3,
      width: double.infinity,
      child: CustomPaint(
        painter: _DayStripPainter(marks, now, scaler, ink, soft, background),
      ),
    );
  }
}

class _DayStripPainter extends CustomPainter {
  _DayStripPainter(
    this.marks,
    this.now,
    this.scaler,
    this.ink,
    this.soft,
    this.background,
  );
  final List<(double, bool)> marks;
  final double? now;
  final TextScaler scaler;
  final Color ink, soft, background;

  @override
  void paint(Canvas canvas, Size size) {
    const dotY = 9.0, lineY = 9.0;
    const inset = 5.0;
    final w = size.width - inset * 2;
    double x(double h) => inset + w * h / 24;
    canvas.drawLine(
      Offset(x(0), lineY),
      Offset(x(24), lineY),
      Paint()
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = soft.withValues(alpha: 0.35),
    );
    for (final (h, label) in const [
      (6.0, '6am'),
      (12.0, 'noon'),
      (18.0, '6pm'),
    ]) {
      canvas.drawLine(
        Offset(x(h), lineY - 4),
        Offset(x(h), lineY + 4),
        Paint()
          ..strokeWidth = 1.2
          ..color = soft.withValues(alpha: 0.5),
      );
      final tp = TextPainter(
        text: TextSpan(text: label, style: figtree(10, FontWeight.w700, soft)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      tp.paint(canvas, Offset(x(h) - tp.width / 2, lineY + 8));
    }
    final n = now;
    if (n != null) {
      canvas.drawLine(
        Offset(x(n), lineY - 7),
        Offset(x(n), lineY + 7),
        Paint()
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = ink.withValues(alpha: 0.3),
      );
    }
    for (final (h, paused) in marks) {
      final c = Offset(x(h), dotY);
      if (paused) {
        canvas.drawCircle(c, 4.2, Paint()..color = background);
        canvas.drawCircle(
          c,
          4.2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = soft,
        );
      } else {
        canvas.drawCircle(c, 4.6, Paint()..color = ink);
      }
    }
  }

  @override
  bool shouldRepaint(_DayStripPainter old) =>
      old.marks != marks ||
      old.now != now ||
      old.scaler != scaler ||
      old.ink != ink;
}

/// A small drawn mark for the medicine's form: a capsule for oral, a
/// syringe for injectable.
class FormMark extends CustomPainter {
  FormMark({
    required this.injectable,
    required this.color,
    this.filled = false,
  });
  final bool injectable;
  final Color color;

  /// Drawn solid, for a chosen form.
  final bool filled;

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.rotate(-math.pi / 4);
    final u = s.width / 18;
    if (!injectable) {
      // A capsule, half filled.
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 15 * u, height: 7 * u),
        Radius.circular(3.5 * u),
      );
      canvas.save();
      canvas.clipRRect(r);
      canvas.drawRect(
        Rect.fromLTRB(-7.5 * u, -3.5 * u, 0, 3.5 * u),
        Paint()..color = color,
      );
      canvas.restore();
      if (filled) {
        canvas.drawRRect(r, Paint()..color = color.withValues(alpha: 0.25));
      }
      canvas.drawRRect(r, stroke);
    } else {
      // A syringe: barrel, plunger and needle.
      final barrel = RRect.fromRectAndRadius(
        Rect.fromLTWH(-5 * u, -2.6 * u, 9 * u, 5.2 * u),
        Radius.circular(1.2 * u),
      );
      if (filled) canvas.drawRRect(barrel, Paint()..color = color);
      canvas.drawRRect(barrel, stroke);
      canvas.drawLine(Offset(-5 * u, 0), Offset(-8.5 * u, 0), stroke);
      canvas.drawLine(
        Offset(-8.5 * u, -2.4 * u),
        Offset(-8.5 * u, 2.4 * u),
        stroke,
      );
      canvas.drawLine(Offset(4 * u, 0), Offset(8.5 * u, 0), stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FormMark old) =>
      old.injectable != injectable ||
      old.color != color ||
      old.filled != filled;
}
