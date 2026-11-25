import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/calendar.dart';
import '../domain/recurrence.dart';
import '../domain/reminder.dart';
import '../domain/reminder_schedule.dart';

/// Maps between reminder rows and the domain model.
abstract final class ReminderRowMapper {
  static Reminder toDomain(ReminderRow row) => Reminder(
    id: row.id,
    medicineId: row.medicineId,
    schedule: ReminderSchedule(
      time: LocalTime(row.timeMinutes ~/ 60, row.timeMinutes % 60),
      recurrence: _recurrence(row),
      startDate: _parseDate(row.startDate),
      endDate: row.endDate == null ? null : _parseDate(row.endDate!),
    ),
    quantity: row.quantity,
    instruction: row.instruction,
    isPaused: row.isPaused,
  );

  static RemindersCompanion toCompanion(
    Reminder reminder, {
    required DateTime createdAt,
  }) {
    final schedule = reminder.schedule;
    final r = schedule.recurrence;
    return RemindersCompanion.insert(
      id: reminder.id,
      medicineId: reminder.medicineId,
      timeMinutes: schedule.time.minutesSinceMidnight,
      recurrenceType: switch (r) {
        OneTimeRecurrence() => 'once',
        DailyRecurrence() => 'daily',
        WeeklyRecurrence() => 'weekly',
        MonthlyRecurrence() => 'monthly',
        YearlyRecurrence() => 'yearly',
      },
      interval: Value(switch (r) {
        DailyRecurrence(:final interval) ||
        WeeklyRecurrence(:final interval) ||
        MonthlyRecurrence(:final interval) => interval,
        _ => 1,
      }),
      recurrenceDays: Value(switch (r) {
        WeeklyRecurrence(:final weekdays) => _joinDays(weekdays),
        MonthlyRecurrence(:final days) => _joinDays(days),
        _ => null,
      }),
      yearlyMonth: Value(r is YearlyRecurrence ? r.month : null),
      yearlyDay: Value(r is YearlyRecurrence ? r.day : null),
      startDate: schedule.startDate.toString(),
      endDate: Value(schedule.endDate?.toString()),
      quantity: Value(reminder.quantity),
      instruction: Value(reminder.instruction),
      isPaused: Value(reminder.isPaused),
      createdAt: createdAt,
    );
  }

  static Recurrence _recurrence(ReminderRow row) =>
      switch (row.recurrenceType) {
        'once' => const OneTimeRecurrence(),
        'daily' => DailyRecurrence(interval: row.interval),
        'weekly' => WeeklyRecurrence(
          weekdays: _splitDays(row.recurrenceDays),
          interval: row.interval,
        ),
        'monthly' => MonthlyRecurrence(
          days: _splitDays(row.recurrenceDays),
          interval: row.interval,
        ),
        'yearly' => YearlyRecurrence(
          month: row.yearlyMonth!,
          day: row.yearlyDay!,
        ),
        final type => throw StateError('Unknown recurrence type: $type'),
      };

  static String _joinDays(Set<int> days) => (days.toList()..sort()).join(',');

  static Set<int> _splitDays(String? value) => (value ?? '')
      .split(',')
      .where((s) => s.isNotEmpty)
      .map(int.parse)
      .toSet();

  static LocalDate _parseDate(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return LocalDate(parts[0], parts[1], parts[2]);
  }
}
