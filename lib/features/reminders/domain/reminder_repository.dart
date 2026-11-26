import 'reminder.dart';

/// Persistence contract for reminders.
abstract interface class ReminderRepository {
  /// Reminders of one medicine, ordered by time of day.
  Stream<List<Reminder>> watchForMedicine(String medicineId);

  Stream<Reminder?> watch(String id);

  /// Every reminder, ordered by time of day.
  Stream<List<Reminder>> watchAll();

  Future<Reminder?> find(String id);

  Future<List<Reminder>> findForMedicine(String medicineId);

  Future<List<Reminder>> findAll();

  /// Inserts or replaces a reminder. Only this reminder's row is written.
  Future<void> save(Reminder reminder);

  Future<void> delete(String id);
}
