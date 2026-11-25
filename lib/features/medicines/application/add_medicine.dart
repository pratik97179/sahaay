import '../domain/medicine.dart';
import '../domain/medicine_photo_storage.dart';
import '../domain/medicine_repository.dart';

/// Creates a medicine from user input and a captured photo (FR-01).
final class AddMedicine {
  AddMedicine({
    required this._medicines,
    required this._photos,
    required this._newId,
  });

  final MedicineRepository _medicines;
  final MedicinePhotoStorage _photos;
  final String Function() _newId;

  /// Copies the photo at [capturedPhotoPath] into app storage and saves the
  /// medicine. Returns the new medicine's id.
  ///
  /// If saving fails, the stored photo copy is removed so no orphan remains.
  Future<String> call({
    required MedicineForm form,
    required String capturedPhotoPath,
    String? name,
  }) async {
    final photoKey = await _photos.store(capturedPhotoPath);
    try {
      final medicine = Medicine(
        id: _newId(),
        name: name,
        form: form,
        photoPath: photoKey,
      );
      await _medicines.insert(medicine);
      return medicine.id;
    } catch (_) {
      await _photos.delete(photoKey).catchError((Object _) {});
      rethrow;
    }
  }
}
