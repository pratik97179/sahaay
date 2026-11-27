import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'day_light.dart';

/// A drawn bin with "delete" under it. Holding it (about a second) deletes
/// what it belongs to: a ring fills around the bin while held, and letting go
/// early rolls it back. A quick tap only says to hold.
class HoldToDelete extends StatefulWidget {
  const HoldToDelete({
    required this.light,
    required this.label,
    required this.hint,
    required this.onDelete,
    super.key,
  });
  final DayLight light;

  /// What screen readers say, such as "Delete Insulin".
  final String label;

  /// What deleting removes, for screen readers.
  final String hint;
  final VoidCallback onDelete;

  @override
  State<HoldToDelete> createState() => _HoldToDeleteState();
}

class _HoldToDeleteState extends State<HoldToDelete>
    with SingleTickerProviderStateMixin {
  late final _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    reverseDuration: const Duration(milliseconds: 250),
  )..addStatusListener(_done);
  bool _hint = false;

  void _done(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onDelete();
  }

  void _tapped() {
    setState(() => _hint = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.light.ink;
    return Semantics(
      button: true,
      label: widget.label,
      hint: widget.hint,
      excludeSemantics: true,
      onLongPress: widget.onDelete,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tapped,
        onLongPressStart: (_) => _hold.forward(),
        onLongPressEnd: (_) {
          if (!_hold.isCompleted) _hold.reverse();
        },
        onLongPressCancel: () {
          if (!_hold.isCompleted) _hold.reverse();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 12),
          child: Column(
            children: [
              SizedBox.square(
                dimension: 40,
                child: AnimatedBuilder(
                  animation: _hold,
                  builder: (context, _) => CustomPaint(
                    painter: _Bin(ink, Curves.easeIn.transform(_hold.value)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Both words keep their space, so the header never shifts.
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: _hint ? 0 : 1,
                    child: Text(
                      'delete',
                      style: figtree(13, FontWeight.w700, ink),
                    ),
                  ),
                  Opacity(
                    opacity: _hint ? 1 : 0,
                    child: Text(
                      'hold',
                      style: figtree(13, FontWeight.w700, ink),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A drawn bin with its lid; [held] (0–1) fills a ring around it and lifts
/// the lid as the hold goes on.
class _Bin extends CustomPainter {
  _Bin(this.ink, this.held);
  final Color ink;
  final double held;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.47;
    if (held > 0) {
      canvas.drawCircle(
        c,
        r,
        Paint()..color = ink.withValues(alpha: 0.08 * held),
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * held,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = ink,
      );
    }
    final u = s.width / 40;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;
    // The body, a little narrower at the bottom.
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 9 * u, c.dy - 6 * u)
        ..lineTo(c.dx - 7.5 * u, c.dy + 12 * u)
        ..lineTo(c.dx + 7.5 * u, c.dy + 12 * u)
        ..lineTo(c.dx + 9 * u, c.dy - 6 * u),
      line,
    );
    for (final x in [-3.5, 3.5]) {
      canvas.drawLine(
        Offset(c.dx + x * u, c.dy - 2 * u),
        Offset(c.dx + x * u, c.dy + 8 * u),
        line,
      );
    }
    // The lid, lifting as it is held.
    canvas.save();
    canvas.translate(c.dx, c.dy - 9 * u - 3 * u * held);
    canvas.rotate(-0.25 * held);
    canvas.drawLine(Offset(-11 * u, 0), Offset(11 * u, 0), line);
    canvas.drawLine(
      Offset(-3.5 * u, -3.5 * u),
      Offset(3.5 * u, -3.5 * u),
      line,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Bin old) => old.ink != ink || old.held != held;
}
