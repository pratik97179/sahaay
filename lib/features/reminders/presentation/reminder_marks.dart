import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';

/// A round ink stamp with a clock face and a plus at its shoulder.
class AddTimeStamp extends CustomPainter {
  AddTimeStamp(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero).translate(-2, 2);
    final r = s.width * 0.36;
    canvas.drawCircle(c, r, Paint()..color = ink);
    final hand = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = Paper.sheet;
    canvas.drawLine(c, c.translate(0, -r * 0.55), hand);
    canvas.drawLine(c, c.translate(r * 0.4, r * 0.22), hand);
    // The plus, on a paper ring that bites into the clock.
    final p = c.translate(r * 0.78, -r * 0.78);
    final pr = r * 0.5;
    canvas.drawCircle(p, pr + 2.5, Paint()..color = DayLight.screen.page);
    canvas.drawCircle(p, pr, Paint()..color = ink);
    final plus = Paint()
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = Paper.sheet;
    canvas.drawLine(p.translate(-pr * 0.5, 0), p.translate(pr * 0.5, 0), plus);
    canvas.drawLine(p.translate(0, -pr * 0.5), p.translate(0, pr * 0.5), plus);
  }

  @override
  bool shouldRepaint(AddTimeStamp old) => old.ink != ink;
}
