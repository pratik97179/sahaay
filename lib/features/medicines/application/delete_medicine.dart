import 'dart:io';

import '../domain/medicine_photo_storage.dart';
import '../domain/medicine_repository.dart';

/// Removes a medicine, all of its reminders and its photo.
final class DeleteMedicine {
  DeleteMedicine({required this._medicines, required this._photos});

  final MedicineRepository _medicines;
  final MedicinePhotoStorage _photos;

  /// Does nothing when the medicine no longer exists.
  Future<void> call(String medicineId) async {
    final medicine = await _medicines.find(medicineId);
    if (medicine == null) return;

    // The database row goes first: its reminders are removed with it by the
    // foreign-key cascade, and a failure here leaves the photo in place.
    await _medicines.delete(medicineId);
    try {
      await _photos.delete(medicine.photoPath);
    } on FileSystemException {
      // The medicine is already gone; a leftover file in the app's private
      // photo directory is never shown or referenced again.
    }
  }
}
