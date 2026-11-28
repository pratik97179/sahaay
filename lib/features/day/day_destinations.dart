// The day feature's screens, for anyone to open (docs/architecture.md,
// Navigation).
import '../../core/navigation/destination.dart';
import '../reminders/domain/calendar.dart';

/// Today, the home screen and the root of every other screen.
final class TodayDestination extends Destination {
  const TodayDestination();
}

/// History: the month's prints as a flipbook and a calendar.
final class HistoryDestination extends Destination {
  const HistoryDestination();
}

/// An earlier day's ruler, opened from History.
final class PastDayDestination extends Destination {
  const PastDayDestination(this.day);
  final LocalDate day;
}

/// A reminder on a day's ruler: its photo, to print or unprint.
final class DayReminderDestination extends Destination {
  const DayReminderDestination({required this.day, required this.reminderId});
  final LocalDate day;
  final String reminderId;
}
