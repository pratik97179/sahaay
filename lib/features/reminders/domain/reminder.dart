import 'calendar.dart';
import 'reminder_schedule.dart';

/// A reminder for one medicine at one time of day.
///
/// [quantity] and [instruction] are free text recorded exactly as the user
/// entered them; Sahaay never interprets or validates them.
final class Reminder {
  Reminder({
    required this.id,
    required this.medicineId,
    required this.schedule,
    String? quantity,
    String? instruction,
    this.isPaused = false,
  }) : quantity = _blankToNull(quantity),
       instruction = _blankToNull(instruction);

  final String id;
  final String medicineId;
  final ReminderSchedule schedule;
  final String? quantity;
  final String? instruction;
  final bool isPaused;

  /// The next time this reminder should notify, or `null` when it is paused
  /// or has no occurrences left.
  LocalDateTime? nextNotification(LocalDateTime now) =>
      isPaused ? null : schedule.nextOccurrence(now);

  /// Whether no occurrences remain at or after [now], regardless of pause.
  bool isFinished(LocalDateTime now) => schedule.nextOccurrence(now) == null;

  Reminder copyWith({
    ReminderSchedule? schedule,
    String? Function()? quantity,
    String? Function()? instruction,
    bool? isPaused,
  }) => Reminder(
    id: id,
    medicineId: medicineId,
    schedule: schedule ?? this.schedule,
    quantity: quantity != null ? quantity() : this.quantity,
    instruction: instruction != null ? instruction() : this.instruction,
    isPaused: isPaused ?? this.isPaused,
  );
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
