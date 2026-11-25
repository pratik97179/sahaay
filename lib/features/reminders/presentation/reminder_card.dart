import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../domain/reminder.dart';
import 'schedule_text.dart';

/// One reminder in a medicine's Reminders section
/// (`docs/design-system.md` §11.2): its time, how often it repeats, the
/// user's quantity and instruction, and whether it is paused.
class ReminderCard extends StatelessWidget {
  const ReminderCard({required this.reminder, super.key});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final schedule = reminder.schedule;
    final notes = [?reminder.quantity, ?reminder.instruction];
    return Card.filled(
      margin: EdgeInsets.only(bottom: spacing.itemSeparation),
      color: context.colors.surfaceContainer,
      shape: context.shapes.card,
      child: Padding(
        padding: EdgeInsets.all(spacing.itemInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatTime(context, schedule.time),
                    style: typography.primaryValue,
                  ),
                ),
                if (reminder.isPaused)
                  Text('Paused', style: typography.statusLabel),
              ],
            ),
            Text(
              describeSchedule(
                schedule,
                formatDate: (date) => formatDate(context, date),
              ),
              style: typography.supporting,
            ),
            for (final note in notes) Text(note, style: typography.metadata),
          ],
        ),
      ),
    );
  }
}
