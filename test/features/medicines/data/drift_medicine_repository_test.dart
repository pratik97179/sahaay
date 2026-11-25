import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/features/medicines/data/drift_medicine_repository.dart';
import 'package:sahaay/features/medicines/domain/medicine.dart';

import '../../../support/builders.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftMedicineRepository repo;
  var tick = 0;

  setUp(() {
    db = openTestDatabase();
    repo = DriftMedicineRepository(
      db,
      clock: () => DateTime.utc(2026).add(Duration(seconds: tick++)),
    );
  });

  tearDown(() => db.close());

  test('creates and retrieves a medicine', () async {
    await repo.insert(
      aMedicine(name: null, form: MedicineForm.injectable, photo: 'k.jpg'),
    );
    final m = (await repo.find('m1'))!;
    expect(m.name, isNull);
    expect(m.form, MedicineForm.injectable);
    expect(m.photoPath, 'k.jpg');
  });

  test('lists medicines in creation order', () async {
    await repo.insert(aMedicine(id: 'b', photo: 'b.jpg'));
    await repo.insert(aMedicine(id: 'a', photo: 'a.jpg'));
    expect((await repo.watchAll().first).map((m) => m.id), ['b', 'a']);
  });

  test('delete removes the medicine', () async {
    await repo.insert(aMedicine());
    await repo.delete('m1');
    expect(await repo.find('m1'), isNull);
  });
}
