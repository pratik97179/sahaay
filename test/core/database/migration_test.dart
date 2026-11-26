import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/core/database/app_database.dart';

void main() {
  test(
    'upgrading a version 1 database adds prints and keeps everything',
    () async {
      // The schema as version 1 shipped it, with one medicine and reminder.
      // drift runs this setup before it opens the database and upgrades it.
      final executor = NativeDatabase.memory(
        setup: (raw) => raw.execute('''
        CREATE TABLE "medicines" ("id" TEXT NOT NULL, "name" TEXT NULL, "form" TEXT NOT NULL, "photo_key" TEXT NOT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));
        CREATE TABLE "reminders" ("id" TEXT NOT NULL, "medicine_id" TEXT NOT NULL REFERENCES medicines (id) ON DELETE CASCADE, "time_minutes" INTEGER NOT NULL, "recurrence_type" TEXT NOT NULL, "interval" INTEGER NOT NULL DEFAULT 1, "recurrence_days" TEXT NULL, "yearly_month" INTEGER NULL, "yearly_day" INTEGER NULL, "start_date" TEXT NOT NULL, "end_date" TEXT NULL, "quantity" TEXT NULL, "instruction" TEXT NULL, "is_paused" INTEGER NOT NULL DEFAULT 0 CHECK ("is_paused" IN (0, 1)), "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));
        INSERT INTO medicines VALUES ('m1', 'Paracetamol', 'oral', 'p.jpg', 0);
        INSERT INTO reminders (id, medicine_id, time_minutes, recurrence_type, start_date, created_at) VALUES ('r1', 'm1', 540, 'daily', '2026-01-01', 0);
        PRAGMA user_version = 1;
      '''),
      );

      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(executor);
      addTearDown(db.close);

      expect((await db.select(db.medicines).get()).single.name, 'Paracetamol');
      expect((await db.select(db.reminders).get()).single.id, 'r1');
      await db
          .into(db.prints)
          .insert(
            PrintsCompanion.insert(
              reminderId: 'r1',
              day: '2026-03-10',
              madeAt: DateTime(2026, 3, 10, 9),
            ),
          );
      expect(await db.select(db.prints).get(), hasLength(1));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 2);
    },
  );
}
