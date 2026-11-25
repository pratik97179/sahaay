import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../design_system/design_system.dart';
import '../../medicines/presentation/add_medicine_extras.dart';
import '../application/create_reminder.dart';
import '../application/reminder_draft.dart';
import 'reminder_card.dart';

/// Reminders entered while adding a medicine (PRD §5.1, FR-01, FR-02).
///
/// They are kept in memory until the medicine is saved, then saved with it
/// in the same transaction.
final class NewMedicineReminders implements AddMedicineExtras {
  NewMedicineReminders({required this._createReminder});

  final CreateReminder _createReminder;
  final _drafts = ValueNotifier<List<ReminderDetails>>(const []);

  /// The reminders entered so far, ordered by time of day.
  List<ReminderDetails> get drafts => _drafts.value;

  @override
  Widget buildSection(BuildContext context, {required bool enabled}) =>
      _DraftRemindersSection(drafts: _drafts, enabled: enabled);

  @override
  Future<void> saveFor(String medicineId) async {
    for (final details in _drafts.value) {
      await _createReminder(medicineId: medicineId, details: details);
    }
  }

  @override
  void dispose() => _drafts.dispose();
}

class _DraftRemindersSection extends StatelessWidget {
  const _DraftRemindersSection({required this.drafts, required this.enabled});

  final ValueNotifier<List<ReminderDetails>> drafts;
  final bool enabled;

  Future<void> _add(BuildContext context) async {
    final added = await context.push<ReminderDetails>(
      AppRoutes.newMedicineReminder,
    );
    if (added != null) drafts.value = _byTime([...drafts.value, added]);
  }

  Future<void> _edit(BuildContext context, int index) async {
    final edited = await context.push<ReminderDetails>(
      AppRoutes.newMedicineReminder,
      extra: ReminderDraft.fromDetails(drafts.value[index]),
    );
    if (edited != null) {
      drafts.value = _byTime([...drafts.value]..[index] = edited);
    }
  }

  /// Ordered by time of day, like a saved medicine's reminders.
  static List<ReminderDetails> _byTime(List<ReminderDetails> list) =>
      list..sort((a, b) => a.schedule.time.compareTo(b.schedule.time));

  void _remove(int index) => drafts.value = [...drafts.value]..removeAt(index);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: drafts,
      builder: (context, list, _) => ContentSection(
        heading: 'Reminders',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (list.isEmpty)
              Padding(
                padding: EdgeInsets.only(
                  bottom: context.spacing.itemSeparation,
                ),
                child: Text(
                  "You can add reminders now, or later from the medicine's "
                  'page.',
                  style: context.typography.supporting,
                ),
              ),
            for (final (index, details) in list.indexed)
              ReminderCard(
                schedule: details.schedule,
                quantity: details.quantity,
                instruction: details.instruction,
                onTap: enabled ? () => _edit(context, index) : () {},
                trailing: IconButton(
                  onPressed: enabled ? () => _remove(index) : null,
                  tooltip: 'Remove reminder',
                  icon: const Icon(Icons.close),
                ),
              ),
            OutlinedButton.icon(
              onPressed: enabled ? () => _add(context) : null,
              icon: const Icon(Icons.add_alarm_outlined),
              label: const Text('Add reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
