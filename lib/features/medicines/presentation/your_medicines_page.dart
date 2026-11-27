import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../app/routes.dart';
import '../../../core/time/clock.dart';
import '../../reminders/domain/calendar.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/reminders_providers.dart';
import '../domain/medicine.dart';
import '../medicines_providers.dart';
import 'add_medicine_button.dart';
import 'medicine_labels.dart';

/// The person's medicines as a shelf of prints (docs/design-system.md §18):
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
                            GestureDetector(
                              onTap: () => Navigator.of(context).maybePop(),
                              child: Text(
                                '‹  today',
                                style: figtree(17, FontWeight.w700, light.soft),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'your medicines.',
                              style: figtree(
                                44,
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
