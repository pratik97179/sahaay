import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';
import 'package:sahaay/features/reminders/domain/reminder.dart';

import '../../../support/builders.dart';
import '../../../support/test_app.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftReminderRepository reminders;

  setUp(() {
    db = openTestDatabase();
    reminders = DriftReminderRepository(db);
  });

  tearDown(() => db.close());

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openNewReminder(
    WidgetTester tester, {
    List<Reminder> existing = const [],
  }) async {
    await runDb(
      tester,
      () => DriftMedicineRepository(db).insert(aMedicine(name: 'Paracetamol')),
    );
    for (final reminder in existing) {
      await runDb(tester, () => reminders.save(reminder));
    }
    await pumpTestApp(tester, db: db);
    await tester.tap(find.text('Paracetamol'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Add reminder'));
  }

  /// Opens the time picker and accepts its initial time, which is the test
  /// clock's 8:00 AM.
  Future<void> chooseTime(WidgetTester tester) async {
    await tapVisible(tester, find.text('Choose a time'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// Closes the keyboard, as the user would, then taps Save.
  Future<void> save(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Save reminder'));
  }

  Future<void> chooseRepeat(WidgetTester tester, String label) =>
      tapVisible(tester, find.widgetWithText(ChoiceChip, label));

  group('Add reminder', () {
    testWidgets('starts as daily, every day, from today, with no end date', (
      tester,
    ) async {
      await openNewReminder(tester);

      expect(find.text('For Paracetamol'), findsOneWidget);
      final daily = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Daily'),
      );
      expect(daily.selected, isTrue);
      expect(find.text('Repeat every'), findsOneWidget);
      expect(find.text('day'), findsOneWidget);
      expect(find.text('Choose a time'), findsOneWidget);
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('Tuesday, March 10, 2026'), findsOneWidget);
      expect(find.text('No end date'), findsOneWidget);

      await disposeTestApp(tester);
    });

    testWidgets('shows only the options of the chosen repeat type', (
      tester,
    ) async {
      await openNewReminder(tester);

      await chooseRepeat(tester, 'Once');
      expect(find.text('Repeat every'), findsNothing);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Start date'), findsNothing);
      expect(find.text('End date'), findsNothing);

      await chooseRepeat(tester, 'Weekly');
      expect(find.text('Repeat every'), findsOneWidget);
      expect(find.text('week'), findsOneWidget);
      expect(find.text('On these days'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('End date'), findsOneWidget);

      await chooseRepeat(tester, 'Monthly');
      expect(find.text('On these days'), findsNothing);
      expect(find.text('On these days of the month'), findsOneWidget);
      expect(find.text('month'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);

      await chooseRepeat(tester, 'Yearly');
      expect(find.text('Repeat every'), findsNothing);
      expect(find.text('On these days of the month'), findsNothing);
      expect(find.text('Date each year'), findsOneWidget);
      expect(find.text('End date'), findsOneWidget);

      await disposeTestApp(tester);
    });

    testWidgets('explains days that shorter months lack', (tester) async {
      await openNewReminder(tester);
      await chooseRepeat(tester, 'Monthly');

      await tapVisible(tester, find.text('31'));

      expect(
        find.text(
          'In months without the 31st, it is on the last day of the month.',
        ),
        findsOneWidget,
      );

      await disposeTestApp(tester);
    });

    testWidgets('says what is missing and saves nothing', (tester) async {
      await openNewReminder(tester);
      await chooseRepeat(tester, 'Weekly');

      await save(tester);

      expect(find.text('Choose a time.'), findsOneWidget);
      expect(find.text('Choose at least one day.'), findsOneWidget);
      expect(find.text('Add reminder'), findsWidgets);
      expect(await runDb(tester, () => reminders.findAll()), isEmpty);

      await disposeTestApp(tester);
    });

    testWidgets('rejects an interval of 0', (tester) async {
      await openNewReminder(tester);
      await chooseTime(tester);

      await tester.enterText(find.widgetWithText(TextField, '1'), '0');
      await save(tester);

      expect(find.text('Enter a number of 1 or more.'), findsOneWidget);
      expect(await runDb(tester, () => reminders.findAll()), isEmpty);

      await disposeTestApp(tester);
    });

    testWidgets('blocks a one-time reminder that is not in the future', (
      tester,
    ) async {
      await openNewReminder(tester);
      await chooseRepeat(tester, 'Once');
      // Today at 8:00 AM, which is the current minute.
      await chooseTime(tester);

      await save(tester);

      expect(
        find.text('Choose a date and time in the future.'),
        findsOneWidget,
      );
      expect(await runDb(tester, () => reminders.findAll()), isEmpty);

      await disposeTestApp(tester);
    });

    testWidgets('saves a daily reminder and lists it on the medicine', (
      tester,
    ) async {
      await openNewReminder(tester);
      await chooseTime(tester);
      await tester.enterText(find.widgetWithText(TextField, '1'), '2');
      await tester.pump();
      expect(find.text('days'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('Quantity'),
                matching: find.byType(Column),
              )
              .first,
          matching: find.byType(TextField),
        ),
        '1 tablet',
      );
      await tester.enterText(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('Instruction'),
                matching: find.byType(Column),
              )
              .first,
          matching: find.byType(TextField),
        ),
        'After food',
      );

      await save(tester);

      final saved = (await runDb(tester, () => reminders.findAll())).single;
      expect(saved.medicineId, 'm1');
      expect(saved.schedule.time, LocalTime(8, 0));
      expect(saved.schedule.recurrence, DailyRecurrence(interval: 2));
      expect(saved.schedule.startDate, LocalDate(2026, 3, 10));
      expect(saved.schedule.endDate, isNull);
      expect(saved.quantity, '1 tablet');
      expect(saved.instruction, 'After food');
      expect(saved.isPaused, isFalse);

      // Back on the medicine's page.
      expect(find.text('Medicine information'), findsOneWidget);
      expect(find.text('8:00 AM'), findsOneWidget);
      expect(find.text('Every 2 days'), findsOneWidget);
      expect(find.text('1 tablet'), findsOneWidget);
      expect(find.text('After food'), findsOneWidget);
      expect(find.text('No reminders.'), findsNothing);

      await disposeTestApp(tester);
    });

    testWidgets('saves a weekly reminder on the chosen days', (tester) async {
      await openNewReminder(tester);
      await chooseRepeat(tester, 'Weekly');
      await tapVisible(tester, find.text('Mon'));
      await tapVisible(tester, find.text('Thu'));
      await chooseTime(tester);

      await save(tester);

      final saved = (await runDb(tester, () => reminders.findAll())).single;
      expect(saved.schedule.recurrence, WeeklyRecurrence(weekdays: {1, 4}));
      expect(find.text('Every week on Monday and Thursday'), findsOneWidget);

      await disposeTestApp(tester);
    });

    testWidgets('keeps sibling reminders when another is added', (
      tester,
    ) async {
      await openNewReminder(
        tester,
        existing: [
          aReminder(id: 'evening', time: LocalTime(21, 0), quantity: '2'),
        ],
      );
      await chooseTime(tester);

      await save(tester);

      final all = await runDb(tester, () => reminders.findForMedicine('m1'));
      expect(all, hasLength(2));
      final evening = all.singleWhere((r) => r.id == 'evening');
      expect(evening.schedule.time, LocalTime(21, 0));
      expect(evening.quantity, '2');
      expect(find.text('8:00 AM'), findsOneWidget);
      expect(find.text('9:00 PM'), findsOneWidget);

      await disposeTestApp(tester);
    });
  });
}
