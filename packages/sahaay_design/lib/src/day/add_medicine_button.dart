import 'package:flutter/material.dart';

import 'day_light.dart';
import 'day_marks.dart';

/// A small drawn capsule and a tablet with a plus, with a word under it:
/// adds a medicine. Same size as Today's history and medicines buttons
/// (docs/design-system.md §3). In a header it says "add"; on its own, such
/// as on an empty Today, it says "add a medicine" and sits centred.
class AddMedicineButton extends StatelessWidget {
  const AddMedicineButton({
    required this.light,
    required this.onTap,
    this.label = 'add',
    this.padding = const EdgeInsets.fromLTRB(12, 6, 0, 12),
    super.key,
  });
  final DayLight light;
  final VoidCallback onTap;

  /// The word under the mark.
  final String label;

  /// Around the mark and word; part of what can be tapped. The default
  /// lines it up with the other header buttons.
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Add a medicine',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(painter: _AddPrint(light.ink)),
            ),
            const SizedBox(height: 4),
            Text(label, style: figtree(13, FontWeight.w700, light.ink)),
          ],
        ),
      ),
    ),
  );
}

class _AddPrint extends CustomPainter {
  _AddPrint(this.ink);
  final Color ink;
  @override
  void paint(Canvas canvas, Size s) {
    const paper = Paper.sheet;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;

    // A capsule, set at an angle: one half ink, one half cream.
    canvas.save();
    canvas.translate(s.width * 0.38, s.height * 0.36);
    canvas.rotate(-0.7);
    final w = s.width * 0.62, h = s.height * 0.27;
    final capsule = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular(h / 2),
    );
    canvas.drawRRect(capsule, Paint()..color = paper);
    canvas.save();
    canvas.clipRRect(capsule);
    canvas.drawRect(
      Rect.fromLTRB(-w / 2, -h / 2, 0, h / 2),
      Paint()..color = ink,
    );
    canvas.restore();
    canvas.drawRRect(capsule, stroke);
    canvas.restore();

    // A round tablet below it with a plus on it: add a medicine.
    final c = Offset(s.width * 0.72, s.height * 0.72);
    final r = s.width * 0.2;
    canvas.drawCircle(c, r, Paint()..color = ink);
    final arm = r * 0.5;
    final plus = Paint()
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = paper;
    canvas
      ..drawLine(c.translate(-arm, 0), c.translate(arm, 0), plus)
      ..drawLine(c.translate(0, -arm), c.translate(0, arm), plus);
  }

  @override
  bool shouldRepaint(_AddPrint old) => old.ink != ink;
}
