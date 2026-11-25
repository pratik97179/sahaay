import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/database/database_provider.dart';
import '../../core/storage/app_directories.dart';
import 'application/add_medicine.dart';
import 'application/delete_medicine.dart';
import 'application/photo_capture.dart';
import 'data/drift_medicine_repository.dart';
import 'data/file_medicine_photo_storage.dart';
import 'data/image_picker_photo_capture.dart';
import 'domain/medicine.dart';
import 'domain/medicine_photo_storage.dart';
import 'domain/medicine_repository.dart';

final medicineRepositoryProvider = Provider<MedicineRepository>(
  (ref) => DriftMedicineRepository(ref.watch(appDatabaseProvider)),
);

final medicinePhotoStorageProvider = Provider<MedicinePhotoStorage>(
  (ref) => FileMedicinePhotoStorage(
    Directory(
      p.join(ref.watch(appDocumentsDirectoryProvider).path, 'medicine_photos'),
    ),
  ),
);

final photoCaptureProvider = Provider<PhotoCapture>(
  (ref) => ImagePickerPhotoCapture(),
);

final addMedicineProvider = Provider<AddMedicine>(
  (ref) => AddMedicine(
    medicines: ref.watch(medicineRepositoryProvider),
    photos: ref.watch(medicinePhotoStorageProvider),
    transactions: ref.watch(transactionRunnerProvider),
    newId: const Uuid().v4,
  ),
);

final deleteMedicineProvider = Provider<DeleteMedicine>(
  (ref) => DeleteMedicine(
    medicines: ref.watch(medicineRepositoryProvider),
    photos: ref.watch(medicinePhotoStorageProvider),
  ),
);

/// All medicines, oldest first.
final medicinesProvider = StreamProvider.autoDispose<List<Medicine>>(
  (ref) => ref.watch(medicineRepositoryProvider).watchAll(),
);

/// One medicine, or `null` once it has been deleted.
final medicineProvider = StreamProvider.autoDispose.family<Medicine?, String>(
  (ref, id) => ref.watch(medicineRepositoryProvider).watch(id),
);
