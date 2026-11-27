import '../domain/reminder_repository.dart';
import 'reminder_draft.dart';

/// Edits, pauses, resumes and deletes single reminders.
///
/// Every operation reads and writes only the reminder it is given, so the
/// medicine's other reminders are never touched.
final class ManageReminder {
  ManageReminder({required this._reminders});

  final ReminderRepository _reminders;

  /// Replaces the reminder's schedule, quantity and instruction. Whether it
  /// is paused is kept. Does nothing if the reminder no longer exists.
  Future<void> update(String id, ReminderDetails details) async {
    final reminder = await _reminders.find(id);
    if (reminder == null) return;
    await _reminders.save(
      reminder.copyWith(
        schedule: details.schedule,
        quantity: () => details.quantity,
        instruction: () => details.instruction,
      ),
    );
  }

  /// Pauses the reminder, or resumes it when [paused] is false. Does nothing
  /// if the reminder no longer exists.
  Future<void> setPaused(String id, {required bool paused}) async {
    final reminder = await _reminders.find(id);
    if (reminder == null || reminder.isPaused == paused) return;
    await _reminders.save(reminder.copyWith(isPaused: paused));
  }

  /// Deletes only this reminder; its medicine and sibling reminders stay.
  Future<void> delete(String id) => _reminders.delete(id);
}
