import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/medicines/domain/medicine.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';

import '../../../support/builders.dart';
import '../../../support/fakes.dart';
import '../../../support/test_app.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftMedicineRepository medicines;
  late DriftReminderRepository reminders;
  late FakePhotoStorage photos;

  setUp(() {
    db = openTestDatabase();
    medicines = DriftMedicineRepository(db);
    reminders = DriftReminderRepository(db);
    photos = FakePhotoStorage();
  });

  tearDown(() => db.close());

  Future<void> openAddMedicine(
    WidgetTester tester, {
    FakePhotoCapture? camera,
  }) async {
    await pumpTestApp(tester, db: db, photos: photos, capture: camera);
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteMedicine(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Delete medicine'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete medicine'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Save medicine'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save medicine'));
    await tester.pumpAndSettle();
  }

  group('Medicines list', () {
    testWidgets('shows each medicine with its name or a generic label', (
      tester,
    ) async {
      await runDb(
        tester,
        () => medicines.insert(aMedicine(id: 'a', name: 'Paracetamol')),
      );
      await runDb(
        tester,
        () => medicines.insert(
          aMedicine(id: 'b', name: null, form: MedicineForm.injectable),
        ),
      );

      await pumpTestApp(tester, db: db, photos: photos);

      expect(find.text('Paracetamol'), findsOneWidget);
      expect(find.text('Unnamed medicine'), findsOneWidget);
      expect(find.bySemanticsLabel('Oral'), findsOneWidget);
      expect(find.bySemanticsLabel('Injectable'), findsOneWidget);
      expect(find.text('add the first one with its photo.'), findsNothing);

      await disposeTestApp(tester);
    });

    testWidgets('opens a medicine when tapped', (tester) async {
      await runDb(
        tester,
        () => medicines.insert(aMedicine(name: 'Paracetamol')),
      );
      await pumpTestApp(tester, db: db, photos: photos);

      await tester.tap(find.text('Paracetamol'));
      await tester.pumpAndSettle();

      expect(find.text('Medicine information'), findsOneWidget);
      expect(find.text('No reminders.'), findsOneWidget);

      await disposeTestApp(tester);
    });
  });

  group('Add medicine', () {
    testWidgets('requires a photo and a form before saving', (tester) async {
      await openAddMedicine(tester);

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);

      await tapSave(tester);

      expect(find.text('Take a photo of the medicine.'), findsOneWidget);
      expect(find.text('Choose the medicine form.'), findsOneWidget);
      expect(await runDb(tester, () => medicines.watchAll().first), isEmpty);

      await disposeTestApp(tester);
    });

    testWidgets('saves name, photo and form, then shows the medicine', (
      tester,
    ) async {
      final camera = FakePhotoCapture(result: '/captured/one.jpg');
      await openAddMedicine(tester, camera: camera);

      await tester.enterText(find.byType(TextField), 'Insulin');
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(find.text('Retake photo'), findsOneWidget);
      await tester.tap(find.text('Injectable'));
      await tester.pumpAndSettle();
      await tapSave(tester);

      final saved = (await runDb(
        tester,
        () => medicines.watchAll().first,
      )).single;
      expect(saved.name, 'Insulin');
      expect(saved.form, MedicineForm.injectable);
      expect(photos.stored[saved.photoPath], '/captured/one.jpg');

      expect(find.text('Insulin'), findsOneWidget);
      expect(find.text('Medicine information'), findsOneWidget);
      expect(find.text('No reminders.'), findsOneWidget);

      // Back goes to the list, not to the add form.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('your medicines.'), findsOneWidget);
      expect(find.text('Insulin'), findsOneWidget);

      await disposeTestApp(tester);
    });

    testWidgets('keeps no photo when the camera is cancelled', (tester) async {
      await openAddMedicine(tester, camera: FakePhotoCapture(result: null));

      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oral / edible'));
      await tapSave(tester);

      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Take a photo of the medicine.'), findsOneWidget);
      expect(await runDb(tester, () => medicines.watchAll().first), isEmpty);

      await disposeTestApp(tester);
    });

    testWidgets('reports a camera that cannot be opened', (tester) async {
      await openAddMedicine(
        tester,
        camera: FakePhotoCapture(
          error: PlatformException(code: 'no_available_camera'),
        ),
      );

      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();

      expect(find.text("The camera couldn't be opened."), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);

      await disposeTestApp(tester);
    });
  });

  group('Medicine details', () {
    testWidgets('lists the medicine reminders with their pause state', (
      tester,
    ) async {
      await runDb(
        tester,
        () => medicines.insert(aMedicine(name: 'Paracetamol')),
      );
      await runDb(
        tester,
        () => reminders.save(aReminder(id: 'r1', time: LocalTime(9, 0))),
      );
      await runDb(
        tester,
        () => reminders.save(
          aReminder(id: 'r2', time: LocalTime(21, 0), paused: true),
        ),
      );
      await pumpTestApp(tester, db: db, photos: photos);

      await tester.tap(find.text('Paracetamol'));
      await tester.pumpAndSettle();

      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('9:00 PM'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('No reminders.'), findsNothing);

      await disposeTestApp(tester);
    });

    testWidgets('deletes the medicine, its reminders and photo on confirm', (
      tester,
    ) async {
      await runDb(
        tester,
        () => medicines.insert(aMedicine(name: 'Paracetamol', photo: 'p.jpg')),
      );
      await runDb(tester, () => reminders.save(aReminder(id: 'r1')));
      await pumpTestApp(tester, db: db, photos: photos);
      await tester.tap(find.text('Paracetamol'));
      await tester.pumpAndSettle();

      await tapDeleteMedicine(tester);
      expect(find.text('Delete Paracetamol?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('add the first one with its photo.'), findsOneWidget);
      expect(await runDb(tester, () => medicines.find('m1')), isNull);
      expect(
        await runDb(tester, () => reminders.findForMedicine('m1')),
        isEmpty,
      );
      expect(photos.deleted, ['p.jpg']);

      await disposeTestApp(tester);
    });

    testWidgets('asks about "this medicine" when it has no name', (
      tester,
    ) async {
      await runDb(tester, () => medicines.insert(aMedicine(name: null)));
      await pumpTestApp(tester, db: db, photos: photos);
      await tester.tap(find.text('Unnamed medicine'));
      await tester.pumpAndSettle();

      await tapDeleteMedicine(tester);

      expect(find.text('Delete this medicine?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await disposeTestApp(tester);
    });

    testWidgets('keeps the medicine when deletion is cancelled', (
      tester,
    ) async {
      await runDb(
        tester,
        () => medicines.insert(aMedicine(name: 'Paracetamol')),
      );
      await pumpTestApp(tester, db: db, photos: photos);
      await tester.tap(find.text('Paracetamol'));
      await tester.pumpAndSettle();

      await tapDeleteMedicine(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Medicine information'), findsOneWidget);
      expect(await runDb(tester, () => medicines.find('m1')), isNotNull);
      expect(photos.deleted, isEmpty);

      await disposeTestApp(tester);
    });
  });
}
