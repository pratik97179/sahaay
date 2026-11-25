import 'dart:io';

/// Keeps medicine photos in app-private storage.
///
/// Photos are identified by a storage key rather than an absolute path,
/// because the app's container path can change between installs and updates.
abstract interface class MedicinePhotoStorage {
  /// Copies the photo at [sourcePath] into storage and returns its key.
  Future<String> store(String sourcePath);

  File resolve(String key);

  /// Deletes the photo for [key]; does nothing if it is already gone.
  Future<void> delete(String key);
}
