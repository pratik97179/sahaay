import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';
import 'package:sahaay/features/reminders/domain/reminder.dart';

import '../../../support/fakes.dart';
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

  /// Scrolls the current page until [finder] is built and visible, then taps.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Opens Add medicine and fills in the required photo and form.
  Future<void> startAddingMedicine(WidgetTester tester) async {
    await pumpTestApp(tester, db: db, capture: FakePhotoCapture());
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Paracetamol');
    await tapVisible(tester, find.text('Take photo'));
    await tapVisible(tester, find.text('Oral / edible'));
  }

  /// From the Add medicine form, enters a reminder at the test clock's
  /// 8:00 AM, letting [configure] change other options first.
  Future<void> addDraftReminder(
    WidgetTester tester, {
    Future<void> Function()? configure,
  }) async {
    await tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, 'Add reminder'),
    );
    expect(find.text('For the new medicine'), findsOneWidget);
    await configure?.call();
    await tapVisible(tester, find.text('Choose a time'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add reminder'));
  }

  Future<List<Reminder>> saved(WidgetTester tester) =>
      runDb(tester, () => reminders.findAll());

  testWidgets('saves the medicine with the reminders entered for it', (
    tester,
  ) async {
    await startAddingMedicine(tester);
    expect(
      find.text(
        "You can add reminders now, or later from the medicine's page.",
      ),
      findsOneWidget,
    );

    await addDraftReminder(tester);
    await addDraftReminder(
      tester,
      configure: () async {
        await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Weekly'));
        await tapVisible(tester, find.text('Mon'));
        await tapVisible(tester, find.text('Thu'));
      },
    );

    // Back on the form: both drafts are listed, nothing is saved yet.
    expect(find.text('Every day'), findsOneWidget);
    expect(find.text('Every week on Monday and Thursday'), findsOneWidget);
    expect(await saved(tester), isEmpty);

    await tapVisible(tester, find.text('Save medicine'));

    final medicine = (await runDb(
      tester,
      () => DriftMedicineRepository(db).watchAll().first,
    )).single;
    final all = await saved(tester);
    expect(all, hasLength(2));
    expect(all.every((r) => r.medicineId == medicine.id), isTrue);
    expect(
      all.map((r) => r.schedule.recurrence),
      containsAll([
        DailyRecurrence(),
        WeeklyRecurrence(weekdays: {1, 4}),
      ]),
    );
    expect(all.every((r) => !r.isPaused), isTrue);

    // The new medicine's page lists them.
    expect(find.text('Medicine information'), findsOneWidget);
    expect(find.text('Every day'), findsOneWidget);
    expect(find.text('Every week on Monday and Thursday'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('edits a draft reminder before the medicine is saved', (
    tester,
  ) async {
    await startAddingMedicine(tester);
    await addDraftReminder(tester);

    await tapVisible(tester, find.text('Every day'));
    expect(find.text('Edit reminder'), findsOneWidget);
    expect(find.text('8:00 AM'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '1').first, '3');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Save changes'));

    expect(find.text('Every 3 days'), findsOneWidget);
    expect(find.text('Every day'), findsNothing);

    await tapVisible(tester, find.text('Save medicine'));

    expect(
      (await saved(tester)).single.schedule.recurrence,
      DailyRecurrence(interval: 3),
    );

    await disposeTestApp(tester);
  });

  testWidgets('removes a draft reminder so it is not saved', (tester) async {
    await startAddingMedicine(tester);
    await addDraftReminder(tester);

    await tapVisible(tester, find.byTooltip('Remove reminder'));

    expect(find.text('Every day'), findsNothing);
    await tapVisible(tester, find.text('Save medicine'));

    expect(find.text('Medicine information'), findsOneWidget);
    expect(find.text('No reminders.'), findsOneWidget);
    expect(await saved(tester), isEmpty);

    await disposeTestApp(tester);
  });

  testWidgets('discards a draft when its editor is closed without adding', (
    tester,
  ) async {
    await startAddingMedicine(tester);

    await tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, 'Add reminder'),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      find.text(
        "You can add reminders now, or later from the medicine's page.",
      ),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNothing);

    await disposeTestApp(tester);
  });

  testWidgets('keeps draft reminders when the medicine form is incomplete', (
    tester,
  ) async {
    await pumpTestApp(tester, db: db, capture: FakePhotoCapture());
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    await addDraftReminder(tester);

    await tapVisible(tester, find.text('Save medicine'));

    expect(find.text('Take a photo of the medicine.'), findsOneWidget);
    expect(find.text('Every day'), findsOneWidget);
    expect(await saved(tester), isEmpty);

    await disposeTestApp(tester);
  });
}
