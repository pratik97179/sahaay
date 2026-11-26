import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/medicines/domain/medicine.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';

import '../../../support/builders.dart';
import '../../../support/test_app.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  final past = LocalDate(2026, 1, 1);

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  // The test clock is Tuesday 10 March 2026, 8:00 AM.
  Future<void> seed(WidgetTester tester) => runDb(tester, () async {
    final medicines = DriftMedicineRepository(db);
    final reminders = DriftReminderRepository(db);
    await medicines.insert(aMedicine(id: 'm1', name: 'Metformin'));
    await medicines.insert(
      aMedicine(id: 'm2', name: 'Insulin', form: MedicineForm.injectable),
    );
    await medicines.insert(aMedicine(id: 'm3', name: 'Calcium'));
    await medicines.insert(aMedicine(id: 'm4', name: 'Iron'));
    await reminders.save(
      aReminder(id: 'a', medicineId: 'm1', start: past, time: LocalTime(9, 0)),
    );
    await reminders.save(
      aReminder(id: 'b', medicineId: 'm1', start: past, time: LocalTime(21, 0)),
    );
    await reminders.save(
      aReminder(
        id: 'c',
        medicineId: 'm2',
        start: past,
        time: LocalTime(7, 30),
        recurrence: WeeklyRecurrence(weekdays: {4}),
      ),
    );
    await reminders.save(
      aReminder(id: 'd', medicineId: 'm3', start: past, paused: true),
    );
  });

  testWidgets('shows each medicine with what\'s next for it', (tester) async {
    await seed(tester);
    await pumpTestApp(tester, db: db);

    expect(find.text('your medicines.'), findsOneWidget);
    expect(find.text('next · today 9:00 am'), findsOneWidget);
    expect(find.text('next · Thu 7:30 am'), findsOneWidget);
    expect(find.text('paused'), findsOneWidget);
    expect(find.text('no reminders yet'), findsOneWidget);
    expect(find.bySemanticsLabel('Injectable'), findsOneWidget);
    expect(find.bySemanticsLabel('Oral'), findsNWidgets(3));

    await disposeTestApp(tester);
  });

  testWidgets('the add button opens Add medicine', (tester) async {
    await pumpTestApp(tester, db: db);

    expect(find.text('add the first one with its photo.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Add a medicine'));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('tapping a medicine opens it', (tester) async {
    await seed(tester);
    await pumpTestApp(tester, db: db);

    await tester.tap(find.text('Metformin'));
    await tester.pumpAndSettle();

    expect(find.text('Medicine information'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('fits at 200% text without overflowing', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await seed(tester);
    await pumpTestApp(tester, db: db);

    expect(tester.takeException(), isNull);

    await disposeTestApp(tester);
  });
}
