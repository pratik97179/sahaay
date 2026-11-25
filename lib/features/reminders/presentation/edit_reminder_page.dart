import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../medicines/medicines_providers.dart';
import '../../medicines/presentation/medicine_labels.dart';
import '../application/reminder_draft.dart';
import '../domain/reminder.dart';
import '../reminders_providers.dart';
import 'reminder_editor.dart';

/// Edits one reminder; its siblings are untouched (PRD §5.3, FR-06).
class EditReminderPage extends ConsumerWidget {
  const EditReminderPage({required this.reminderId, super.key});

  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(reminderProvider(reminderId))) {
      AsyncData(value: final Reminder reminder) => PageLayout(
        heading: 'Edit reminder',
        supportingText: switch (ref
            .watch(medicineProvider(reminder.medicineId))
            .value) {
          final medicine? => 'For ${medicine.displayName}',
          null => null,
        },
        children: [
          ReminderEditor(
            initial: ReminderDraft.fromReminder(reminder),
            submitLabel: 'Save changes',
            onSubmit: (details) async {
              await ref
                  .read(manageReminderProvider)
                  .update(reminderId, details);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      AsyncData() => const PageLayout(
        heading: 'Edit reminder',
        children: [EmptyState(message: 'This reminder no longer exists.')],
      ),
      AsyncError() => const PageLayout(
        heading: 'Edit reminder',
        children: [ErrorState(message: "This reminder couldn't be loaded.")],
      ),
      _ => const PageLayout(
        heading: 'Edit reminder',
        children: [Center(child: CircularProgressIndicator())],
      ),
    };
  }
}
