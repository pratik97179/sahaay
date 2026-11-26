import '../../reminders/domain/calendar.dart';
import '../../reminders/domain/reminder.dart';

/// How early before its time a reminder can be printed (PRD FR-11).
const printWindowBefore = Duration(minutes: 30);

/// Whether [reminder] can be printed for [day] at [now] (PRD FR-11, AC-16):
/// never while paused; on an earlier day, always; today, from
/// [printWindowBefore] before its time.
bool canPrint(Reminder reminder, LocalDate day, LocalDateTime now) {
  if (reminder.isPaused) return false;
  if (day.isBefore(now.date)) return true;
  if (day.isAfter(now.date)) return false;
  final opens =
      reminder.schedule.time.minutesSinceMidnight - printWindowBefore.inMinutes;
  return now.time.minutesSinceMidnight >= opens;
}
