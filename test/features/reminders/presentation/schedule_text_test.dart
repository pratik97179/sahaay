import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';
import 'package:sahaay/features/reminders/domain/reminder_schedule.dart';
import 'package:sahaay/features/reminders/presentation/schedule_text.dart';

void main() {
  String describe(Recurrence recurrence) => describeSchedule(
    ReminderSchedule(
      time: LocalTime(9, 0),
      recurrence: recurrence,
      startDate: LocalDate(2026, 3, 10),
    ),
    formatDate: (date) => 'DATE($date)',
  );

  group('describeSchedule', () {
    test('one-time reminders name their date', () {
      expect(describe(const OneTimeRecurrence()), 'Once on DATE(2026-03-10)');
    });

    test('daily', () {
      expect(describe(DailyRecurrence()), 'Every day');
      expect(describe(DailyRecurrence(interval: 15)), 'Every 15 days');
    });

    test('weekly names up to two days in full, in week order', () {
      expect(
        describe(WeeklyRecurrence(weekdays: {4, 1})),
        'Every week on Monday and Thursday',
      );
      expect(describe(WeeklyRecurrence(weekdays: {7})), 'Every week on Sunday');
      expect(
        describe(WeeklyRecurrence(weekdays: {1, 4}, interval: 2)),
        'Every 2 weeks on Monday and Thursday',
      );
    });

    test('weekly shortens three or more days', () {
      expect(
        describe(WeeklyRecurrence(weekdays: {5, 1, 3})),
        'Every week on Mon, Wed and Fri',
      );
    });

    test('monthly lists days as ordinals', () {
      expect(
        describe(MonthlyRecurrence(days: {15, 1})),
        'Every month on the 1st and 15th',
      );
      expect(
        describe(MonthlyRecurrence(days: {31}, interval: 3)),
        'Every 3 months on the 31st',
      );
      expect(
        describe(MonthlyRecurrence(days: {2, 3, 22})),
        'Every month on the 2nd, 3rd and 22nd',
      );
    });

    test('yearly', () {
      expect(
        describe(YearlyRecurrence(month: 2, day: 29)),
        'Every year on 29 February',
      );
    });
  });

  group('ordinal', () {
    test('uses th for 11 to 13', () {
      expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 30, 31].map(ordinal), [
        '1st',
        '2nd',
        '3rd',
        '4th',
        '11th',
        '12th',
        '13th',
        '21st',
        '22nd',
        '23rd',
        '30th',
        '31st',
      ]);
    });
  });

  group('monthEndNote', () {
    test('explains days that some months lack', () {
      expect(
        monthEndNote(MonthlyRecurrence(days: {1, 31})),
        'In months without the 31st, it is on the last day of the month.',
      );
      expect(
        monthEndNote(MonthlyRecurrence(days: {29, 30})),
        'In months without the 29th or 30th, '
        'it is on the last day of the month.',
      );
    });

    test('explains 29 February', () {
      expect(
        monthEndNote(YearlyRecurrence(month: 2, day: 29)),
        'In years without 29 February, it is on 28 February.',
      );
    });

    test('is absent when every month has the days', () {
      expect(monthEndNote(MonthlyRecurrence(days: {1, 28})), isNull);
      expect(monthEndNote(YearlyRecurrence(month: 3, day: 31)), isNull);
      expect(monthEndNote(DailyRecurrence()), isNull);
    });
  });
}
