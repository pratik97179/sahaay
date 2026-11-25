import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/medicines/domain/medicine.dart';

part 'app_database.g.dart';

@DataClassName('MedicineRow')
class Medicines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get form => textEnum<MedicineForm>()();

  /// Storage key of the photo, relative to the photo directory.
  TextColumn get photoKey => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get medicineId =>
      text().references(Medicines, #id, onDelete: KeyAction.cascade)();
  IntColumn get timeMinutes => integer()();

  /// One of: once, daily, weekly, monthly, yearly.
  TextColumn get recurrenceType => text()();
  IntColumn get interval => integer().withDefault(const Constant(1))();

  /// Comma-separated ISO weekdays (weekly) or days of month (monthly).
  TextColumn get recurrenceDays => text().nullable()();
  IntColumn get yearlyMonth => integer().nullable()();
  IntColumn get yearlyDay => integer().nullable()();

  /// ISO dates (yyyy-MM-dd), stored without zone.
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();
  TextColumn get quantity => text().nullable()();
  TextColumn get instruction => text().nullable()();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Medicines, Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the on-device database.
  factory AppDatabase.local() => AppDatabase(driftDatabase(name: 'sahaay'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Required for ON DELETE CASCADE from medicines to reminders.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
