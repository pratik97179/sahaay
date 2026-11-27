import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/prints/application/toggle_print.dart';
import 'package:sahaay/features/prints/data/drift_print_repository.dart';
import 'package:sahaay/features/prints/domain/print.dart';
import 'package:sahaay/features/prints/domain/print_rules.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';

import '../../support/builders.dart';
import '../../support/test_database.dart';

void main() {
  final today = LocalDate(2026, 3, 10);
  LocalDateTime at(int h, int m, [LocalDate? d]) =>
      LocalDateTime(d ?? today, LocalTime(h, m));
  final past = LocalDate(2026, 1, 1);

  group('canPrint', () {
    final nine = aReminder(start: past, time: LocalTime(9, 0));

    test('opens 30 minutes before the reminder\'s time', () {
      expect(canPrint(nine, today, at(8, 29)), isFalse);
      expect(canPrint(nine, today, at(8, 30)), isTrue);
      expect(canPrint(nine, today, at(15, 0)), isTrue);
    });

    test('a reminder on an earlier day can always be printed', () {
      expect(canPrint(nine, LocalDate(2026, 3, 9), at(6, 0)), isTrue);
    });

    test('a later day cannot be printed yet', () {
      expect(canPrint(nine, LocalDate(2026, 3, 11), at(23, 0)), isFalse);
    });

    test('a paused reminder cannot be printed', () {
      final paused = aReminder(start: past, paused: true);
      expect(canPrint(paused, today, at(23, 0)), isFalse);
      expect(canPrint(paused, LocalDate(2026, 3, 1), at(23, 0)), isFalse);
    });
  });

  group('prints in the database', () {
    late AppDatabase db;
    late DriftPrintRepository prints;
    late DriftReminderRepository reminders;
    late DriftMedicineRepository medicines;

    setUp(() async {
      db = openTestDatabase();
      prints = DriftPrintRepository(db);
      reminders = DriftReminderRepository(db);
      medicines = DriftMedicineRepository(db);
      await medicines.insert(aMedicine(id: 'm1'));
      await reminders.save(aReminder(id: 'r1', start: past));
      await reminders.save(aReminder(id: 'r2', start: past));
    });

    tearDown(() => db.close());

    test('keeps the time the print was made', () async {
      await prints.add(Print(reminderId: 'r1', day: today, madeAt: at(7, 42)));

      final saved = (await prints.find('r1', today))!;
      expect(saved.madeAt, at(7, 42));
      expect((await prints.watchDay(today).first).single.reminderId, 'r1');
    });

    test('lists a range of days, oldest first', () async {
      await prints.add(
        Print(reminderId: 'r1', day: LocalDate(2026, 3, 9), madeAt: at(9, 0)),
      );
      await prints.add(
        Print(reminderId: 'r1', day: LocalDate(2026, 2, 28), madeAt: at(9, 0)),
      );
      await prints.add(
        Print(reminderId: 'r2', day: LocalDate(2026, 3, 1), madeAt: at(9, 0)),
      );

      final march = await prints
          .watchBetween(LocalDate(2026, 3, 1), LocalDate(2026, 3, 31))
          .first;
      expect(march.map((p) => p.day), [
        LocalDate(2026, 3, 1),
        LocalDate(2026, 3, 9),
      ]);
    });

    test('deleting a reminder or its medicine removes its prints', () async {
      await prints.add(Print(reminderId: 'r1', day: today, madeAt: at(9, 0)));
      await prints.add(Print(reminderId: 'r2', day: today, madeAt: at(9, 0)));

      await reminders.delete('r1');
      expect(await prints.find('r1', today), isNull);
      expect(await prints.find('r2', today), isNotNull);

      await medicines.delete('m1');
      expect(await prints.find('r2', today), isNull);
    });

    test('toggling makes a print, and toggling again undoes it', () async {
      final toggle = TogglePrint(prints: prints, now: () => at(9, 5));
      final reminder = aReminder(id: 'r1', start: past);

      expect(await toggle(reminder, today), isTrue);
      expect((await prints.find('r1', today))!.madeAt, at(9, 5));
      expect(await toggle(reminder, today), isFalse);
      expect(await prints.find('r1', today), isNull);
    });

    test('toggling a reminder still to come makes no print', () async {
      final toggle = TogglePrint(prints: prints, now: () => at(6, 0));

      expect(await toggle(aReminder(id: 'r1', start: past), today), isFalse);
      expect(await prints.find('r1', today), isNull);
    });
  });
}
