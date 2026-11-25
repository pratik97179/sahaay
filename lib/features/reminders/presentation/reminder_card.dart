import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../domain/reminder.dart';
import '../domain/reminder_schedule.dart';
import 'schedule_text.dart';

/// One reminder in a list (`docs/design-system.md` §11.2): its time, how often
/// it repeats, the user's quantity and instruction, and whether it is paused.
///
/// Tapping it calls [onTap]. Shows [trailing] in place of the chevron when
/// given, such as a remove button.
class ReminderCard extends StatelessWidget {
  const ReminderCard({
    required this.schedule,
    required this.onTap,
    this.quantity,
    this.instruction,
    this.isPaused = false,
    this.trailing,
    super.key,
  });

  /// A saved reminder.
  ReminderCard.reminder(Reminder reminder, {required this.onTap, super.key})
    : schedule = reminder.schedule,
      quantity = reminder.quantity,
      instruction = reminder.instruction,
      isPaused = reminder.isPaused,
      trailing = null;

  final ReminderSchedule schedule;
  final String? quantity;
  final String? instruction;
  final bool isPaused;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final notes = [
      for (final note in [quantity, instruction])
        if (note != null && note.trim().isNotEmpty) note.trim(),
    ];
    return Card.filled(
      margin: EdgeInsets.only(bottom: spacing.itemSeparation),
      color: context.colors.surfaceContainer,
      shape: context.shapes.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(spacing.itemInset),
          child: Row(
            children: [
              Expanded(
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
                        if (isPaused)
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
                    for (final note in notes)
                      Text(note, style: typography.metadata),
                  ],
                ),
              ),
              SizedBox(width: spacing.inlineSeparation),
              trailing ??
                  Icon(Icons.chevron_right, color: context.colors.contentQuiet),
            ],
          ),
        ),
      ),
    );
  }
}
