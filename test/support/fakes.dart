import 'dart:io';

import 'package:sahaay/features/medicines/application/photo_capture.dart';
import 'package:sahaay/features/medicines/domain/medicine_photo_storage.dart';

/// Returns a fixed path, `null` to simulate the user cancelling, or throws
/// [error] to simulate a camera that cannot be opened.
final class FakePhotoCapture implements PhotoCapture {
  FakePhotoCapture({this.result = '/captured/photo.jpg', this.error});

  final String? result;
  final Exception? error;

  @override
  Future<String?> capture() async {
    if (error case final error?) throw error;
    return result;
  }
}

/// Records stored and deleted keys without touching the file system, so it
/// can be used inside widget tests' fake-async zone.
final class FakePhotoStorage implements MedicinePhotoStorage {
  final stored = <String, String>{};
  final deleted = <String>[];

  @override
  Future<String> store(String sourcePath) async {
    final key = 'photo-${stored.length + 1}.jpg';
    stored[key] = sourcePath;
    return key;
  }

  @override
  File resolve(String key) => File('/fake-photos/$key');

  @override
  Future<void> delete(String key) async {
    stored.remove(key);
    deleted.add(key);
  }
}
