import '../../reminders/domain/calendar.dart';
import '../../reminders/domain/reminder.dart';
import '../domain/print.dart';
import '../domain/print_repository.dart';
import '../domain/print_rules.dart';

/// Makes a print, or undoes it if it was already made. Only the
/// person's deliberate hold calls this; nothing else creates or removes
/// prints.
final class TogglePrint {
  TogglePrint({required this._prints, required this._now});

  final PrintRepository _prints;
  final LocalDateTime Function() _now;

  /// Returns whether [reminder] is printed for [day] afterwards. A reminder
  /// that can't be printed yet is left unprinted.
  Future<bool> call(Reminder reminder, LocalDate day) async {
    if (await _prints.find(reminder.id, day) != null) {
      await _prints.remove(reminder.id, day);
      return false;
    }
    final now = _now();
    if (!canPrint(reminder, day, now)) return false;
    await _prints.add(Print(reminderId: reminder.id, day: day, madeAt: now));
    return true;
  }
}
