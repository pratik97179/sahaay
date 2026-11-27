import 'calendar.dart';
import 'reminder.dart';

/// The reminders that fall on [day], ordered by time of day, then id.
///
/// A paused reminder still falls on its days; it is shown as paused, not
/// left out.
List<Reminder> remindersOn(LocalDate day, Iterable<Reminder> reminders) {
  final dayStart = LocalDateTime(day, LocalTime(0, 0));
  return [
    for (final reminder in reminders)
      if (reminder.schedule.nextOccurrence(dayStart)?.date == day) reminder,
  ]..sort((a, b) {
    final byTime = a.schedule.time.compareTo(b.schedule.time);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
}
