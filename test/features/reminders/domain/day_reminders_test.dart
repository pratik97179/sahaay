import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/day_reminders.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';

import '../../../support/builders.dart';

void main() {
  // Tuesday 10 March 2026.
  final day = LocalDate(2026, 3, 10);
  final past = LocalDate(2026, 1, 1);

  test('keeps the reminders that fall on the day, ordered by time', () {
    final result = remindersOn(day, [
      aReminder(id: 'evening', start: past, time: LocalTime(21, 0)),
      aReminder(id: 'morning', start: past, time: LocalTime(7, 30)),
      aReminder(
        id: 'thursdays',
        start: past,
        recurrence: WeeklyRecurrence(weekdays: {4}),
      ),
      aReminder(
        id: 'tuesdays',
        start: past,
        recurrence: WeeklyRecurrence(weekdays: {2}),
      ),
    ]);

    expect(result.map((r) => r.id), ['morning', 'tuesdays', 'evening']);
  });

  test('respects start and end dates and one-time days', () {
    final result = remindersOn(day, [
      aReminder(id: 'not-started', start: LocalDate(2026, 3, 11)),
      aReminder(id: 'ended', start: past, end: LocalDate(2026, 3, 9)),
      aReminder(id: 'ends-today', start: past, end: day),
      aReminder(
        id: 'once-today',
        start: day,
        recurrence: const OneTimeRecurrence(),
      ),
      aReminder(
        id: 'once-tomorrow',
        start: LocalDate(2026, 3, 11),
        recurrence: const OneTimeRecurrence(),
      ),
    ]);

    expect(result.map((r) => r.id), containsAll(['ends-today', 'once-today']));
    expect(result, hasLength(2));
  });

  test('includes paused reminders; they are shown as paused', () {
    expect(
      remindersOn(day, [aReminder(start: past, paused: true)]),
      hasLength(1),
    );
  });

  test('orders reminders at the same time by id', () {
    final result = remindersOn(day, [
      aReminder(id: 'b', start: past),
      aReminder(id: 'a', start: past),
    ]);

    expect(result.map((r) => r.id), ['a', 'b']);
  });

  test('a day at a month end follows month-end clamping', () {
    final result = remindersOn(LocalDate(2026, 4, 30), [
      aReminder(
        start: past,
        recurrence: MonthlyRecurrence(days: {31}),
      ),
    ]);

    expect(result, hasLength(1));
  });
}
