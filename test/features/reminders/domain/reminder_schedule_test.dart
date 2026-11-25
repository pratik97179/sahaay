import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';
import 'package:sahaay/features/reminders/domain/reminder_schedule.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);
LocalDateTime at(int y, int m, int day, [int h = 0, int min = 0]) =>
    LocalDateTime(d(y, m, day), LocalTime(h, min));

ReminderSchedule schedule(
  Recurrence recurrence, {
  required LocalDate start,
  LocalDate? end,
  LocalTime? time,
}) => ReminderSchedule(
  time: time ?? LocalTime(9, 0),
  recurrence: recurrence,
  startDate: start,
  endDate: end,
);

List<LocalDate> dates(ReminderSchedule s, LocalDateTime from, int count) =>
    s.occurrencesFrom(from).take(count).map((o) => o.date).toList();

void main() {
  group('one-time', () {
    final s = schedule(const OneTimeRecurrence(), start: d(2026, 12, 1));

    test('fires once at the configured date and time', () {
      expect(s.occurrencesFrom(at(2026, 11, 25)).toList(), [
        at(2026, 12, 1, 9),
      ]);
    });

    test('fires when now is exactly the occurrence', () {
      expect(s.nextOccurrence(at(2026, 12, 1, 9)), at(2026, 12, 1, 9));
    });

    test('has no occurrence after it has passed', () {
      expect(s.nextOccurrence(at(2026, 12, 1, 9, 1)), isNull);
    });

    test('rejects an end date', () {
      expect(
        () => schedule(
          const OneTimeRecurrence(),
          start: d(2026, 12, 1),
          end: d(2026, 12, 2),
        ),
        throwsA(isA<InvalidScheduleException>()),
      );
    });
  });

  group('daily', () {
    test('every day starts on the start date', () {
      final s = schedule(DailyRecurrence(), start: d(2026, 12, 30));
      expect(dates(s, at(2026, 1, 1), 3), [
        d(2026, 12, 30),
        d(2026, 12, 31),
        d(2027, 1, 1),
      ]);
    });

    test('skips today once the time has passed', () {
      final s = schedule(DailyRecurrence(), start: d(2026, 11, 1));
      expect(s.nextOccurrence(at(2026, 11, 25, 9, 1)), at(2026, 11, 26, 9));
      expect(s.nextOccurrence(at(2026, 11, 25, 8, 59)), at(2026, 11, 25, 9));
    });

    test('every N days counts from the start date', () {
      final s = schedule(DailyRecurrence(interval: 15), start: d(2026, 1, 1));
      expect(dates(s, at(2026, 1, 2), 3), [
        d(2026, 1, 16),
        d(2026, 1, 31),
        d(2026, 2, 15),
      ]);
    });

    test('interval crosses a leap day by calendar days', () {
      final s = schedule(DailyRecurrence(interval: 2), start: d(2028, 2, 27));
      expect(dates(s, at(2028, 2, 27), 3), [
        d(2028, 2, 27),
        d(2028, 2, 29),
        d(2028, 3, 2),
      ]);
    });

    test('rejects an interval below 1', () {
      expect(
        () => DailyRecurrence(interval: 0),
        throwsA(isA<InvalidScheduleException>()),
      );
    });
  });

  group('weekly', () {
    test('fires on selected weekdays', () {
      // 2026-11-23 is a Monday.
      final s = schedule(
        WeeklyRecurrence(weekdays: {1, 4}),
        start: d(2026, 11, 23),
      );
      expect(dates(s, at(2026, 11, 23), 4), [
        d(2026, 11, 23),
        d(2026, 11, 26),
        d(2026, 11, 30),
        d(2026, 12, 3),
      ]);
    });

    test('does not fire on weekdays before a mid-week start date', () {
      // Start on Wednesday 2026-11-25; Monday of that week is excluded.
      final s = schedule(
        WeeklyRecurrence(weekdays: {1, 4}),
        start: d(2026, 11, 25),
      );
      expect(dates(s, at(2026, 11, 1), 2), [d(2026, 11, 26), d(2026, 11, 30)]);
    });

    test(
      'every N weeks combines with weekdays, anchored on the start week',
      () {
        final s = schedule(
          WeeklyRecurrence(weekdays: {1, 4}, interval: 2),
          start: d(2026, 11, 25),
        );
        expect(dates(s, at(2026, 11, 25), 4), [
          d(2026, 11, 26),
          d(2026, 12, 7),
          d(2026, 12, 10),
          d(2026, 12, 21),
        ]);
      },
    );

    test('crosses a year boundary', () {
      final s = schedule(
        WeeklyRecurrence(weekdays: {5}),
        start: d(2026, 12, 25),
      );
      expect(dates(s, at(2026, 12, 26), 2), [d(2027, 1, 1), d(2027, 1, 8)]);
    });

    test('rejects empty or invalid weekdays', () {
      expect(
        () => WeeklyRecurrence(weekdays: {}),
        throwsA(isA<InvalidScheduleException>()),
      );
      expect(
        () => WeeklyRecurrence(weekdays: {0}),
        throwsA(isA<InvalidScheduleException>()),
      );
    });
  });

  group('monthly', () {
    test('fires on multiple selected days in order', () {
      final s = schedule(
        MonthlyRecurrence(days: {20, 5}),
        start: d(2026, 1, 1),
      );
      expect(dates(s, at(2026, 1, 1), 4), [
        d(2026, 1, 5),
        d(2026, 1, 20),
        d(2026, 2, 5),
        d(2026, 2, 20),
      ]);
    });

    test('day 31 clamps to each month end without drifting', () {
      final s = schedule(MonthlyRecurrence(days: {31}), start: d(2027, 1, 1));
      expect(dates(s, at(2027, 1, 1), 5), [
        d(2027, 1, 31),
        d(2027, 2, 28),
        d(2027, 3, 31),
        d(2027, 4, 30),
        d(2027, 5, 31),
      ]);
    });

    test('day 30 uses 29 February in a leap year', () {
      final s = schedule(MonthlyRecurrence(days: {30}), start: d(2028, 2, 1));
      expect(dates(s, at(2028, 2, 1), 2), [d(2028, 2, 29), d(2028, 3, 30)]);
    });

    test('days that clamp to the same date fire once', () {
      final s = schedule(
        MonthlyRecurrence(days: {29, 30, 31}),
        start: d(2027, 2, 1),
      );
      expect(dates(s, at(2027, 2, 1), 4), [
        d(2027, 2, 28),
        d(2027, 3, 29),
        d(2027, 3, 30),
        d(2027, 3, 31),
      ]);
    });

    test('every N months counts calendar months from the start month', () {
      final s = schedule(
        MonthlyRecurrence(days: {31}, interval: 3),
        start: d(2026, 11, 10),
      );
      expect(dates(s, at(2026, 11, 10), 4), [
        d(2026, 11, 30),
        d(2027, 2, 28),
        d(2027, 5, 31),
        d(2027, 8, 31),
      ]);
    });

    test('skips selected days before the start date in the start month', () {
      final s = schedule(
        MonthlyRecurrence(days: {1, 15}),
        start: d(2026, 11, 10),
      );
      expect(dates(s, at(2026, 1, 1), 2), [d(2026, 11, 15), d(2026, 12, 1)]);
    });

    test('rejects empty or out-of-range days', () {
      expect(
        () => MonthlyRecurrence(days: {}),
        throwsA(isA<InvalidScheduleException>()),
      );
      expect(
        () => MonthlyRecurrence(days: {32}),
        throwsA(isA<InvalidScheduleException>()),
      );
    });
  });

  group('yearly', () {
    test('fires on the selected month and day', () {
      final s = schedule(
        YearlyRecurrence(month: 3, day: 15),
        start: d(2026, 11, 25),
      );
      expect(dates(s, at(2026, 11, 25), 2), [d(2027, 3, 15), d(2028, 3, 15)]);
    });

    test('includes the start year when the date has not passed', () {
      final s = schedule(
        YearlyRecurrence(month: 12, day: 1),
        start: d(2026, 11, 25),
      );
      expect(dates(s, at(2026, 11, 25), 1), [d(2026, 12, 1)]);
    });

    test('29 February clamps to 28 February in non-leap years', () {
      final s = schedule(
        YearlyRecurrence(month: 2, day: 29),
        start: d(2027, 1, 1),
      );
      expect(dates(s, at(2027, 1, 1), 3), [
        d(2027, 2, 28),
        d(2028, 2, 29),
        d(2029, 2, 28),
      ]);
    });

    test('rejects a day that never exists in the month', () {
      expect(
        () => YearlyRecurrence(month: 4, day: 31),
        throwsA(isA<InvalidScheduleException>()),
      );
    });
  });

  group('start and end dates', () {
    test('no occurrences before the start date', () {
      final s = schedule(DailyRecurrence(), start: d(2026, 12, 1));
      expect(s.nextOccurrence(at(2026, 11, 1)), at(2026, 12, 1, 9));
    });

    test('end date is inclusive and stops the sequence', () {
      final s = schedule(
        DailyRecurrence(),
        start: d(2026, 12, 30),
        end: d(2027, 1, 1),
      );
      expect(s.occurrencesFrom(at(2026, 1, 1)).map((o) => o.date).toList(), [
        d(2026, 12, 30),
        d(2026, 12, 31),
        d(2027, 1, 1),
      ]);
    });

    test('no occurrences after the end date', () {
      final s = schedule(
        WeeklyRecurrence(weekdays: {1}),
        start: d(2026, 11, 1),
        end: d(2026, 11, 30),
      );
      expect(s.nextOccurrence(at(2026, 11, 30, 9, 1)), isNull);
    });

    test('end date that matches no occurrence ends cleanly', () {
      final s = schedule(
        MonthlyRecurrence(days: {15}),
        start: d(2026, 11, 1),
        end: d(2026, 12, 10),
      );
      expect(s.occurrencesFrom(at(2026, 11, 1)).length, 1);
    });

    test('rejects an end date before the start date', () {
      expect(
        () => schedule(
          DailyRecurrence(),
          start: d(2026, 11, 2),
          end: d(2026, 11, 1),
        ),
        throwsA(isA<InvalidScheduleException>()),
      );
    });
  });
}
