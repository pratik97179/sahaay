import '../../../core/database/transaction_runner.dart';
import '../domain/medicine.dart';
import '../domain/medicine_photo_storage.dart';
import '../domain/medicine_repository.dart';

/// Saves records that belong to a new medicine, such as its reminders, given
/// the medicine's id. Runs inside the same transaction as the medicine.
typedef SaveWithMedicine = Future<void> Function(String medicineId);

/// Creates a medicine from user input and a captured photo.
final class AddMedicine {
  AddMedicine({
    required this._medicines,
    required this._photos,
    required this._transactions,
    required this._newId,
  });

  final MedicineRepository _medicines;
  final MedicinePhotoStorage _photos;
  final TransactionRunner _transactions;
  final String Function() _newId;

  /// Copies the photo at [capturedPhotoPath] into app storage and saves the
  /// medicine, then runs [alsoSave] for anything saved with it. Returns the
  /// new medicine's id.
  ///
  /// The medicine and whatever [alsoSave] writes are saved together or not at
  /// all. If saving fails, the stored photo copy is removed so no
  /// orphan remains.
  Future<String> call({
    required MedicineForm form,
    required String capturedPhotoPath,
    String? name,
    SaveWithMedicine? alsoSave,
  }) async {
    final photoKey = await _photos.store(capturedPhotoPath);
    try {
      final medicine = Medicine(
        id: _newId(),
        name: name,
        form: form,
        photoPath: photoKey,
      );
      await _transactions.run(() async {
        await _medicines.insert(medicine);
        await alsoSave?.call(medicine.id);
      });
      return medicine.id;
    } catch (_) {
      await _photos.delete(photoKey).catchError((Object _) {});
      rethrow;
    }
  }
}
