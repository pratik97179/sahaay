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

  final morning = aReminder(
    id: 'morning',
    time: LocalTime(9, 0),
    start: LocalDate(2026, 3, 1),
    quantity: '1 tablet',
    instruction: 'After food',
  );
  final evening = aReminder(
    id: 'evening',
    time: LocalTime(21, 0),
    recurrence: MonthlyRecurrence(days: {31}),
    end: LocalDate(2026, 12, 31),
    quantity: '2 tablets',
  );

  setUp(() {
    db = openTestDatabase();
    reminders = DriftReminderRepository(db);
  });

  tearDown(() => db.close());

  /// Scrolls the page until [finder] is built and visible, then taps it.
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

  /// Opens the medicine page, then the reminder shown at [time].
  Future<void> openReminder(
    WidgetTester tester,
    String time, {
    List<Reminder>? existing,
  }) async {
    await runDb(
      tester,
      () => DriftMedicineRepository(db).insert(aMedicine(name: 'Paracetamol')),
    );
    for (final reminder in existing ?? [morning, evening]) {
      await runDb(tester, () => reminders.save(reminder));
    }
    await pumpTestApp(tester, db: db);
    await tester.tap(find.text('Paracetamol'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(time));
  }

  Future<Reminder> stored(WidgetTester tester, String id) async =>
      (await runDb<Reminder?>(tester, () => reminders.find(id)))!;

  testWidgets('shows the medicine and the reminder details', (tester) async {
    await openReminder(tester, '9:00 PM');

    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.text('Reminder'), findsWidgets);
    expect(find.bySemanticsLabel('Photo of Paracetamol'), findsOneWidget);
    expect(find.text('Oral / edible'), findsOneWidget);
    expect(find.text('9:00 PM'), findsOneWidget);
    expect(find.text('Every month on the 31st'), findsOneWidget);
    expect(
      find.text(
        'In months without the 31st, it is on the last day of the month.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sunday, November 1, 2026'), findsOneWidget);
    expect(find.text('Thursday, December 31, 2026'), findsOneWidget);
    expect(find.text('2 tablets'), findsOneWidget);
    expect(find.text('Paused'), findsNothing);

    await disposeTestApp(tester);
  });

  testWidgets('shows a one-time reminder by its date, without repeats', (
    tester,
  ) async {
    await openReminder(
      tester,
      '9:00 AM',
      existing: [
        aReminder(
          id: 'once',
          recurrence: const OneTimeRecurrence(),
          start: LocalDate(2026, 3, 12),
        ),
      ],
    );

    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Thursday, March 12, 2026'), findsOneWidget);
    expect(find.text('Repeats'), findsNothing);
    expect(find.text('Ends'), findsNothing);

    await disposeTestApp(tester);
  });

  testWidgets('pauses and resumes only this reminder', (tester) async {
    await openReminder(tester, '9:00 AM');

    await tapVisible(tester, find.text('Pause reminder'));

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text("It won't notify until you resume it."), findsOneWidget);
    expect(find.text('Resume reminder'), findsOneWidget);
    expect((await stored(tester, 'morning')).isPaused, isTrue);
    expect((await stored(tester, 'evening')).isPaused, isFalse);

    await tapVisible(tester, find.text('Resume reminder'));

    expect(find.text('Paused'), findsNothing);
    expect(find.text('Pause reminder'), findsOneWidget);
    expect((await stored(tester, 'morning')).isPaused, isFalse);

    // The medicine page reflects the change too.
    await tapVisible(tester, find.text('Pause reminder'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Paused'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('edits only this reminder, starting from its details', (
    tester,
  ) async {
    await openReminder(tester, '9:00 AM');
    await tapVisible(tester, find.text('Pause reminder'));

    await tapVisible(tester, find.text('Edit reminder'));

    expect(find.text('Edit reminder'), findsWidgets);
    expect(find.text('For Paracetamol'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('Sunday, March 1, 2026'), findsOneWidget);
    expect(find.text('1 tablet'), findsOneWidget);
    expect(find.text('After food'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '1').first, '3');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Save changes'));

    // Back on the reminder screen, showing the change.
    expect(find.text('Every 3 days'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);

    final edited = await stored(tester, 'morning');
    expect(edited.schedule.recurrence, DailyRecurrence(interval: 3));
    expect(edited.quantity, '1 tablet');
    expect(edited.isPaused, isTrue, reason: 'editing keeps the pause');

    final sibling = await stored(tester, 'evening');
    expect(sibling.schedule.recurrence, MonthlyRecurrence(days: {31}));
    expect(sibling.quantity, '2 tablets');

    await disposeTestApp(tester);
  });

  testWidgets('deletes only this reminder after confirmation', (tester) async {
    await openReminder(tester, '9:00 AM');

    await tapVisible(tester, find.text('Delete reminder'));
    expect(find.text('Delete this reminder?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    // Back on the medicine page, with the sibling still there.
    expect(find.text('Medicine information'), findsOneWidget);
    expect(find.text('9:00 AM'), findsNothing);
    expect(find.text('9:00 PM'), findsOneWidget);
    expect(await runDb(tester, () => reminders.find('morning')), isNull);
    expect((await stored(tester, 'evening')).quantity, '2 tablets');

    await disposeTestApp(tester);
  });

  testWidgets('keeps the reminder when deletion is cancelled', (tester) async {
    await openReminder(tester, '9:00 AM');

    await tapVisible(tester, find.text('Delete reminder'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Pause reminder'), findsOneWidget);
    expect(await runDb(tester, () => reminders.find('morning')), isNotNull);

    await disposeTestApp(tester);
  });
}
