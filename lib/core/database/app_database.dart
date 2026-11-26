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

/// The person's own record that they took one reminder's dose on one day
/// (PRD §3.3, FR-11). Made and removed only by the person.
@DataClassName('PrintRow')
class Prints extends Table {
  TextColumn get reminderId =>
      text().references(Reminders, #id, onDelete: KeyAction.cascade)();

  /// The day it is for, as an ISO date (yyyy-MM-dd).
  TextColumn get day => text()();

  /// When the person made it, as local wall-clock time.
  DateTimeColumn get madeAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {reminderId, day};
}

@DriftDatabase(tables: [Medicines, Reminders, Prints])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the on-device database.
  factory AppDatabase.local() => AppDatabase(driftDatabase(name: 'sahaay'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // 2: prints (PRD 0.4). Existing medicines and reminders are kept.
      if (from < 2) await m.createTable(prints);
    },
    beforeOpen: (details) async {
      // Required for ON DELETE CASCADE from medicines to reminders to prints.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
