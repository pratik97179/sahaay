import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/notifications/domain/notification_plan.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';

import '../../../support/builders.dart';

void main() {
  // Tuesday 10 March 2026, 8:00 AM.
  final now = LocalDateTime(LocalDate(2026, 3, 10), LocalTime(8, 0));
  final past = LocalDate(2026, 1, 1);

  LocalDateTime at(int month, int day, int hour, [int minute = 0, int? year]) =>
      LocalDateTime(
        LocalDate(year ?? 2026, month, day),
        LocalTime(hour, minute),
      );

  PlannedOccurrence single(String id, LocalDateTime when) =>
      PlannedOccurrence(reminderId: id, at: when);

  PlannedOccurrence repeating(
    String id,
    LocalDateTime when,
    NotificationRepeat repeat,
  ) => PlannedOccurrence(reminderId: id, at: when, repeat: repeat);

  group('repeating notifications the system can keep on its own', () {
    test('every day: one daily notification, next at today\'s time', () {
      final plan = planNotifications(
        reminders: [aReminder(start: past, time: LocalTime(9, 0))],
        now: now,
      );

      expect(plan, [repeating('r1', at(3, 10, 9), NotificationRepeat.daily)]);
    });

    test('a time already passed today starts tomorrow', () {
      final plan = planNotifications(
        reminders: [aReminder(start: past, time: LocalTime(7, 30))],
        now: now,
      );

      expect(plan.single.at, at(3, 11, 7, 30));
    });

    test('the current minute counts as passed', () {
      final plan = planNotifications(
        reminders: [aReminder(start: past, time: LocalTime(8, 0))],
        now: now,
      );

      expect(plan.single.at, at(3, 11, 8));
    });

    test('every week: one weekly notification per chosen day', () {
      final plan = planNotifications(
        reminders: [
          aReminder(
            start: past,
            recurrence: WeeklyRecurrence(weekdays: {1, 4}),
          ),
        ],
        now: now,
      );

      expect(plan, [
        repeating('r1', at(3, 12, 9), NotificationRepeat.weekly), // Thu
        repeating('r1', at(3, 16, 9), NotificationRepeat.weekly), // Mon
      ]);
    });

    test('every month on days up to the 28th: one per day', () {
      final plan = planNotifications(
        reminders: [
          aReminder(
            start: past,
            recurrence: MonthlyRecurrence(days: {1, 15}),
          ),
        ],
        now: now,
      );

      expect(plan, [
        repeating('r1', at(3, 15, 9), NotificationRepeat.monthly),
        repeating('r1', at(4, 1, 9), NotificationRepeat.monthly),
      ]);
    });

    test('every year', () {
      final plan = planNotifications(
        reminders: [
          aReminder(
            start: past,
            recurrence: YearlyRecurrence(month: 6, day: 5),
          ),
        ],
        now: now,
      );

      expect(plan, [repeating('r1', at(6, 5, 9), NotificationRepeat.yearly)]);
    });
  });

  group('single notifications for schedules the system cannot repeat', () {
    test('every N days', () {
      final plan = planNotifications(
        reminders: [
          aReminder(
            start: LocalDate(2026, 3, 9),
            recurrence: DailyRecurrence(interval: 15),
          ),
        ],
        now: now,
        budget: 3,
      );

      expect(plan, [
        single('r1', at(3, 24, 9)),
        single('r1', at(4, 8, 9)),
        single('r1', at(4, 23, 9)),
      ]);
    });

    test('every N weeks', () {
      final plan = planNotifications(
        reminders: [
          aReminder(
            start: LocalDate(2026, 3, 9),
            recurrence: WeeklyRecurrence(weekdays: {1}, interval: 2),
          ),
        ],
        now: now,
        budget: 2,
      );

      expect(plan, [single('r1', at(3, 23, 9)), single('r1', at(4, 6, 9))]);
    });

    test('the 31st falls on the last day of shorter months (AC-12)', () {
      final plan = planNotifications(
        reminders: [
          aReminder(
            start: past,
            recurrence: MonthlyRecurrence(days: {31}),
          ),
        ],
        now: now,
        budget: 4,
      );

      expect(plan.map((p) => p.at), [
        at(3, 31, 9),
        at(4, 30, 9),
        at(5, 31, 9),
        at(6, 30, 9),
      ]);
      expect(plan.every((p) => p.repeat == null), isTrue);
    });

    test('29 February falls on the 28th in other years', () {
      final plan = planNotifications(
        reminders: [
          aReminder(
            start: past,
            recurrence: YearlyRecurrence(month: 2, day: 29),
          ),
        ],
        now: now,
        budget: 3,
      );

      expect(plan.map((p) => p.at), [
        at(2, 28, 9, 0, 2027),
        at(2, 29, 9, 0, 2028),
        at(2, 28, 9, 0, 2029),
      ]);
    });

    test('nothing after the end date (AC-11)', () {
      final plan = planNotifications(
        reminders: [aReminder(start: past, end: LocalDate(2026, 3, 12))],
        now: now,
      );

      expect(plan, [
        single('r1', at(3, 10, 9)),
        single('r1', at(3, 11, 9)),
        single('r1', at(3, 12, 9)),
      ]);
    });

    test('nothing before a future start date (AC-11)', () {
      final plan = planNotifications(
        reminders: [aReminder(start: LocalDate(2026, 3, 20))],
        now: now,
        budget: 2,
      );

      expect(plan, [single('r1', at(3, 20, 9)), single('r1', at(3, 21, 9))]);
    });

    test('a one-time reminder in the future', () {
      final plan = planNotifications(
        reminders: [
          aReminder(
            start: LocalDate(2026, 3, 11),
            recurrence: const OneTimeRecurrence(),
          ),
        ],
        now: now,
      );

      expect(plan, [single('r1', at(3, 11, 9))]);
    });
  });

  group('nothing is planned', () {
    test('for a paused reminder (AC-08)', () {
      expect(
        planNotifications(reminders: [aReminder(paused: true)], now: now),
        isEmpty,
      );
      expect(
        planNotifications(
          reminders: [
            aReminder(paused: true, start: past, end: LocalDate(2026, 4, 1)),
          ],
          now: now,
        ),
        isEmpty,
      );
    });

    test('for a one-time reminder that has passed', () {
      expect(
        planNotifications(
          reminders: [
            aReminder(
              start: LocalDate(2026, 3, 9),
              recurrence: const OneTimeRecurrence(),
            ),
          ],
          now: now,
        ),
        isEmpty,
      );
    });

    test('for a reminder whose end date has passed', () {
      expect(
        planNotifications(
          reminders: [aReminder(start: past, end: LocalDate(2026, 3, 1))],
          now: now,
        ),
        isEmpty,
      );
    });
  });

  group('several reminders', () {
    test('are planned independently, ordered by time then reminder', () {
      final plan = planNotifications(
        reminders: [
          aReminder(id: 'evening', start: past, time: LocalTime(21, 0)),
          aReminder(id: 'morning', start: past, time: LocalTime(9, 0)),
          aReminder(id: 'paused', start: past, paused: true),
        ],
        now: now,
      );

      expect(plan, [
        repeating('morning', at(3, 10, 9), NotificationRepeat.daily),
        repeating('evening', at(3, 10, 21), NotificationRepeat.daily),
      ]);
    });

    test('share the budget earliest first, so none crowds out the others', () {
      final plan = planNotifications(
        reminders: [
          aReminder(
            id: 'a',
            start: past,
            end: LocalDate(2026, 12, 31),
            time: LocalTime(9, 0),
          ),
          aReminder(
            id: 'b',
            start: past,
            end: LocalDate(2026, 12, 31),
            time: LocalTime(21, 0),
          ),
          // Repeating: always planned, and counted against the budget.
          aReminder(id: 'c', start: past, time: LocalTime(12, 0)),
        ],
        now: now,
        budget: 5,
      );

      expect(plan, [
        single('a', at(3, 10, 9)),
        repeating('c', at(3, 10, 12), NotificationRepeat.daily),
        single('b', at(3, 10, 21)),
        single('a', at(3, 11, 9)),
        single('b', at(3, 11, 21)),
      ]);
    });

    test('never exceed the budget', () {
      final reminders = [
        for (var i = 0; i < 10; i++)
          aReminder(
            id: 'r$i',
            start: past,
            recurrence: WeeklyRecurrence(weekdays: {1, 2, 3, 4, 5, 6, 7}),
          ),
      ];

      expect(planNotifications(reminders: reminders, now: now), hasLength(60));
      expect(
        planNotifications(reminders: reminders, now: now, budget: 8),
        hasLength(8),
      );
    });

    test('ties in time are ordered by reminder id', () {
      final plan = planNotifications(
        reminders: [
          aReminder(id: 'b', start: past, end: LocalDate(2026, 3, 10)),
          aReminder(id: 'a', start: past, end: LocalDate(2026, 3, 10)),
        ],
        now: now,
      );

      expect(plan.map((p) => p.reminderId), ['a', 'b']);
    });
  });

  test('a reminder just before midnight is planned for the next day', () {
    final lateNow = LocalDateTime(LocalDate(2026, 3, 10), LocalTime(23, 59));
    final plan = planNotifications(
      reminders: [aReminder(start: past, time: LocalTime(0, 0))],
      now: lateNow,
    );

    expect(plan.single.at, at(3, 11, 0));
  });
}
