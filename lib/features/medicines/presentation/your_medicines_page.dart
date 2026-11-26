import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/time/clock.dart';
import '../../day/presentation/day_widgets.dart';
import '../../reminders/domain/calendar.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/reminders_providers.dart';
import '../domain/medicine.dart';
import '../medicines_providers.dart';
import 'medicine_labels.dart';

/// The person's medicines as a shelf of prints (docs/design-system.md §18):
/// adding a medicine first, then each medicine as a rounded print showing
/// its photo, name and form, when in the day its reminders are, and what's
/// next.
class YourMedicinesPage extends ConsumerWidget {
  const YourMedicinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = screenLight;
    final now = LocalDateTime.fromDateTime(ref.watch(clockProvider)());
    final medicines = ref.watch(medicinesProvider).value ?? const [];
    final reminders = ref.watch(allRemindersProvider).value ?? const [];
    final photos = ref.read(medicinePhotoStorageProvider);
    final meds = [
      for (final m in medicines)
        _Med(m, FileImage(photos.resolve(m.photoPath)), [
          for (final r in reminders)
            if (r.medicineId == m.id) r,
        ]),
    ];

    return Scaffold(
      backgroundColor: light.page,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // Two prints a row on a phone; more when there is room.
            final columns = math.max(2, (box.maxWidth / 200).floor());
            final width =
                (box.maxWidth - 28 * 2 - 18 * (columns - 1)) / columns;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The add button sits level with the first line, exactly
                  // where Today's buttons sit, so it doesn't jump between
                  // screens.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).maybePop(),
                              child: Text(
                                '‹  today',
                                style: f(17, FontWeight.w700, light.soft),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'your medicines.',
                              style: f(44, FontWeight.w800, light.ink, ls: -1),
                            ),
                            Text(
                              meds.isEmpty
                                  ? 'add the first one with its photo.'
                                  : 'tap one to see its reminders.',
                              style: f(17, FontWeight.w500, light.soft),
                            ),
                          ],
                        ),
                      ),
                      AddMedicineButton(
                        light: light,
                        onTap: () => context.push(AppRoutes.addMedicine),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 18,
                    runSpacing: 26,
                    children: [
                      for (final (i, m) in meds.indexed)
                        SizedBox(
                          width: width,
                          child: Transform.rotate(
                            // Alternate a slight tilt, as if set down by hand.
                            angle: (i.isEven ? 1 : -1) * 0.022,
                            child: GestureDetector(
                              onTap: () => context.push(
                                AppRoutes.medicine(m.medicine.id),
                              ),
                              child: _MedicinePrint(med: m, now: now),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One medicine with what its print shows.
final class _Med {
  const _Med(this.medicine, this.photo, this.reminders);
  final Medicine medicine;
  final ImageProvider photo;
  final List<Reminder> reminders;
}

const _paper = Color(0xFFFBFAF6);
const _paperInk = Color(0xFF2A2622);
const _paperSoft = Color(0xFF6B6660);
const _paperRadius = 18.0;
const _photoRadius = 12.0;

/// A medicine as a rounded print: photo; name and form; a day strip with a
/// dot at each reminder's time; and what's next.
class _MedicinePrint extends StatelessWidget {
  const _MedicinePrint({required this.med, required this.now});
  final _Med med;
  final LocalDateTime now;

  @override
  Widget build(BuildContext context) {
    final rs = med.reminders;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_paperRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_photoRadius),
              child: Image(
                image: med.photo,
                fit: BoxFit.cover,
                semanticLabel: 'Photo of ${med.medicine.displayName}',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  med.medicine.displayName,
                  style: f(18, FontWeight.w800, _paperInk),
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                container: true,
                label: med.medicine.form == MedicineForm.injectable
                    ? 'Injectable'
                    : 'Oral',
                child: SizedBox.square(
                  dimension: MediaQuery.textScalerOf(context).scale(18),
                  child: CustomPaint(
                    painter: _FormMark(
                      injectable: med.medicine.form == MedicineForm.injectable,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rs.isNotEmpty) ...[
            ExcludeSemantics(
              child: _DayStrip(
                marks: [
                  for (final r in rs)
                    (r.schedule.time.minutesSinceMidnight / 60, r.isPaused),
                ],
                now: now.time.minutesSinceMidnight / 60,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(_next(context, rs), style: f(13, FontWeight.w600, _paperSoft)),
        ],
      ),
    );
  }

  /// What's next: the soonest notification of any active reminder.
  String _next(BuildContext context, List<Reminder> rs) {
    if (rs.isEmpty) return 'no reminders yet';
    if (rs.every((r) => r.isPaused)) return 'paused';
    final next = [for (final r in rs) ?r.nextNotification(now)]
      ..sort((a, b) => a.compareTo(b));
    if (next.isEmpty) return 'nothing coming up';
    final n = next.first;
    final time = clockText(context, n.time.hour, n.time.minute);
    final days = now.date.daysUntil(n.date);
    final when = days == 0
        ? 'today'
        : days == 1
        ? 'tomorrow'
        : days < 7
        ? _weekdays[n.date.weekday - 1]
        : '${n.date.day} ${_months[n.date.month - 1]}';
    return 'next · $when $time';
  }
}

/// A whole day on one line, midnight to midnight: quiet marks at 6 am, noon
/// and 6 pm, a faint tick at now, and a dot at each reminder's time (a ring
/// when paused).
class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.marks, required this.now});
  final List<(double, bool)> marks;
  final double now;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return SizedBox(
      height: 22 + scaler.scale(10) * 1.3,
      width: double.infinity,
      child: CustomPaint(painter: _DayStripPainter(marks, now, scaler)),
    );
  }
}

class _DayStripPainter extends CustomPainter {
  _DayStripPainter(this.marks, this.now, this.scaler);
  final List<(double, bool)> marks;
  final double now;
  final TextScaler scaler;

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
        ..color = _paperSoft.withValues(alpha: 0.35),
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
          ..color = _paperSoft.withValues(alpha: 0.5),
      );
      final tp = TextPainter(
        text: TextSpan(text: label, style: f(10, FontWeight.w700, _paperSoft)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      tp.paint(canvas, Offset(x(h) - tp.width / 2, lineY + 8));
    }
    canvas.drawLine(
      Offset(x(now), lineY - 7),
      Offset(x(now), lineY + 7),
      Paint()
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = _paperInk.withValues(alpha: 0.3),
    );
    for (final (h, paused) in marks) {
      final c = Offset(x(h), dotY);
      if (paused) {
        canvas.drawCircle(c, 4.2, Paint()..color = _paper);
        canvas.drawCircle(
          c,
          4.2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = _paperSoft,
        );
      } else {
        canvas.drawCircle(c, 4.6, Paint()..color = _paperInk);
      }
    }
  }

  @override
  bool shouldRepaint(_DayStripPainter old) =>
      old.marks != marks || old.now != now || old.scaler != scaler;
}

/// A small drawn mark for the medicine's form: a capsule for oral, a
/// syringe for injectable.
class _FormMark extends CustomPainter {
  _FormMark({required this.injectable});
  final bool injectable;

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _paperSoft;
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
        Paint()..color = _paperSoft,
      );
      canvas.restore();
      canvas.drawRRect(r, stroke);
    } else {
      // A syringe: barrel, plunger and needle.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-5 * u, -2.6 * u, 9 * u, 5.2 * u),
          Radius.circular(1.2 * u),
        ),
        stroke,
      );
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
  bool shouldRepaint(_FormMark old) => old.injectable != injectable;
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
