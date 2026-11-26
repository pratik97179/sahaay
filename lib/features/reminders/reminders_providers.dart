import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database_provider.dart';
import 'application/create_reminder.dart';
import 'application/manage_reminder.dart';
import 'data/drift_reminder_repository.dart';
import 'domain/reminder.dart';
import 'domain/reminder_repository.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => DriftReminderRepository(ref.watch(appDatabaseProvider)),
);

final createReminderProvider = Provider<CreateReminder>(
  (ref) => CreateReminder(
    reminders: ref.watch(reminderRepositoryProvider),
    newId: const Uuid().v4,
  ),
);

final manageReminderProvider = Provider<ManageReminder>(
  (ref) => ManageReminder(reminders: ref.watch(reminderRepositoryProvider)),
);

/// One reminder, or `null` once it has been deleted.
final reminderProvider = StreamProvider.autoDispose.family<Reminder?, String>(
  (ref, id) => ref.watch(reminderRepositoryProvider).watch(id),
);

/// Every reminder, ordered by time of day.
final allRemindersProvider = StreamProvider.autoDispose<List<Reminder>>(
  (ref) => ref.watch(reminderRepositoryProvider).watchAll(),
);

/// The reminders of one medicine, ordered by time of day.
final medicineRemindersProvider = StreamProvider.autoDispose
    .family<List<Reminder>, String>(
      (ref, medicineId) =>
          ref.watch(reminderRepositoryProvider).watchForMedicine(medicineId),
    );
