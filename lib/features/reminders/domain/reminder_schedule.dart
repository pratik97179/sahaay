import 'calendar.dart';
import 'recurrence.dart';

/// When a reminder fires: one time of day, a recurrence, a required start
/// date and an optional end date (PRD §3.2, FR-03).
final class ReminderSchedule {
  ReminderSchedule({
    required this.time,
    required this.recurrence,
    required this.startDate,
    this.endDate,
  }) {
    if (recurrence is OneTimeRecurrence && endDate != null) {
      throw const InvalidScheduleException(
        'A one-time reminder has no end date.',
      );
    }
    if (endDate != null && endDate!.isBefore(startDate)) {
      throw const InvalidScheduleException(
        'End date must not be before the start date.',
      );
    }
  }

  final LocalTime time;
  final Recurrence recurrence;

  /// The first day the reminder may fire. For a one-time reminder, the date
  /// it fires.
  final LocalDate startDate;

  /// The last day the reminder may fire, inclusive.
  final LocalDate? endDate;

  /// Occurrences at or after [from], in ascending order. The sequence is
  /// lazy and may be infinite when there is no end date.
  Iterable<LocalDateTime> occurrencesFrom(LocalDateTime from) sync* {
    for (final date in _datesFrom(from.date)) {
      if (endDate != null && date.isAfter(endDate!)) return;
      final occurrence = LocalDateTime(date, time);
      if (!occurrence.isBefore(from)) yield occurrence;
    }
  }

  /// The next occurrence at or after [from], or `null` when none remain.
  LocalDateTime? nextOccurrence(LocalDateTime from) {
    final it = occurrencesFrom(from).iterator;
    return it.moveNext() ? it.current : null;
  }

  /// Candidate dates in ascending order, starting no earlier than both the
  /// start date and [from].
  Iterable<LocalDate> _datesFrom(LocalDate from) {
    final first = from.isAfter(startDate) ? from : startDate;
    return switch (recurrence) {
      OneTimeRecurrence() => [startDate],
      final DailyRecurrence r => _daily(r, first),
      final WeeklyRecurrence r => _weekly(r, first),
      final MonthlyRecurrence r => _monthly(r, first),
      final YearlyRecurrence r => _yearly(r, first),
    };
  }

  Iterable<LocalDate> _daily(DailyRecurrence r, LocalDate first) sync* {
    final offset = startDate.daysUntil(first);
    final steps = (offset + r.interval - 1) ~/ r.interval;
    for (
      var date = startDate.addDays(steps * r.interval);
      ;
      date = date.addDays(r.interval)
    ) {
      yield date;
    }
  }

  Iterable<LocalDate> _weekly(WeeklyRecurrence r, LocalDate first) sync* {
    final anchorMonday = startDate.addDays(1 - startDate.weekday);
    final weekdays = r.weekdays.toList()..sort();
    var week = anchorMonday.daysUntil(first) ~/ 7;
    while (true) {
      if (week % r.interval == 0) {
        final monday = anchorMonday.addDays(week * 7);
        for (final weekday in weekdays) {
          final date = monday.addDays(weekday - 1);
          if (!date.isBefore(first)) yield date;
        }
      }
      week++;
    }
  }

  Iterable<LocalDate> _monthly(MonthlyRecurrence r, LocalDate first) sync* {
    final days = r.days.toList()..sort();
    var index = startDate.monthsUntil(first);
    while (true) {
      if (index % r.interval == 0) {
        final monthStart = startDate.month - 1 + index;
        final year = startDate.year + monthStart ~/ 12;
        final month = monthStart % 12 + 1;
        // Clamping can map several selected days to the same date.
        final dates = {
          for (final day in days) LocalDate.clamped(year, month, day),
        };
        for (final date in dates) {
          if (!date.isBefore(first)) yield date;
        }
      }
      index++;
    }
  }

  Iterable<LocalDate> _yearly(YearlyRecurrence r, LocalDate first) sync* {
    for (var year = first.year; ; year++) {
      final date = LocalDate.clamped(year, r.month, r.day);
      if (!date.isBefore(first)) yield date;
    }
  }
}
