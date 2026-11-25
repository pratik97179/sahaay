import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/core/database/transaction_runner.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';

import '../../../support/builders.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftMedicineRepository medicines;
  late DriftReminderRepository reminders;
  var tick = 0;
  DateTime clock() => DateTime.utc(2026, 11, 25).add(Duration(seconds: tick++));

  setUp(() async {
    db = openTestDatabase();
    medicines = DriftMedicineRepository(db, clock: clock);
    reminders = DriftReminderRepository(db, clock: clock);
    await medicines.insert(aMedicine());
  });

  tearDown(() => db.close());

  test('round-trips every recurrence type with all fields', () async {
    final all = [
      aReminder(id: 'once', recurrence: const OneTimeRecurrence()),
      aReminder(id: 'daily', recurrence: DailyRecurrence(interval: 15)),
      aReminder(
        id: 'weekly',
        recurrence: WeeklyRecurrence(weekdays: {4, 1}, interval: 2),
        end: LocalDate(2027, 1, 31),
      ),
      aReminder(
        id: 'monthly',
        recurrence: MonthlyRecurrence(days: {31, 1}, interval: 3),
      ),
      aReminder(
        id: 'yearly',
        recurrence: YearlyRecurrence(month: 2, day: 29),
        quantity: '2 tablets',
        instruction: 'After food',
        paused: true,
      ),
    ];
    for (final r in all) {
      await reminders.save(r);
    }

    for (final expected in all) {
      final actual = (await reminders.find(expected.id))!;
      expect(actual.schedule.recurrence, expected.schedule.recurrence);
      expect(actual.schedule.time, expected.schedule.time);
      expect(actual.schedule.startDate, expected.schedule.startDate);
      expect(actual.schedule.endDate, expected.schedule.endDate);
      expect(actual.quantity, expected.quantity);
      expect(actual.instruction, expected.instruction);
      expect(actual.isPaused, expected.isPaused);
    }
  });

  test('orders a medicine\'s reminders by time of day', () async {
    await reminders.save(aReminder(id: 'evening', time: LocalTime(21, 0)));
    await reminders.save(aReminder(id: 'morning', time: LocalTime(9, 0)));

    final list = await reminders.findForMedicine('m1');
    expect(list.map((r) => r.id), ['morning', 'evening']);
  });

  test(
    'updating, pausing or deleting one reminder leaves siblings intact',
    () async {
      await reminders.save(aReminder(id: 'a', quantity: '1 tablet'));
      await reminders.save(aReminder(id: 'b', quantity: '2 tablets'));

      final a = (await reminders.find('a'))!;
      await reminders.save(
        a.copyWith(isPaused: true, quantity: () => 'half tablet'),
      );
      final b = (await reminders.find('b'))!;
      expect(b.quantity, '2 tablets');
      expect(b.isPaused, isFalse);

      await reminders.delete('a');
      expect(await reminders.find('a'), isNull);
      expect(await reminders.find('b'), isNotNull);
      expect(await medicines.find('m1'), isNotNull);
    },
  );

  test('resuming a paused reminder persists', () async {
    await reminders.save(aReminder(paused: true));
    await reminders.save(
      (await reminders.find('r1'))!.copyWith(isPaused: false),
    );
    expect((await reminders.find('r1'))!.isPaused, isFalse);
  });

  test('a reminder cannot move to another medicine', () async {
    await medicines.insert(aMedicine(id: 'm2', photo: 'm2.jpg'));
    await reminders.save(aReminder());
    expect(() => reminders.save(aReminder(medicineId: 'm2')), throwsStateError);
  });

  test('a reminder requires an existing medicine', () async {
    expect(
      () => reminders.save(aReminder(medicineId: 'missing')),
      throwsA(isA<SqliteException>()),
    );
  });

  test('deleting a medicine deletes all of its reminders only', () async {
    await medicines.insert(aMedicine(id: 'm2', photo: 'm2.jpg'));
    await reminders.save(aReminder(id: 'a'));
    await reminders.save(aReminder(id: 'b'));
    await reminders.save(aReminder(id: 'c', medicineId: 'm2'));

    await medicines.delete('m1');

    expect(await reminders.findForMedicine('m1'), isEmpty);
    expect((await reminders.findAll()).map((r) => r.id), ['c']);
  });

  test('a failed transaction leaves nothing behind', () async {
    final tx = DriftTransactionRunner(db);
    await expectLater(
      tx.run(() async {
        await medicines.insert(aMedicine(id: 'm2', photo: 'm2.jpg'));
        await reminders.save(aReminder(id: 'x', medicineId: 'm2'));
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(await medicines.find('m2'), isNull);
    expect(await reminders.find('x'), isNull);
  });

  test('data survives closing and reopening the database file', () async {
    final dir = await Directory.systemTemp.createTemp('sahaay_db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    final first = openTestDatabase(NativeDatabase(file));
    await DriftMedicineRepository(first).insert(aMedicine());
    await DriftReminderRepository(first).save(aReminder(quantity: '1 tablet'));
    await first.close();

    final second = openTestDatabase(NativeDatabase(file));
    addTearDown(second.close);
    expect(await DriftMedicineRepository(second).find('m1'), isNotNull);
    expect(
      (await DriftReminderRepository(second).find('r1'))!.quantity,
      '1 tablet',
    );
  });
}
