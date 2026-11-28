import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../core/navigation/navigation.dart';
import '../../../core/time/clock.dart';
import '../../reminders/domain/calendar.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/reminders_providers.dart';
import '../domain/medicine.dart';
import '../medicines_destinations.dart';
import '../medicines_providers.dart';
import 'medicine_labels.dart';

/// The person's medicines as a shelf of prints (docs/design-system.md §3):
/// adding a medicine first, then each medicine as a rounded print showing
/// its photo, name and form, when in the day its reminders are, and what's
/// next.
class YourMedicinesPage extends ConsumerWidget {
  const YourMedicinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = DayLight.screen;
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
                            const BackLink('today'),
                            const SizedBox(height: 10),
                            Text(
                              'your medicines.',
                              style: figtree(
                                40,
                                FontWeight.w800,
                                light.ink,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              meds.isEmpty
                                  ? 'add the first one with its photo.'
                                  : 'tap one to see its reminders.',
                              style: figtree(17, FontWeight.w500, light.soft),
                            ),
                          ],
                        ),
                      ),
                      AddMedicineButton(
                        light: light,
                        onTap: () =>
                            AppNavigator.of(context)
                                .open(const AddMedicineDestination()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 18,
                    runSpacing: 26,
                    children: [
                      if (meds.isEmpty)
                        SizedBox(
                          width: width,
                          child: Transform.rotate(
                            angle: 0.022,
                            child: _EmptyPrint(
                              light: light,
                              onTap: () =>
                                  AppNavigator.of(context)
                                      .open(const AddMedicineDestination()),
                            ),
                          ),
                        ),
                      for (final (i, m) in meds.indexed)
                        SizedBox(
                          width: width,
                          child: Transform.rotate(
                            // Alternate a slight tilt, as if set down by hand.
                            angle: (i.isEven ? 1 : -1) * 0.022,
                            child: GestureDetector(
                              onTap: () =>
                                  AppNavigator.of(context)
                                      .open(MedicineDestination(m.medicine.id)),
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

/// The first slot on an empty shelf: a blank print with a dashed edge, a
/// camera where the photo goes and a scribble where the name goes. Tapping
/// it adds a medicine.
class _EmptyPrint extends StatelessWidget {
  const _EmptyPrint({required this.light, required this.onTap});
  final DayLight light;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    return Semantics(
      button: true,
      label: 'Add a medicine',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: DashedFrame(light.soft, _paperRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: light.soft.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(_photoRadius),
                    ),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 40,
                        child: CustomPaint(painter: CameraMark(light.soft)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: scale.scale(22),
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _Scribble(light.soft.withValues(alpha: 0.5), 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: scale.scale(16),
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _Scribble(light.soft.withValues(alpha: 0.3), 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One loose handwritten line across [reach] of the width: something goes
/// here.
class _Scribble extends CustomPainter {
  _Scribble(this.color, this.reach);
  final Color color;
  final double reach;
  @override
  void paint(Canvas canvas, Size s) {
    final y = s.height / 2;
    final path = Path()..moveTo(0, y);
    for (var x = 0.0; x <= s.width * reach; x += 2) {
      path.lineTo(x, y + math.sin(x / 2.6) * 1.8);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Scribble old) => old.color != color || old.reach != reach;
}

/// One medicine with what its print shows.
final class _Med {
  const _Med(this.medicine, this.photo, this.reminders);
  final Medicine medicine;
  final ImageProvider photo;
  final List<Reminder> reminders;
}

const _paper = Paper.sheet;
const _paperInk = Paper.ink;
const _paperSoft = Paper.soft;
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
                  style: figtree(18, FontWeight.w800, _paperInk),
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
                    painter: FormMark(
                      injectable: med.medicine.form == MedicineForm.injectable,
                      color: _paperSoft,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rs.isNotEmpty) ...[
            ExcludeSemantics(
              child: DayStrip(
                ink: _paperInk,
                soft: _paperSoft,
                background: _paper,
                marks: [
                  for (final r in rs)
                    (r.schedule.time.minutesSinceMidnight / 60, r.isPaused),
                ],
                now: now.time.minutesSinceMidnight / 60,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            _next(context, rs),
            style: figtree(13, FontWeight.w600, _paperSoft),
          ),
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
