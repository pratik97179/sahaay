import 'package:flutter/material.dart';

import '../domain/calendar.dart';
import '../domain/recurrence.dart';
import '../domain/reminder_schedule.dart';

/// Plain-language descriptions of reminder schedules, in English.

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The weekday's three-letter name; [weekday] is ISO, Monday = 1.
String shortWeekdayName(int weekday) =>
    weekdayNames[weekday - 1].substring(0, 3);

/// How often [schedule] repeats, for example "Every 2 weeks on Monday and
/// Thursday". [formatDate] formats the date of a one-time reminder.
String describeSchedule(
  ReminderSchedule schedule, {
  required String Function(LocalDate) formatDate,
}) => switch (schedule.recurrence) {
  OneTimeRecurrence() => 'Once on ${formatDate(schedule.startDate)}',
  DailyRecurrence(:final interval) =>
    interval == 1 ? 'Every day' : 'Every $interval days',
  WeeklyRecurrence(:final weekdays, :final interval) =>
    '${_every(interval, 'week')} on ${_weekdayList(weekdays)}',
  MonthlyRecurrence(:final days, :final interval) =>
    '${_every(interval, 'month')} on the ${_list([for (final d in days.toList()..sort()) ordinal(d)])}',
  YearlyRecurrence(:final month, :final day) =>
    'Every year on $day ${monthNames[month - 1]}',
};

/// Explains month-end clamping (PRD FR-03) when it applies to [recurrence],
/// otherwise `null`.
String? monthEndNote(Recurrence recurrence) => switch (recurrence) {
  MonthlyRecurrence(:final days) => monthDaysNote(days),
  YearlyRecurrence(month: 2, day: 29) => leapDayNote,
  _ => null,
};

/// The note for a yearly reminder on 29 February.
const leapDayNote = 'In years without 29 February, it is on 28 February.';

/// The note for selected days of the month, or `null` when every selected
/// day exists in every month.
String? monthDaysNote(Set<int> days) => days.any((d) => d > 28)
    ? 'In months without the ${_list([for (final d in days.where((d) => d > 28).toList()..sort()) ordinal(d)], conjunction: 'or')}, '
          'it is on the last day of the month.'
    : null;

/// 1st, 2nd, 3rd, 4th … 11th, 12th, 13th … 21st, 22nd, 23rd … 31st.
String ordinal(int n) {
  final suffix = (n % 100 >= 11 && n % 100 <= 13)
      ? 'th'
      : switch (n % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return '$n$suffix';
}

String _every(int interval, String unit) =>
    interval == 1 ? 'Every $unit' : 'Every $interval ${unit}s';

/// Up to two weekdays by full name; more by short name so the line stays
/// readable.
String _weekdayList(Set<int> weekdays) {
  final sorted = weekdays.toList()..sort();
  return _list([
    for (final d in sorted)
      sorted.length <= 2 ? weekdayNames[d - 1] : shortWeekdayName(d),
  ]);
}

String _list(List<String> items, {String conjunction = 'and'}) =>
    items.length <= 1
    ? items.join()
    : '${items.sublist(0, items.length - 1).join(', ')} $conjunction ${items.last}';

/// Formats a time of day the way the device is set up, 12- or 24-hour.
String formatTime(BuildContext context, LocalTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: time.hour, minute: time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// Formats a date in full, for example "Tuesday, March 10, 2026".
String formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(context)
        .formatFullDate(DateTime(date.year, date.month, date.day));
