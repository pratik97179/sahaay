import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/reminder.dart';
import '../domain/reminder_repository.dart';
import 'reminder_row_mapper.dart';

final class DriftReminderRepository implements ReminderRepository {
  DriftReminderRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  SimpleSelectStatement<$RemindersTable, ReminderRow> _ordered() =>
      _db.select(_db.reminders)..orderBy([
        (t) => OrderingTerm.asc(t.timeMinutes),
        (t) => OrderingTerm.asc(t.createdAt),
        (t) => OrderingTerm.asc(t.id),
      ]);

  @override
  Stream<List<Reminder>> watchForMedicine(String medicineId) =>
      (_ordered()..where((t) => t.medicineId.equals(medicineId))).watch().map(
        (rows) => rows.map(ReminderRowMapper.toDomain).toList(),
      );

  @override
  Stream<List<Reminder>> watchAll() => _ordered().watch().map(
    (rows) => rows.map(ReminderRowMapper.toDomain).toList(),
  );

  @override
  Stream<Reminder?> watch(String id) =>
      (_db.select(_db.reminders)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : ReminderRowMapper.toDomain(row));

  @override
  Future<Reminder?> find(String id) async {
    final row = await (_db.select(
      _db.reminders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : ReminderRowMapper.toDomain(row);
  }

  @override
  Future<List<Reminder>> findForMedicine(String medicineId) async =>
      (await (_ordered()..where((t) => t.medicineId.equals(medicineId))).get())
          .map(ReminderRowMapper.toDomain)
          .toList();

  @override
  Future<List<Reminder>> findAll() async =>
      (await _ordered().get()).map(ReminderRowMapper.toDomain).toList();

  @override
  Future<void> save(Reminder reminder) async {
    final existing = await (_db.select(
      _db.reminders,
    )..where((t) => t.id.equals(reminder.id))).getSingleOrNull();
    if (existing != null && existing.medicineId != reminder.medicineId) {
      throw StateError('A reminder cannot move to another medicine.');
    }
    await _db
        .into(_db.reminders)
        .insertOnConflictUpdate(
          ReminderRowMapper.toCompanion(
            reminder,
            createdAt: existing?.createdAt ?? _clock(),
          ),
        );
  }

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();
}
