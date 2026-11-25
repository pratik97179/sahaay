import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'data/drift_reminder_repository.dart';
import 'domain/reminder.dart';
import 'domain/reminder_repository.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => DriftReminderRepository(ref.watch(appDatabaseProvider)),
);

/// The reminders of one medicine, ordered by time of day.
final medicineRemindersProvider = StreamProvider.autoDispose
    .family<List<Reminder>, String>(
      (ref, medicineId) =>
          ref.watch(reminderRepositoryProvider).watchForMedicine(medicineId),
    );
