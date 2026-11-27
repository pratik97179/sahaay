import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../app/routes.dart';
import '../../../core/time/clock.dart';
import '../domain/calendar.dart';
import '../domain/reminder.dart';
import '../reminders_providers.dart';
import 'reminder_marks.dart';
import 'schedule_text.dart';

/// A medicine's reminders on its page (docs/design-system.md
/// §18.3): when in the day they are, then each one as a small print. Tapping
/// a print opens that reminder; the drawn clock with a plus adds one.
///
/// A medicine with no reminders says so.
class MedicineRemindersSection extends ConsumerWidget {
  const MedicineRemindersSection({required this.medicineId, super.key});

  final String medicineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = DayLight.screen;
    final now = LocalDateTime.fromDateTime(ref.watch(clockProvider)());
    final reminders = ref.watch(medicineRemindersProvider(medicineId));
    final list = [...?reminders.value]
      ..sort((a, b) => a.schedule.time.compareTo(b.schedule.time));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'reminders',
                style: figtree(
                  26,
                  FontWeight.w800,
                  light.ink,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Add a reminder',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(AppRoutes.newReminder(medicineId)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SizedBox.square(
                    dimension: 48,
                    child: CustomPaint(painter: AddTimeStamp(light.ink)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        switch (reminders) {
          AsyncData() when list.isEmpty => Text(
            'no reminders yet.',
            style: figtree(17, FontWeight.w500, light.soft),
          ),
          AsyncData() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: DayStrip(
                  ink: light.ink,
                  soft: light.soft,
                  background: light.page,
                  marks: [
                    for (final r in list)
                      (r.schedule.time.minutesSinceMidnight / 60, r.isPaused),
                  ],
                  now: now.time.minutesSinceMidnight / 60,
                ),
              ),
              const SizedBox(height: 18),
              for (final (i, r) in list.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Transform.rotate(
                    // Set down by hand, like the prints on the shelf.
                    angle: (i.isEven ? -1 : 1) * 0.012,
                    child: _ReminderPrint(
                      reminder: r,
                      onTap: () => context.push(AppRoutes.reminder(r.id)),
                    ),
                  ),
                ),
            ],
          ),
          AsyncError() => Text(
            "reminders couldn't be loaded.",
            style: figtree(17, FontWeight.w500, light.soft),
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// One reminder as a small print: the time, how often, the amount, and the
/// person's note pinned on as a little sticky note. A paused reminder is
/// faded and says so.
class _ReminderPrint extends StatelessWidget {
  const _ReminderPrint({required this.reminder, required this.onTap});
  final Reminder reminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = reminder.schedule.time;
    final amount = reminder.quantity?.trim() ?? '';
    final note = reminder.instruction?.trim() ?? '';
    final how = describeSchedule(
      reminder.schedule,
      formatDate: (d) => formatDate(context, d),
    ).toLowerCase();
    final time = clockText(context, t.hour, t.minute);
    return Semantics(
      button: true,
      label: [
        time,
        how,
        if (amount.isNotEmpty) amount,
        if (note.isNotEmpty) note,
        if (reminder.isPaused) 'paused',
      ].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: reminder.isPaused ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
            decoration: BoxDecoration(
              color: Paper.sheet,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: figtree(
                          28,
                          FontWeight.w800,
                          Paper.ink,
                          letterSpacing: -0.6,
                        ),
                      ),
                      Text(
                        reminder.isPaused ? '$how · paused' : how,
                        style: figtree(15, FontWeight.w600, Paper.soft),
                      ),
                      if (amount.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            amount,
                            style: figtree(15, FontWeight.w700, Paper.ink),
                          ),
                        ),
                    ],
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Transform.rotate(
                      angle: 0.04,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        decoration: BoxDecoration(
                          color: Paper.note,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(1, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          note,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: handwritten(19, Paper.noteInk, height: 1.15),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
