import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../domain/reminder.dart';
import '../reminders_providers.dart';

/// The Reminders section of a medicine's page (PRD §5.3).
///
/// A medicine with no reminders says so (PRD §3.1). Creating and managing
/// reminders is added with the reminder editor.
class MedicineRemindersSection extends ConsumerWidget {
  const MedicineRemindersSection({required this.medicineId, super.key});

  final String medicineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentSection(
      heading: 'Reminders',
      child: switch (ref.watch(medicineRemindersProvider(medicineId))) {
        AsyncData(value: final list) when list.isEmpty => const EmptyState(
          icon: Icons.notifications_none,
          message: 'No reminders.',
        ),
        AsyncData(value: final list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final reminder in list) _ReminderItem(reminder)],
        ),
        AsyncError() => const ErrorState(
          message: "Reminders couldn't be loaded.",
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReminderItem extends StatelessWidget {
  const _ReminderItem(this.reminder);

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final time = reminder.schedule.time;
    final label = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: time.hour, minute: time.minute));
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.itemSeparation),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.typography.primaryValue)),
          if (reminder.isPaused)
            Text('Paused', style: context.typography.statusLabel),
        ],
      ),
    );
  }
}
