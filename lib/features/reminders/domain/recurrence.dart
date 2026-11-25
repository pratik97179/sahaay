import 'calendar.dart';

/// Thrown when a schedule or recurrence configuration is invalid.
final class InvalidScheduleException implements Exception {
  const InvalidScheduleException(this.message);

  final String message;

  @override
  String toString() => 'InvalidScheduleException: $message';
}

/// The recurrence patterns from PRD FR-03.
sealed class Recurrence {
  const Recurrence();
}

/// Fires once, on the schedule's start date.
final class OneTimeRecurrence extends Recurrence {
  const OneTimeRecurrence();

  @override
  bool operator ==(Object other) => other is OneTimeRecurrence;

  @override
  int get hashCode => (OneTimeRecurrence).hashCode;
}

/// Every [interval] days, counted from the start date.
final class DailyRecurrence extends Recurrence {
  DailyRecurrence({this.interval = 1}) {
    _checkInterval(interval);
  }

  final int interval;

  @override
  bool operator ==(Object other) =>
      other is DailyRecurrence && other.interval == interval;

  @override
  int get hashCode => Object.hash(DailyRecurrence, interval);
}

/// On [weekdays] (ISO, Monday = 1) of every [interval]th week.
///
/// Weeks run Monday–Sunday; the start date's week is week 0.
final class WeeklyRecurrence extends Recurrence {
  WeeklyRecurrence({required Set<int> weekdays, this.interval = 1})
    : weekdays = Set.unmodifiable(weekdays) {
    _checkInterval(interval);
    if (weekdays.isEmpty) {
      throw const InvalidScheduleException('Select at least one weekday.');
    }
    if (weekdays.any((d) => d < 1 || d > 7)) {
      throw const InvalidScheduleException('Weekdays must be 1-7.');
    }
  }

  final Set<int> weekdays;
  final int interval;

  @override
  bool operator ==(Object other) =>
      other is WeeklyRecurrence &&
      other.interval == interval &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays);

  @override
  int get hashCode => Object.hash(
    WeeklyRecurrence,
    interval,
    Object.hashAllUnordered(weekdays),
  );
}

/// On [days] of every [interval]th month; the start date's month is month 0.
///
/// A day beyond a month's length fires on that month's last day, without
/// carrying over to later months (PRD FR-03).
final class MonthlyRecurrence extends Recurrence {
  MonthlyRecurrence({required Set<int> days, this.interval = 1})
    : days = Set.unmodifiable(days) {
    _checkInterval(interval);
    if (days.isEmpty) {
      throw const InvalidScheduleException('Select at least one day.');
    }
    if (days.any((d) => d < 1 || d > 31)) {
      throw const InvalidScheduleException('Days must be 1-31.');
    }
  }

  final Set<int> days;
  final int interval;

  @override
  bool operator ==(Object other) =>
      other is MonthlyRecurrence &&
      other.interval == interval &&
      other.days.length == days.length &&
      other.days.containsAll(days);

  @override
  int get hashCode =>
      Object.hash(MonthlyRecurrence, interval, Object.hashAllUnordered(days));
}

/// Every year on [month]/[day]; a day missing from the month (29 February in
/// a non-leap year) fires on the month's last day.
final class YearlyRecurrence extends Recurrence {
  YearlyRecurrence({required this.month, required this.day}) {
    if (month < 1 || month > 12) {
      throw const InvalidScheduleException('Month must be 1-12.');
    }
    if (day < 1 || day > LocalDate.daysInMonth(2024, month)) {
      throw InvalidScheduleException(
        'Day $day does not exist in month $month.',
      );
    }
  }

  final int month;
  final int day;

  @override
  bool operator ==(Object other) =>
      other is YearlyRecurrence && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(YearlyRecurrence, month, day);
}

void _checkInterval(int interval) {
  if (interval < 1) {
    throw const InvalidScheduleException('Interval must be at least 1.');
  }
}
