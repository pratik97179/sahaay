import '../domain/reminder.dart';
import '../domain/reminder_repository.dart';
import 'reminder_draft.dart';

/// Adds a reminder to an existing medicine (FR-02).
final class CreateReminder {
  CreateReminder({required this._reminders, required this._newId});

  final ReminderRepository _reminders;
  final String Function() _newId;

  /// Saves a new, active reminder and returns its id. Only this reminder is
  /// written; the medicine's other reminders are untouched.
  Future<String> call({
    required String medicineId,
    required ReminderDetails details,
  }) async {
    final reminder = Reminder(
      id: _newId(),
      medicineId: medicineId,
      schedule: details.schedule,
      quantity: details.quantity,
      instruction: details.instruction,
    );
    await _reminders.save(reminder);
    return reminder.id;
  }
}
