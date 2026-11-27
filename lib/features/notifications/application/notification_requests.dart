import '../../medicines/domain/medicine.dart';
import '../../reminders/domain/calendar.dart';
import '../../reminders/domain/reminder.dart';
import '../domain/notification_plan.dart';

/// Everything needed to schedule one notification on the device.
final class NotificationRequest {
  const NotificationRequest({
    required this.id,
    required this.reminderId,
    required this.at,
    required this.title,
    required this.body,
    this.repeat,
  });

  /// Unique among the requests scheduled together.
  final int id;

  /// The reminder this notification is for; carried as the notification's
  /// payload so a tap opens that reminder.
  final String reminderId;
  final LocalDateTime at;
  final NotificationRepeat? repeat;
  final String title;
  final String body;

  @override
  String toString() =>
      'NotificationRequest($id, $reminderId, $at, $repeat, "$title", "$body")';
}

/// The notifications that should be pending for [reminders], with their text:
/// - The title names the medicine, or says "Unnamed medicine".
/// - The body gives the reminder's quantity and instruction exactly as the
///   user entered them. When there are none, it gives the time.
///
/// Text only, and nothing about whether a dose was taken. [formatTime]
/// formats times the way the device shows them.
List<NotificationRequest> buildNotificationRequests({
  required Iterable<Reminder> reminders,
  required Map<String, Medicine> medicines,
  required LocalDateTime now,
  required String Function(LocalTime) formatTime,
  int budget = defaultNotificationBudget,
}) {
  final byId = {for (final reminder in reminders) reminder.id: reminder};
  // A reminder always belongs to a medicine; skip any that has lost it
  // rather than notify about an unknown medicine.
  final eligible = byId.values.where(
    (reminder) => medicines.containsKey(reminder.medicineId),
  );
  final plan = planNotifications(reminders: eligible, now: now, budget: budget);
  return [
    for (final (index, occurrence) in plan.indexed)
      _request(
        id: index + 1,
        occurrence: occurrence,
        reminder: byId[occurrence.reminderId]!,
        medicine: medicines[byId[occurrence.reminderId]!.medicineId]!,
        formatTime: formatTime,
      ),
  ];
}

NotificationRequest _request({
  required int id,
  required PlannedOccurrence occurrence,
  required Reminder reminder,
  required Medicine medicine,
  required String Function(LocalTime) formatTime,
}) {
  final details = [?reminder.quantity, ?reminder.instruction];
  return NotificationRequest(
    id: id,
    reminderId: reminder.id,
    at: occurrence.at,
    repeat: occurrence.repeat,
    title: medicine.name ?? 'Unnamed medicine',
    body: details.isEmpty
        ? 'Reminder for ${formatTime(reminder.schedule.time)}'
        : details.join(' · '),
  );
}
