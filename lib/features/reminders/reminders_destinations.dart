// The reminders feature's screens, for anyone to open
// (docs/architecture.md, Navigation).
import '../../core/navigation/destination.dart';

/// A saved reminder's page. Also where a tapped notification lands.
final class ReminderDestination extends Destination {
  const ReminderDestination(this.reminderId);
  final String reminderId;
}

/// Adds reminders to a medicine.
final class NewReminderDestination extends Destination {
  const NewReminderDestination(this.medicineId);
  final String medicineId;
}
