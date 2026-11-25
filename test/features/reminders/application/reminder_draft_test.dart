import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/reminders/application/reminder_draft.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';

import '../../../support/builders.dart';

void main() {
  final today = LocalDate(2026, 3, 10);
  final now = LocalDateTime(today, LocalTime(8, 0));
  final nine = LocalTime(9, 0);

  ReminderDraft draft(RepeatType repeat) =>
      ReminderDraft.initial(today).copyWith(repeat: repeat, time: nine);

  group('initial draft', () {
    test('is daily, every day, from today, with no time chosen', () {
      final initial = ReminderDraft.initial(today);

      expect(initial.repeat, RepeatType.daily);
      expect(initial.interval, 1);
      expect(initial.startDate, today);
      expect(initial.time, isNull);
      expect(initial.endDate, isNull);
      expect(initial.errors(now), {ReminderDraftError.timeMissing});
      expect(initial.toDetails(now), isNull);
    });
  });

  group('builds the schedule of each repeat type', () {
    test('once, on the chosen date, never with an end date', () {
      final details = draft(RepeatType.once)
          .copyWith(endDate: () => LocalDate(2026, 4, 1))
          .toDetails(now)!;

      expect(details.schedule.recurrence, const OneTimeRecurrence());
      expect(details.schedule.startDate, today);
      expect(details.schedule.endDate, isNull);
      expect(details.schedule.time, nine);
    });

    test('daily, every N days', () {
      final details = draft(RepeatType.daily)
          .copyWith(interval: () => 15)
          .toDetails(now)!;

      expect(details.schedule.recurrence, DailyRecurrence(interval: 15));
    });

    test('weekly, on chosen weekdays every N weeks', () {
      final details = draft(RepeatType.weekly)
          .copyWith(weekdays: {1, 4}, interval: () => 2)
          .toDetails(now)!;

      expect(
        details.schedule.recurrence,
        WeeklyRecurrence(weekdays: {1, 4}, interval: 2),
      );
    });

    test('monthly, on chosen days every N months', () {
      final details = draft(RepeatType.monthly)
          .copyWith(monthDays: {1, 31}, interval: () => 3)
          .toDetails(now)!;

      expect(
        details.schedule.recurrence,
        MonthlyRecurrence(days: {1, 31}, interval: 3),
      );
    });

    test('yearly, on a chosen month and day, including 29 February', () {
      final details = draft(RepeatType.yearly)
          .copyWith(yearlyMonth: 2, yearlyDay: () => 29)
          .toDetails(now)!;

      expect(details.schedule.recurrence, YearlyRecurrence(month: 2, day: 29));
    });

    test('keeps the end date of a repeating reminder', () {
      final end = LocalDate(2026, 6, 30);
      final details = draft(RepeatType.daily)
          .copyWith(endDate: () => end)
          .toDetails(now)!;

      expect(details.schedule.endDate, end);
    });

    test('uses only the options of the chosen type', () {
      // Days chosen for weekly stay in the draft but do not leak into daily.
      final details = draft(RepeatType.weekly)
          .copyWith(weekdays: {2}, interval: () => 2)
          .copyWith(repeat: RepeatType.daily)
          .toDetails(now)!;

      expect(details.schedule.recurrence, DailyRecurrence(interval: 2));
    });
  });

  group('quantity and instruction', () {
    test('are passed on exactly as typed', () {
      final details = draft(RepeatType.daily)
          .copyWith(quantity: '1 tablet', instruction: ' After food ')
          .toDetails(now)!;

      expect(details.quantity, '1 tablet');
      expect(details.instruction, ' After food ');
    });
  });

  group('validation', () {
    test('requires a time', () {
      expect(
        ReminderDraft.initial(today).errors(now),
        contains(ReminderDraftError.timeMissing),
      );
    });

    test('requires an interval of at least 1 where it applies', () {
      for (final repeat in [
        RepeatType.daily,
        RepeatType.weekly,
        RepeatType.monthly,
      ]) {
        expect(
          draft(repeat).copyWith(interval: () => null).errors(now),
          contains(ReminderDraftError.intervalInvalid),
          reason: '$repeat with no interval',
        );
        expect(
          draft(repeat).copyWith(interval: () => 0).errors(now),
          contains(ReminderDraftError.intervalInvalid),
          reason: '$repeat every 0',
        );
      }
    });

    test('ignores the interval where it does not apply', () {
      for (final repeat in [RepeatType.once, RepeatType.yearly]) {
        expect(
          draft(repeat).copyWith(interval: () => null).errors(now),
          isNot(contains(ReminderDraftError.intervalInvalid)),
        );
      }
    });

    test('requires weekdays for weekly and days for monthly', () {
      expect(draft(RepeatType.weekly).errors(now), {
        ReminderDraftError.weekdaysMissing,
      });
      expect(draft(RepeatType.monthly).errors(now), {
        ReminderDraftError.monthDaysMissing,
      });
    });

    test('requires both month and day for yearly', () {
      expect(draft(RepeatType.yearly).copyWith(yearlyMonth: 5).errors(now), {
        ReminderDraftError.yearlyDateMissing,
      });
      expect(
        draft(RepeatType.yearly).copyWith(yearlyDay: () => 5).errors(now),
        {ReminderDraftError.yearlyDateMissing},
      );
    });

    test('rejects an end date before the start date', () {
      final early = draft(RepeatType.daily)
          .copyWith(endDate: () => today.addDays(-1));

      expect(early.errors(now), {ReminderDraftError.endBeforeStart});
      expect(
        draft(RepeatType.daily).copyWith(endDate: () => today).errors(now),
        isEmpty,
        reason: 'ending on the start day is allowed',
      );
    });

    test('ignores an end date on a one-time reminder', () {
      expect(
        draft(RepeatType.once)
            .copyWith(endDate: () => today.addDays(-1))
            .errors(now),
        isEmpty,
      );
    });

    group('a one-time reminder', () {
      test('must be later than now', () {
        final past = draft(RepeatType.once).copyWith(time: LocalTime(7, 59));
        final thisMinute = draft(RepeatType.once)
            .copyWith(time: LocalTime(8, 0));
        final nextMinute = draft(RepeatType.once)
            .copyWith(time: LocalTime(8, 1));
        final yesterday = draft(RepeatType.once)
            .copyWith(startDate: today.addDays(-1), time: LocalTime(23, 0));

        expect(past.errors(now), {ReminderDraftError.onceNotInFuture});
        expect(thisMinute.errors(now), {ReminderDraftError.onceNotInFuture});
        expect(yesterday.errors(now), {ReminderDraftError.onceNotInFuture});
        expect(nextMinute.errors(now), isEmpty);
      });

      test('on a later day may be at an earlier time of day', () {
        expect(
          draft(RepeatType.once)
              .copyWith(startDate: today.addDays(1), time: LocalTime(6, 0))
              .errors(now),
          isEmpty,
        );
      });
    });

    test('lets a repeating reminder start in the past', () {
      final details = draft(RepeatType.daily)
          .copyWith(startDate: LocalDate(2026, 1, 1))
          .toDetails(now)!;

      expect(details.schedule.startDate, LocalDate(2026, 1, 1));
    });
  });

  group('editing an existing reminder', () {
    final recurrences = <Recurrence>[
      const OneTimeRecurrence(),
      DailyRecurrence(interval: 15),
      WeeklyRecurrence(weekdays: {1, 4}, interval: 2),
      MonthlyRecurrence(days: {1, 31}, interval: 3),
      YearlyRecurrence(month: 2, day: 29),
    ];

    for (final recurrence in recurrences) {
      test('round-trips ${recurrence.runtimeType} unchanged', () {
        final end = recurrence is OneTimeRecurrence
            ? null
            : LocalDate(2027, 1, 31);
        final reminder = aReminder(
          recurrence: recurrence,
          time: LocalTime(21, 30),
          start: LocalDate(2026, 4, 1),
          end: end,
          quantity: '2 tablets',
          instruction: 'After food',
        );

        final details = ReminderDraft.fromReminder(reminder).toDetails(now)!;

        expect(details.schedule.recurrence, recurrence);
        expect(details.schedule.time, LocalTime(21, 30));
        expect(details.schedule.startDate, LocalDate(2026, 4, 1));
        expect(details.schedule.endDate, end);
        expect(details.quantity, '2 tablets');
        expect(details.instruction, 'After food');
      });
    }

    test('leaves quantity and instruction empty when there are none', () {
      final draft = ReminderDraft.fromReminder(aReminder());

      expect(draft.quantity, '');
      expect(draft.instruction, '');
    });
  });
}
