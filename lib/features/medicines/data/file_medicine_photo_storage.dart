import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../domain/medicine_photo_storage.dart';

final class FileMedicinePhotoStorage implements MedicinePhotoStorage {
  FileMedicinePhotoStorage(this._directory, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final Directory _directory;
  final Uuid _uuid;

  @override
  Future<String> store(String sourcePath) async {
    await _directory.create(recursive: true);
    final extension = p.extension(sourcePath).toLowerCase();
    final key = '${_uuid.v4()}${extension.isEmpty ? '.jpg' : extension}';
    await File(sourcePath).copy(p.join(_directory.path, key));
    return key;
  }

  @override
  File resolve(String key) => File(p.join(_directory.path, p.basename(key)));

  @override
  Future<void> delete(String key) async {
    final file = resolve(key);
    if (await file.exists()) await file.delete();
  }
}
