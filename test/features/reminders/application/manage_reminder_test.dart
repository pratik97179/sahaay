import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/reminders/application/manage_reminder.dart';
import 'package:sahaay/features/reminders/application/reminder_draft.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';
import 'package:sahaay/features/reminders/domain/reminder.dart';
import 'package:sahaay/features/reminders/domain/reminder_schedule.dart';

import '../../../support/builders.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftMedicineRepository medicines;
  late DriftReminderRepository reminders;
  late ManageReminder manage;

  final morning = aReminder(
    id: 'morning',
    time: LocalTime(9, 0),
    quantity: '1 tablet',
  );
  final evening = aReminder(
    id: 'evening',
    time: LocalTime(21, 0),
    recurrence: WeeklyRecurrence(weekdays: {1, 4}),
    quantity: '2 tablets',
    instruction: 'After food',
  );

  setUp(() async {
    db = openTestDatabase();
    medicines = DriftMedicineRepository(db);
    reminders = DriftReminderRepository(db);
    manage = ManageReminder(reminders: reminders);
    await medicines.insert(aMedicine(id: 'm1'));
    await reminders.save(morning);
    await reminders.save(evening);
  });

  tearDown(() => db.close());

  void expectUnchanged(Reminder actual, Reminder expected) {
    expect(actual.schedule.time, expected.schedule.time);
    expect(actual.schedule.recurrence, expected.schedule.recurrence);
    expect(actual.schedule.startDate, expected.schedule.startDate);
    expect(actual.schedule.endDate, expected.schedule.endDate);
    expect(actual.quantity, expected.quantity);
    expect(actual.instruction, expected.instruction);
    expect(actual.isPaused, expected.isPaused);
  }

  group('update', () {
    test('replaces the schedule, quantity and instruction', () async {
      await manage.update(
        'morning',
        ReminderDetails(
          schedule: ReminderSchedule(
            time: LocalTime(8, 30),
            recurrence: DailyRecurrence(interval: 2),
            startDate: LocalDate(2026, 5, 1),
            endDate: LocalDate(2026, 6, 1),
          ),
          instruction: 'With water',
        ),
      );

      final updated = (await reminders.find('morning'))!;
      expect(updated.medicineId, 'm1');
      expect(updated.schedule.time, LocalTime(8, 30));
      expect(updated.schedule.recurrence, DailyRecurrence(interval: 2));
      expect(updated.schedule.endDate, LocalDate(2026, 6, 1));
      expect(updated.quantity, isNull);
      expect(updated.instruction, 'With water');
    });

    test('keeps a paused reminder paused', () async {
      await manage.setPaused('morning', paused: true);

      await manage.update(
        'morning',
        ReminderDetails(schedule: morning.schedule, quantity: '3'),
      );

      expect((await reminders.find('morning'))!.isPaused, isTrue);
    });

    test('leaves sibling reminders unchanged', () async {
      await manage.update(
        'morning',
        ReminderDetails(
          schedule: ReminderSchedule(
            time: LocalTime(7, 0),
            recurrence: DailyRecurrence(),
            startDate: LocalDate(2026, 5, 1),
          ),
        ),
      );

      expectUnchanged((await reminders.find('evening'))!, evening);
    });

    test('does nothing for a reminder that no longer exists', () async {
      await manage.update('gone', ReminderDetails(schedule: morning.schedule));

      expect(await reminders.find('gone'), isNull);
      expect(await reminders.findAll(), hasLength(2));
    });
  });

  group('pause and resume', () {
    test('pause stops only this reminder', () async {
      await manage.setPaused('morning', paused: true);

      expect((await reminders.find('morning'))!.isPaused, isTrue);
      expectUnchanged((await reminders.find('evening'))!, evening);
    });

    test('resume makes it active again and keeps its schedule', () async {
      await manage.setPaused('morning', paused: true);
      await manage.setPaused('morning', paused: false);

      expectUnchanged((await reminders.find('morning'))!, morning);
    });
  });

  group('delete', () {
    test('removes only this reminder, keeping medicine and siblings '
        '', () async {
      await manage.delete('morning');

      expect(await reminders.find('morning'), isNull);
      expect(await medicines.find('m1'), isNotNull);
      expectUnchanged((await reminders.find('evening'))!, evening);
    });

    test('keeps the medicine when its last reminder is deleted', () async {
      await manage.delete('morning');
      await manage.delete('evening');

      expect(await reminders.findForMedicine('m1'), isEmpty);
      expect(await medicines.find('m1'), isNotNull);
    });
  });
}
