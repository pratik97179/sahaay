import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/medicines/domain/medicine.dart';

void main() {
  test('name is optional and blank names are treated as absent', () {
    final medicine = Medicine(
      id: 'm1',
      form: MedicineForm.oral,
      photoPath: 'photos/m1.jpg',
      name: '  ',
    );
    expect(medicine.name, isNull);
  });

  test('a photo is required', () {
    expect(
      () => Medicine(id: 'm1', form: MedicineForm.injectable, photoPath: ''),
      throwsArgumentError,
    );
  });
}
