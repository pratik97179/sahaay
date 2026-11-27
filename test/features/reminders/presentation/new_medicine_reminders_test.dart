import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';
import 'package:sahaay/features/reminders/domain/reminder.dart';

import '../../../support/fakes.dart';
import '../../../support/test_app.dart';
import '../../../support/test_database.dart';

/// The "when?" step of adding a medicine (docs/design-system.md §18.3):
/// reminders are set on the step itself and saved with the medicine.
void main() {
  late AppDatabase db;
  late DriftReminderRepository reminders;

  setUp(() {
    db = openTestDatabase();
    reminders = DriftReminderRepository(db);
  });

  tearDown(() => db.close());

  Future<void> goToStep(WidgetTester tester, int step, String name) async {
    await tester.tap(find.bySemanticsLabel('Step $step of 5: $name'));
    await tester.pumpAndSettle();
  }

  /// Opens Add medicine, takes the photo, picks the form and moves to
  /// the "when?" step.
  Future<void> startAtWhen(WidgetTester tester) async {
    await pumpTestApp(tester, db: db, capture: FakePhotoCapture());
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Take its photo'));
    await tester.pumpAndSettle();
    await goToStep(tester, 3, 'how it’s taken');
    await tester.tap(find.text('oral'));
    await tester.pumpAndSettle();
    await goToStep(tester, 4, 'when');
  }

  /// Sets the first time: tapping the untouched ruler sets 9:00 am.
  Future<void> setFirstTime(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Time'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await goToStep(tester, 5, 'saved');
    expect(find.text('it’s saved.'), findsOneWidget);
  }

  Future<List<Reminder>> saved(WidgetTester tester) =>
      runDb(tester, () => reminders.findAll());

  testWidgets('adds no reminder when no time was set', (tester) async {
    await startAtWhen(tester);
    expect(find.text('slide the ruler to set a time'), findsOneWidget);

    await save(tester);

    expect(
      await runDb(tester, () => DriftMedicineRepository(db).watchAll().first),
      hasLength(1),
    );
    expect(await saved(tester), isEmpty);

    await disposeTestApp(tester);
  });

  testWidgets('saves one reminder for each time of day', (tester) async {
    await startAtWhen(tester);
    await setFirstTime(tester);
    expect(find.text('9:00 am'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Add another time of day'));
    await tester.pumpAndSettle();
    expect(find.text('1:00 pm'), findsOneWidget);
    // Nothing is saved before the last step.
    expect(await saved(tester), isEmpty);

    await save(tester);

    final medicine = (await runDb(
      tester,
      () => DriftMedicineRepository(db).watchAll().first,
    )).single;
    final all = await saved(tester);
    expect(all, hasLength(2));
    expect(all.every((r) => r.medicineId == medicine.id), isTrue);
    expect(
      all.map((r) => r.schedule.time),
      containsAll([LocalTime(9, 0), LocalTime(13, 0)]),
    );
    expect(
      all.every((r) => r.schedule.recurrence == DailyRecurrence()),
      isTrue,
    );

    await disposeTestApp(tester);
  });

  testWidgets('a removed time is not saved', (tester) async {
    await startAtWhen(tester);
    await setFirstTime(tester);
    await tester.tap(find.bySemanticsLabel('Add another time of day'));
    await tester.pumpAndSettle();

    // The new time is the one being set; its cross removes it.
    await tester.tap(find.bySemanticsLabel('Remove 1:00 pm'));
    await tester.pumpAndSettle();
    expect(find.text('1:00 pm'), findsNothing);

    await save(tester);

    expect((await saved(tester)).map((r) => r.schedule.time), [
      LocalTime(9, 0),
    ]);

    await disposeTestApp(tester);
  });

  testWidgets('saves a weekly reminder on the chosen days', (tester) async {
    await startAtWhen(tester);
    await setFirstTime(tester);
    // The last match: an invisible bold copy holds each word's width.
    await tester.tap(find.text('weekly').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Monday'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Thursday'));
    await tester.pumpAndSettle();

    await save(tester);

    expect(
      (await saved(tester)).single.schedule.recurrence,
      WeeklyRecurrence(weekdays: {1, 4}),
    );

    await disposeTestApp(tester);
  });

  testWidgets('saves every other day', (tester) async {
    await startAtWhen(tester);
    await setFirstTime(tester);
    await tester.tap(find.bySemanticsLabel('More days apart'));
    await tester.pumpAndSettle();
    expect(find.text('days'), findsOneWidget);

    await save(tester);

    expect(
      (await saved(tester)).single.schedule.recurrence,
      DailyRecurrence(interval: 2),
    );

    await disposeTestApp(tester);
  });

  testWidgets('saves what is written on the note', (tester) async {
    await startAtWhen(tester);
    await setFirstTime(tester);

    await tester.tap(find.bySemanticsLabel('Add a note'));
    await tester.pumpAndSettle();
    expect(find.text('note to self'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'After food');
    await tester.tap(find.bySemanticsLabel('Done'));
    await tester.pumpAndSettle();
    expect(find.text('After food'), findsOneWidget);

    await save(tester);

    expect((await saved(tester)).single.instruction, 'After food');

    await disposeTestApp(tester);
  });
}
