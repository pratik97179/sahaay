import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/time/clock.dart';
import '../../../design_system/design_system.dart';
import '../../medicines/medicines_providers.dart';
import '../../medicines/presentation/medicine_labels.dart';
import '../application/reminder_draft.dart';
import '../domain/calendar.dart';
import '../reminders_providers.dart';
import 'reminder_editor.dart';

/// Adds a reminder to an existing medicine (PRD §5.3, FR-02).
class NewReminderPage extends ConsumerWidget {
  const NewReminderPage({required this.medicineId, super.key});

  final String medicineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicine = ref.watch(medicineProvider(medicineId)).value;
    final today = LocalDate.fromDateTime(ref.read(clockProvider)());
    return PageLayout(
      heading: 'Add reminder',
      supportingText: medicine == null ? null : 'For ${medicine.displayName}',
      children: [
        ReminderEditor(
          initial: ReminderDraft.initial(today),
          submitLabel: 'Save reminder',
          onSubmit: (details) async {
            await ref.read(createReminderProvider)(
              medicineId: medicineId,
              details: details,
            );
            if (context.mounted) context.pop();
          },
        ),
      ],
    );
  }
}
