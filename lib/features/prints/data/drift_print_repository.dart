import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../reminders/domain/calendar.dart';
import '../domain/print.dart';
import '../domain/print_repository.dart';

final class DriftPrintRepository implements PrintRepository {
  DriftPrintRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Print>> watchDay(LocalDate day) =>
      (_db.select(_db.prints)..where((t) => t.day.equals(day.toString())))
          .watch()
          .map((rows) => rows.map(_toDomain).toList());

  @override
  Stream<List<Print>> watchBetween(LocalDate from, LocalDate to) =>
      // ISO dates sort as text, so a text range is a date range.
      (_db.select(_db.prints)
            ..where(
              (t) => t.day.isBetweenValues(from.toString(), to.toString()),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.day)]))
          .watch()
          .map((rows) => rows.map(_toDomain).toList());

  @override
  Future<Print?> find(String reminderId, LocalDate day) async {
    final row =
        await (_db.select(_db.prints)..where(
              (t) =>
                  t.reminderId.equals(reminderId) &
                  t.day.equals(day.toString()),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> add(Print print) => _db
      .into(_db.prints)
      .insertOnConflictUpdate(
        PrintsCompanion.insert(
          reminderId: print.reminderId,
          day: print.day.toString(),
          madeAt: DateTime(
            print.madeAt.date.year,
            print.madeAt.date.month,
            print.madeAt.date.day,
            print.madeAt.time.hour,
            print.madeAt.time.minute,
          ),
        ),
      );

  @override
  Future<void> remove(String reminderId, LocalDate day) =>
      (_db.delete(_db.prints)..where(
            (t) =>
                t.reminderId.equals(reminderId) & t.day.equals(day.toString()),
          ))
          .go();

  static Print _toDomain(PrintRow row) {
    final parts = row.day.split('-').map(int.parse).toList();
    return Print(
      reminderId: row.reminderId,
      day: LocalDate(parts[0], parts[1], parts[2]),
      madeAt: LocalDateTime.fromDateTime(row.madeAt),
    );
  }
}
