import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../design_system/design_system.dart';
import '../reminders_providers.dart';
import 'reminder_card.dart';

/// The Reminders section of a medicine's page (PRD §5.3).
///
/// A medicine with no reminders says so (PRD §3.1).
class MedicineRemindersSection extends ConsumerWidget {
  const MedicineRemindersSection({required this.medicineId, super.key});

  final String medicineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentSection(
      heading: 'Reminders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (ref.watch(medicineRemindersProvider(medicineId))) {
            AsyncData(value: final list) when list.isEmpty => const EmptyState(
              icon: Icons.notifications_none,
              message: 'No reminders.',
            ),
            AsyncData(value: final list) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final reminder in list)
                  ReminderCard.reminder(
                    reminder,
                    onTap: () => context.push(AppRoutes.reminder(reminder.id)),
                  ),
              ],
            ),
            AsyncError() => const ErrorState(
              message: "Reminders couldn't be loaded.",
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
          SizedBox(height: context.spacing.itemSeparation),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.newReminder(medicineId)),
            icon: const Icon(Icons.add_alarm_outlined),
            label: const Text('Add reminder'),
          ),
        ],
      ),
    );
  }
}
