import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/application/add_medicine.dart';
import 'package:sahaay/features/medicines/application/delete_medicine.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/medicines/data/file_medicine_photo_storage.dart';
import 'package:sahaay/features/medicines/domain/medicine.dart';
import 'package:sahaay/features/medicines/domain/medicine_repository.dart';
import 'package:sahaay/features/reminders/data/drift_reminder_repository.dart';

import '../../../support/builders.dart';
import '../../../support/test_database.dart';

/// Fails every insert, to check that a failed save leaves nothing behind.
final class _FailingInsertRepository implements MedicineRepository {
  _FailingInsertRepository(this._inner);

  final MedicineRepository _inner;

  @override
  Future<void> insert(Medicine medicine) async => throw StateError('disk full');

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<Medicine?> find(String id) => _inner.find(id);

  @override
  Stream<Medicine?> watch(String id) => _inner.watch(id);

  @override
  Stream<List<Medicine>> watchAll() => _inner.watchAll();
}

void main() {
  late AppDatabase db;
  late Directory tmp;
  late DriftMedicineRepository medicines;
  late DriftReminderRepository reminders;
  late FileMedicinePhotoStorage photos;
  late File captured;

  setUp(() async {
    db = openTestDatabase();
    tmp = await Directory.systemTemp.createTemp('sahaay_workflows');
    medicines = DriftMedicineRepository(db);
    reminders = DriftReminderRepository(db);
    photos = FileMedicinePhotoStorage(Directory('${tmp.path}/photos'));
    captured = await File('${tmp.path}/capture.jpg').writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  List<FileSystemEntity> storedPhotos() {
    final dir = Directory('${tmp.path}/photos');
    return dir.existsSync() ? dir.listSync() : const [];
  }

  group('AddMedicine', () {
    test('stores a copy of the photo and saves the medicine', () async {
      final add = AddMedicine(
        medicines: medicines,
        photos: photos,
        newId: () => 'm1',
      );

      final id = await add(
        name: '  Paracetamol ',
        form: MedicineForm.oral,
        capturedPhotoPath: captured.path,
      );

      final saved = (await medicines.find(id))!;
      expect(id, 'm1');
      expect(saved.name, 'Paracetamol');
      expect(saved.form, MedicineForm.oral);
      expect(await photos.resolve(saved.photoPath).readAsBytes(), [1, 2, 3]);
    });

    test('saves a medicine without a name', () async {
      final add = AddMedicine(
        medicines: medicines,
        photos: photos,
        newId: () => 'm1',
      );

      await add(
        name: '',
        form: MedicineForm.injectable,
        capturedPhotoPath: captured.path,
      );

      final saved = (await medicines.find('m1'))!;
      expect(saved.name, isNull);
      expect(saved.form, MedicineForm.injectable);
    });

    test('removes the stored photo when saving fails', () async {
      final add = AddMedicine(
        medicines: _FailingInsertRepository(medicines),
        photos: photos,
        newId: () => 'm1',
      );

      await expectLater(
        add(form: MedicineForm.oral, capturedPhotoPath: captured.path),
        throwsStateError,
      );
      expect(storedPhotos(), isEmpty);
      expect(await medicines.find('m1'), isNull);
    });
  });

  group('DeleteMedicine', () {
    late AddMedicine add;
    late DeleteMedicine delete;

    setUp(() {
      var n = 0;
      add = AddMedicine(
        medicines: medicines,
        photos: photos,
        newId: () => 'm${++n}',
      );
      delete = DeleteMedicine(medicines: medicines, photos: photos);
    });

    test('removes the medicine, its reminders and its photo', () async {
      final id = await add(
        form: MedicineForm.oral,
        capturedPhotoPath: captured.path,
      );
      await reminders.save(aReminder(id: 'r1', medicineId: id));
      await reminders.save(aReminder(id: 'r2', medicineId: id));

      await delete(id);

      expect(await medicines.find(id), isNull);
      expect(await reminders.findForMedicine(id), isEmpty);
      expect(storedPhotos(), isEmpty);
    });

    test('leaves other medicines, reminders and photos intact', () async {
      final kept = await add(
        form: MedicineForm.oral,
        capturedPhotoPath: captured.path,
      );
      final removed = await add(
        form: MedicineForm.injectable,
        capturedPhotoPath: captured.path,
      );
      await reminders.save(aReminder(id: 'r1', medicineId: kept));
      await reminders.save(aReminder(id: 'r2', medicineId: removed));

      await delete(removed);

      final keptMedicine = (await medicines.find(kept))!;
      expect((await reminders.findForMedicine(kept)).map((r) => r.id), ['r1']);
      expect(photos.resolve(keptMedicine.photoPath).existsSync(), isTrue);
      expect(storedPhotos(), hasLength(1));
    });

    test('does nothing for a medicine that no longer exists', () async {
      await expectLater(delete('missing'), completes);
    });
  });
}
