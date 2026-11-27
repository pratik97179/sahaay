/// Calendar value types with no time zone, so recurrence rules stay
/// deterministic and independent of the device clock.
library;

/// A calendar date without time or zone.
final class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be 1-12');
    }
    if (day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError.value(day, 'day', 'invalid for $year-$month');
    }
  }

  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate(dateTime.year, dateTime.month, dateTime.day);

  /// Builds a date in [month] of [year], using the month's last day when
  /// [day] is larger than the month (month-end clamping).
  factory LocalDate.clamped(int year, int month, int day) =>
      LocalDate(year, month, day.clamp(1, daysInMonth(year, month)));

  final int year;
  final int month;
  final int day;

  /// ISO weekday: Monday = 1 … Sunday = 7.
  int get weekday => _utc.weekday;

  DateTime get _utc => DateTime.utc(year, month, day);

  LocalDate addDays(int days) =>
      LocalDate.fromDateTime(_utc.add(Duration(days: days)));

  /// Whole days from this date to [other] (positive when [other] is later).
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  /// Months from this date's month to [other]'s month, ignoring days.
  int monthsUntil(LocalDate other) =>
      (other.year - year) * 12 + (other.month - month);

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  static int daysInMonth(int year, int month) => switch (month) {
    2 => isLeapYear(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };

  @override
  int compareTo(LocalDate other) => year != other.year
      ? year.compareTo(other.year)
      : month != other.month
      ? month.compareTo(other.month)
      : day.compareTo(other.day);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

/// A wall-clock time of day (minute precision).
final class LocalTime implements Comparable<LocalTime> {
  LocalTime(this.hour, this.minute) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be 0-23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'must be 0-59');
    }
  }

  final int hour;
  final int minute;

  int get minutesSinceMidnight => hour * 60 + minute;

  @override
  int compareTo(LocalTime other) =>
      minutesSinceMidnight.compareTo(other.minutesSinceMidnight);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// A wall-clock date and time without zone.
final class LocalDateTime implements Comparable<LocalDateTime> {
  const LocalDateTime(this.date, this.time);

  factory LocalDateTime.fromDateTime(DateTime dateTime) => LocalDateTime(
    LocalDate.fromDateTime(dateTime),
    LocalTime(dateTime.hour, dateTime.minute),
  );

  final LocalDate date;
  final LocalTime time;

  @override
  int compareTo(LocalDateTime other) {
    final byDate = date.compareTo(other.date);
    return byDate != 0 ? byDate : time.compareTo(other.time);
  }

  bool isBefore(LocalDateTime other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is LocalDateTime && other.date == date && other.time == time;

  @override
  int get hashCode => Object.hash(date, time);

  @override
  String toString() => '${date}T$time';
}
