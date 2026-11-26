import '../../reminders/domain/calendar.dart';
import 'print.dart';

/// Persistence contract for prints.
abstract interface class PrintRepository {
  /// The prints made for [day].
  Stream<List<Print>> watchDay(LocalDate day);

  /// The prints made for days from [from] to [to], inclusive.
  Stream<List<Print>> watchBetween(LocalDate from, LocalDate to);

  Future<Print?> find(String reminderId, LocalDate day);

  Future<void> add(Print print);

  Future<void> remove(String reminderId, LocalDate day);
}
