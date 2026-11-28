import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/day/day_destinations.dart';
import 'package:sahaay/features/day/presentation/day_widgets.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/prints/data/drift_print_repository.dart';
import 'package:sahaay/features/prints/domain/print.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';

import '../../support/builders.dart';
import '../../support/test_app.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftPrintRepository prints;
  final past = LocalDate(2026, 1, 1);
  final today = LocalDate(2026, 3, 10); // the test clock: Tuesday, 8:00 AM

  setUp(() {
    db = openTestDatabase();
    prints = DriftPrintRepository(db);
  });
  tearDown(() => db.close());

  Future<void> seed(WidgetTester tester) => runDb(tester, () async {
    final medicines = DriftMedicineRepository(db);
    final reminders = DriftReminderRepository(db);
    await medicines.insert(aMedicine(id: 'm1', name: 'Paracetamol'));
    await medicines.insert(aMedicine(id: 'm2', name: 'Vitamin D'));
    await reminders.save(
      aReminder(
        id: 'early',
        start: past,
        time: LocalTime(7, 30),
        quantity: '2 tablets',
        instruction: 'after food',
      ),
    );
    await reminders.save(
      aReminder(
        id: 'noon',
        medicineId: 'm2',
        start: past,
        time: LocalTime(13, 0),
      ),
    );
    await reminders.save(
      aReminder(id: 'night', start: past, time: LocalTime(21, 0), paused: true),
    );
  });

  Future<void> openToday(WidgetTester tester) async {
    await seed(tester);
    await pumpTestApp(tester, db: db, start: const TodayDestination());
  }

  Future<void> swipeRuler(WidgetTester tester, double dx) async {
    await tester.ensureVisible(find.byKey(const ValueKey('ruler')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('ruler')), Offset(dx, 0));
    await tester.pumpAndSettle();
  }

  Future<void> holdPhoto(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(HoldPhoto));
    await tester.pumpAndSettle();
    final g = await tester.startGesture(
      tester.getCenter(find.byType(HoldPhoto)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 1000));
    await g.up();
    await tester.pumpAndSettle();
  }

  testWidgets('Today opens on the next reminder still to come', (tester) async {
    await openToday(tester);

    expect(find.text('Tuesday, 10 March'), findsOneWidget);
    expect(find.text('good morning.'), findsOneWidget);
    expect(find.text('1:00 pm'), findsOneWidget);
    expect(find.text('Vitamin D  ·  next'), findsOneWidget);
    expect(find.text('history'), findsOneWidget);
    expect(
      find.text('swipe the ruler  ·  tap the photo to open'),
      findsOneWidget,
    );

    await disposeTestApp(tester);
  });

  testWidgets('swiping steps between reminders only', (tester) async {
    await openToday(tester);

    await swipeRuler(tester, 150);
    expect(find.text('7:30 am'), findsOneWidget);
    expect(find.text('Paracetamol  ·  earlier today'), findsOneWidget);
    expect(find.text('2 tablets, after food'), findsOneWidget);

    await swipeRuler(tester, -150);
    await swipeRuler(tester, -150);
    expect(find.text('9:00 pm'), findsOneWidget);
    expect(find.text('Paused, won’t notify'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets(
    'holding a due reminder\'s photo prints it; holding again undoes it',
    (tester) async {
      await openToday(tester);
      await swipeRuler(tester, 150); // 7:30 am, already due

      expect(find.text('hold the photo to mark it taken'), findsOneWidget);
      await holdPhoto(tester);

      expect(find.text('taken at 8:00 am  ·  hold to undo'), findsOneWidget);
      expect(await runDb(tester, () => prints.find('early', today)), isNotNull);

      await holdPhoto(tester);
      expect(find.text('hold the photo to mark it taken'), findsOneWidget);
      expect(await runDb(tester, () => prints.find('early', today)), isNull);

      await disposeTestApp(tester);
    },
  );

  testWidgets('a reminder still to come cannot be printed', (tester) async {
    await openToday(tester); // opens on 1:00 pm

    await holdPhoto(tester);

    expect(await runDb(tester, () => prints.find('noon', today)), isNull);
    expect(find.text('hold the photo to mark it taken'), findsNothing);

    await disposeTestApp(tester);
  });

  testWidgets('tapping the photo opens the reminder', (tester) async {
    await openToday(tester);

    await tester.ensureVisible(find.byType(HoldPhoto));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(HoldPhoto));
    await tester.pumpAndSettle();

    expect(find.text('swipe down to go back'), findsOneWidget);
    expect(find.text('1:00 pm.'), findsOneWidget);
    expect(find.text('every day'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('History shows the month\'s printed days, without totals', (
    tester,
  ) async {
    await seed(tester);
    await runDb(tester, () async {
      for (final id in ['early', 'noon']) {
        await prints.add(
          Print(
            reminderId: id,
            day: LocalDate(2026, 3, 9),
            madeAt: LocalDateTime(LocalDate(2026, 3, 9), LocalTime(9, 0)),
          ),
        );
      }
    });
    await pumpTestApp(tester, db: db, start: const TodayDestination());

    await tester.tap(find.text('history'));
    await tester.pumpAndSettle();

    expect(find.text('march.'), findsOneWidget);
    expect(find.text('your prints, day by day.'), findsOneWidget);
    expect(find.text('Mar 9'), findsOneWidget);
    expect(find.text('2 prints'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('an empty day says so and leads to adding a medicine', (
    tester,
  ) async {
    await pumpTestApp(tester, db: db, start: const TodayDestination());

    expect(find.text('nothing for today.'), findsOneWidget);
    await tester.tap(find.text('add a medicine'));
    await tester.pumpAndSettle();
    expect(find.text('your medicines.'), findsOneWidget);
    expect(find.text('add the first one with its photo.'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('fits at 200% text without overflowing', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openToday(tester);

    expect(tester.takeException(), isNull);

    await disposeTestApp(tester);
  });
}
