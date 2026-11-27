import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../medicines/domain/medicine.dart';
import '../../medicines/medicines_providers.dart';
import '../../medicines/presentation/medicine_labels.dart';
import '../../prints/domain/print_rules.dart';
import '../../prints/prints_providers.dart';
import '../../reminders/domain/calendar.dart';
import '../../reminders/domain/day_reminders.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/reminders_providers.dart';

/// One reminder on a day's ruler, with what the ruler shows about it.
final class DayEntry {
  const DayEntry(this.reminder, this.medicine, this.photo);

  final Reminder reminder;
  final Medicine medicine;
  final ImageProvider photo;

  double get hour => reminder.schedule.time.minutesSinceMidnight / 60;
  String get name => medicine.displayName;
  bool get paused => reminder.isPaused;

  /// The person's quantity and instruction, as they entered them.
  String get note => [?reminder.quantity, ?reminder.instruction].join(', ');
}

/// Now, as a local date and time.
LocalDateTime nowOf(WidgetRef ref) =>
    LocalDateTime.fromDateTime(ref.watch(clockProvider)());

/// The hour of now on [day]: the real time today; an earlier day is over.
double nowHourOn(LocalDate day, LocalDateTime now) =>
    day == now.date ? now.time.minutesSinceMidnight / 60 : 24;

/// The reminders on [day] with their medicines and photos, ordered by time.
final dayEntriesProvider = Provider.autoDispose
    .family<AsyncValue<List<DayEntry>>, LocalDate>((ref, day) {
      final reminders = ref.watch(allRemindersProvider);
      final medicines = ref.watch(medicinesProvider);
      return switch ((reminders, medicines)) {
        (AsyncData(value: final rs), AsyncData(value: final ms)) => AsyncData(
          _entries(ref, day, rs, ms),
        ),
        (AsyncError(:final error, :final stackTrace), _) ||
        (
          _,
          AsyncError(:final error, :final stackTrace),
        ) => AsyncError(error, stackTrace),
        _ => const AsyncLoading(),
      };
    });

List<DayEntry> _entries(
  Ref ref,
  LocalDate day,
  List<Reminder> reminders,
  List<Medicine> medicines,
) {
  final byId = {for (final m in medicines) m.id: m};
  final photos = ref.read(medicinePhotoStorageProvider);
  return [
    for (final r in remindersOn(day, reminders))
      if (byId[r.medicineId] case final m?)
        DayEntry(r, m, FileImage(photos.resolve(m.photoPath))),
  ];
}

/// The prints made on [day]: reminder id → the time it was made.
final dayMarksProvider = Provider.autoDispose
    .family<Map<String, LocalTime>, LocalDate>(
      (ref, day) => {
        for (final p in ref.watch(dayPrintsProvider(day)).value ?? const [])
          p.reminderId: p.madeAt.time,
      },
    );

/// Whether [entry] can be printed on [day] at [now].
bool canMark(DayEntry entry, LocalDate day, LocalDateTime now) =>
    canPrint(entry.reminder, day, now);

/// One printed day of the month in History.
final class PrintedDay {
  const PrintedDay(this.day, this.prints, this.photo);

  final int day;
  final int prints;

  /// The photo of the day's first print.
  final ImageProvider photo;
}

/// The days of [anyDay]'s month before today that have prints, most recent
/// first: History's pages.
final printedDaysProvider = Provider.autoDispose
    .family<List<PrintedDay>, LocalDate>((ref, anyDay) {
      final today = LocalDateTime.fromDateTime(ref.watch(clockProvider)()).date;
      final prints = ref.watch(monthPrintsProvider(anyDay)).value ?? const [];
      final reminders = {
        for (final r in ref.watch(allRemindersProvider).value ?? <Reminder>[])
          r.id: r,
      };
      final medicines = {
        for (final m in ref.watch(medicinesProvider).value ?? <Medicine>[])
          m.id: m,
      };
      final photos = ref.read(medicinePhotoStorageProvider);
      final byDay = <int, List<String>>{};
      for (final p in prints) {
        if (!p.day.isBefore(today)) continue;
        (byDay[p.day.day] ??= []).add(p.reminderId);
      }
      return [
        for (final day in byDay.keys.toList()..sort((a, b) => b - a))
          if (medicines[reminders[byDay[day]!.first]?.medicineId] case final m?)
            PrintedDay(
              day,
              byDay[day]!.length,
              FileImage(photos.resolve(m.photoPath)),
            ),
      ];
    });
