import '../../reminders/domain/calendar.dart';

/// The person's own record that they took one reminder's dose on one day
/// (PRD §3.3). Sahaay never creates, infers or removes one on its own.
final class Print {
  const Print({
    required this.reminderId,
    required this.day,
    required this.madeAt,
  });

  final String reminderId;
  final LocalDate day;

  /// When the person made it.
  final LocalDateTime madeAt;
}
