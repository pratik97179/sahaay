import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/reminders/application/create_reminder.dart';
import 'package:sahaay/features/reminders/application/reminder_draft.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';
import 'package:sahaay/features/reminders/domain/reminder_schedule.dart';

import '../../../support/builders.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftReminderRepository reminders;
  late CreateReminder create;

  setUp(() async {
    db = openTestDatabase();
    reminders = DriftReminderRepository(db);
    await DriftMedicineRepository(db).insert(aMedicine(id: 'm1'));
    var next = 0;
    create = CreateReminder(reminders: reminders, newId: () => 'new-${++next}');
  });

  tearDown(() => db.close());

  test('saves an active reminder with the given details', () async {
    final schedule = ReminderSchedule(
      time: LocalTime(21, 0),
      recurrence: WeeklyRecurrence(weekdays: {1, 4}),
      startDate: LocalDate(2026, 3, 10),
      endDate: LocalDate(2026, 12, 31),
    );

    final id = await create(
      medicineId: 'm1',
      details: ReminderDetails(
        schedule: schedule,
        quantity: '2 tablets',
        instruction: 'After food',
      ),
    );

    final saved = (await reminders.find(id))!;
    expect(id, 'new-1');
    expect(saved.medicineId, 'm1');
    expect(saved.schedule.time, LocalTime(21, 0));
    expect(saved.schedule.recurrence, WeeklyRecurrence(weekdays: {1, 4}));
    expect(saved.schedule.endDate, LocalDate(2026, 12, 31));
    expect(saved.quantity, '2 tablets');
    expect(saved.instruction, 'After food');
    expect(saved.isPaused, isFalse);
  });

  test('leaves the medicine\'s other reminders unchanged', () async {
    final existing = aReminder(id: 'r1', quantity: '1 tablet');
    await reminders.save(existing);

    await create(
      medicineId: 'm1',
      details: ReminderDetails(
        schedule: ReminderSchedule(
          time: LocalTime(21, 0),
          recurrence: DailyRecurrence(),
          startDate: LocalDate(2026, 3, 10),
        ),
        quantity: '2 tablets',
      ),
    );

    final all = await reminders.findForMedicine('m1');
    expect(all, hasLength(2));
    final kept = all.singleWhere((r) => r.id == 'r1');
    expect(kept.quantity, '1 tablet');
    expect(kept.schedule.time, existing.schedule.time);
  });
}
