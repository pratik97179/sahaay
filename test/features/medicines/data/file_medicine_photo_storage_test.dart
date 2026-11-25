import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/medicines/data/file_medicine_photo_storage.dart';

void main() {
  late Directory temp;
  late FileMedicinePhotoStorage storage;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('sahaay_photos');
    storage = FileMedicinePhotoStorage(Directory('${temp.path}/photos'));
  });

  tearDown(() => temp.delete(recursive: true));

  test('stores a copy and resolves it by key', () async {
    final source = File('${temp.path}/capture.JPG')
      ..writeAsBytesSync([1, 2, 3]);

    final key = await storage.store(source.path);

    expect(key, endsWith('.jpg'));
    expect(key, isNot(contains('/')));
    expect(storage.resolve(key).readAsBytesSync(), [1, 2, 3]);
  });

  test('delete removes the photo and tolerates a missing file', () async {
    final source = File('${temp.path}/c.png')..writeAsBytesSync([1]);
    final key = await storage.store(source.path);

    await storage.delete(key);
    expect(storage.resolve(key).existsSync(), isFalse);
    await storage.delete(key);
  });
}
