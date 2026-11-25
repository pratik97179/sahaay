import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/medicine.dart';
import '../domain/medicine_repository.dart';

final class DriftMedicineRepository implements MedicineRepository {
  DriftMedicineRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  @override
  Stream<List<Medicine>> watchAll() =>
      (_db.select(_db.medicines)..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .watch()
          .map((rows) => rows.map(_toDomain).toList());

  @override
  Stream<Medicine?> watch(String id) => (_db.select(
    _db.medicines,
  )..where((t) => t.id.equals(id))).watchSingleOrNull().map(_toDomainOrNull);

  @override
  Future<Medicine?> find(String id) async => _toDomainOrNull(
    await (_db.select(
      _db.medicines,
    )..where((t) => t.id.equals(id))).getSingleOrNull(),
  );

  @override
  Future<void> insert(Medicine medicine) => _db
      .into(_db.medicines)
      .insert(
        MedicinesCompanion.insert(
          id: medicine.id,
          name: Value(medicine.name),
          form: medicine.form,
          photoKey: medicine.photoPath,
          createdAt: _clock(),
        ),
      );

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.medicines)..where((t) => t.id.equals(id))).go();

  static Medicine? _toDomainOrNull(MedicineRow? row) =>
      row == null ? null : _toDomain(row);

  static Medicine _toDomain(MedicineRow row) => Medicine(
    id: row.id,
    name: row.name,
    form: row.form,
    photoPath: row.photoKey,
  );
}
