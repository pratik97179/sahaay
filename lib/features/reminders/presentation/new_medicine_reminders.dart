import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../medicines/domain/medicine.dart';
import '../../medicines/presentation/add_medicine_extras.dart';
import '../application/create_reminder.dart';
import '../application/reminder_draft.dart';
import '../domain/calendar.dart';
import 'when_step.dart';

/// Reminders entered while adding a medicine.
///
/// They are kept in memory until the medicine is saved, then saved with it
/// in the same transaction.
final class NewMedicineReminders implements AddMedicineExtras {
  NewMedicineReminders({required this._createReminder, required this._now})
    : _current = ValueNotifier(
        WhenDraft(draft: ReminderDraft.initial(_now().date)),
      ) {
    _current.addListener(_updateFilled);
  }

  final CreateReminder _createReminder;
  final LocalDateTime Function() _now;
  final ValueNotifier<WhenDraft> _current;
  final _filled = ValueNotifier(false);

  void _updateFilled() => _filled.value = drafts.isNotEmpty;

  /// The reminders entered so far: one per time of day, once a time is set.
  List<ReminderDetails> get drafts => _current.value.toDetails(_now());

  @override
  Widget buildSection(
    BuildContext context, {
    required bool enabled,
    required MedicineForm? form,
  }) => WhenStep(current: _current, enabled: enabled, form: form);

  @override
  ValueListenable<bool> get filled => _filled;

  @override
  Future<void> saveFor(String medicineId) async {
    for (final details in drafts) {
      await _createReminder(medicineId: medicineId, details: details);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _filled.dispose();
  }
}
