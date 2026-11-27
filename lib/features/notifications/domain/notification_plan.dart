import '../../reminders/domain/calendar.dart';
import '../../reminders/domain/recurrence.dart';
import '../../reminders/domain/reminder.dart';

/// How a scheduled notification repeats, in terms the operating system can
/// repeat on its own without the app running.
enum NotificationRepeat {
  /// Every day at the same time.
  daily,

  /// Every week on the same weekday and time.
  weekly,

  /// Every month on the same day of the month and time.
  monthly,

  /// Every year on the same month, day and time.
  yearly,
}

/// One notification that should be pending for a reminder.
final class PlannedOccurrence {
  const PlannedOccurrence({
    required this.reminderId,
    required this.at,
    this.repeat,
  });

  final String reminderId;

  /// When it first fires, in the device's local time.
  final LocalDateTime at;

  /// How the operating system repeats it after [at], or `null` for a single
  /// notification.
  final NotificationRepeat? repeat;

  @override
  bool operator ==(Object other) =>
      other is PlannedOccurrence &&
      other.reminderId == reminderId &&
      other.at == at &&
      other.repeat == repeat;

  @override
  int get hashCode => Object.hash(reminderId, at, repeat);

  @override
  String toString() =>
      'PlannedOccurrence($reminderId, $at${repeat == null ? '' : ', $repeat'})';
}

/// Decides which notifications should be pending, so they can be handed to
/// the operating system (implementation plan §9).
///
/// The operating system only knows about notifications scheduled in advance,
/// and iOS keeps at most 64 per app. So:
/// - A reminder the operating system can repeat exactly, forever, is
///   scheduled once as a repeating notification (one per weekday or day of
///   the month). That is every day, every week, every month on days 1–28, or
///   every year (except 29 February), with no end date, that has already
///   started.
/// - Every other reminder is scheduled as single notifications for its next
///   occurrences, earliest first across all reminders, until [budget] is
///   used. The app tops these up whenever it runs.
///
/// Paused reminders, and reminders with no occurrences left, get nothing.
/// The result is ordered by time, then reminder id, so it is deterministic.
List<PlannedOccurrence> planNotifications({
  required Iterable<Reminder> reminders,
  required LocalDateTime now,
  int budget = defaultNotificationBudget,
}) {
  // Notifications fire at whole minutes; the current minute has passed.
  final from = _nextMinute(now);
  final repeating = <PlannedOccurrence>[];
  final single = <Reminder>[];

  for (final reminder in reminders) {
    if (reminder.isPaused) continue;
    final planned = _repeating(reminder, from);
    if (planned != null) {
      repeating.addAll(planned);
    } else {
      single.add(reminder);
    }
  }

  repeating.sort(_byTimeThenReminder);
  final plan = repeating.take(budget).toList();
  plan.addAll(_earliestOccurrences(single, from, budget - plan.length));
  return plan..sort(_byTimeThenReminder);
}

/// Leaves room under iOS's limit of 64 pending notifications per app.
const defaultNotificationBudget = 60;

/// The repeating notifications for [reminder], or `null` when the operating
/// system cannot repeat it exactly.
List<PlannedOccurrence>? _repeating(Reminder reminder, LocalDateTime from) {
  final schedule = reminder.schedule;
  // An end date needs the repeats to stop. A future start date needs them
  // not to begin early: iOS repeats match from the moment they are
  // scheduled, not from the first date.
  if (schedule.endDate != null || schedule.startDate.isAfter(from.date)) {
    return null;
  }
  final time = schedule.time;

  PlannedOccurrence next(
    NotificationRepeat repeat,
    bool Function(LocalDate) matches,
  ) {
    var date = from.date;
    while (!matches(date) || LocalDateTime(date, time).isBefore(from)) {
      date = date.addDays(1);
    }
    return PlannedOccurrence(
      reminderId: reminder.id,
      at: LocalDateTime(date, time),
      repeat: repeat,
    );
  }

  return switch (schedule.recurrence) {
    DailyRecurrence(interval: 1) => [
      next(NotificationRepeat.daily, (_) => true),
    ],
    WeeklyRecurrence(interval: 1, :final weekdays) => [
      for (final weekday in weekdays)
        next(NotificationRepeat.weekly, (d) => d.weekday == weekday),
    ],
    MonthlyRecurrence(interval: 1, :final days)
        when days.every((d) => d <= 28) =>
      [
        for (final day in days)
          next(NotificationRepeat.monthly, (d) => d.day == day),
      ],
    YearlyRecurrence(:final month, :final day)
        when !(month == 2 && day == 29) =>
      [
        next(
          NotificationRepeat.yearly,
          (d) => d.month == month && d.day == day,
        ),
      ],
    _ => null,
  };
}

/// Up to [count] occurrences of [reminders], earliest first, merged across
/// reminders so no single reminder crowds out the others' next times.
List<PlannedOccurrence> _earliestOccurrences(
  List<Reminder> reminders,
  LocalDateTime from,
  int count,
) {
  if (count <= 0) return const [];
  final iterators = [
    for (final reminder in reminders)
      (reminder.id, reminder.schedule.occurrencesFrom(from).iterator),
  ];
  final heads = <(String, Iterator<LocalDateTime>)>[
    for (final entry in iterators)
      if (entry.$2.moveNext()) entry,
  ];
  final result = <PlannedOccurrence>[];
  while (result.length < count && heads.isNotEmpty) {
    heads.sort(
      (a, b) => a.$2.current.compareTo(b.$2.current) != 0
          ? a.$2.current.compareTo(b.$2.current)
          : a.$1.compareTo(b.$1),
    );
    final (id, iterator) = heads.first;
    result.add(PlannedOccurrence(reminderId: id, at: iterator.current));
    if (!iterator.moveNext()) heads.removeAt(0);
  }
  return result;
}

LocalDateTime _nextMinute(LocalDateTime now) {
  final minutes = now.time.minutesSinceMidnight + 1;
  return minutes == 24 * 60
      ? LocalDateTime(now.date.addDays(1), LocalTime(0, 0))
      : LocalDateTime(now.date, LocalTime(minutes ~/ 60, minutes % 60));
}

int _byTimeThenReminder(PlannedOccurrence a, PlannedOccurrence b) {
  final byTime = a.at.compareTo(b.at);
  return byTime != 0 ? byTime : a.reminderId.compareTo(b.reminderId);
}
