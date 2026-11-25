import 'medicine.dart';

/// Persistence contract for medicines.
abstract interface class MedicineRepository {
  /// All medicines, oldest first.
  Stream<List<Medicine>> watchAll();

  Stream<Medicine?> watch(String id);

  Future<Medicine?> find(String id);

  Future<void> insert(Medicine medicine);

  /// Deletes the medicine and, through the store, all of its reminders.
  Future<void> delete(String id);
}
