import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../core/time/clock.dart';
import '../reminders/domain/calendar.dart';
import 'application/toggle_print.dart';
import 'data/drift_print_repository.dart';
import 'domain/print.dart';
import 'domain/print_repository.dart';

final printRepositoryProvider = Provider<PrintRepository>(
  (ref) => DriftPrintRepository(ref.watch(appDatabaseProvider)),
);

final togglePrintProvider = Provider<TogglePrint>(
  (ref) => TogglePrint(
    prints: ref.watch(printRepositoryProvider),
    now: () => LocalDateTime.fromDateTime(ref.read(clockProvider)()),
  ),
);

/// The prints made for one day.
final dayPrintsProvider = StreamProvider.autoDispose
    .family<List<Print>, LocalDate>(
      (ref, day) => ref.watch(printRepositoryProvider).watchDay(day),
    );

/// The prints made in one month (any day of it identifies the month).
final monthPrintsProvider = StreamProvider.autoDispose
    .family<List<Print>, LocalDate>((ref, anyDay) {
      final first = LocalDate(anyDay.year, anyDay.month, 1);
      final last = LocalDate(
        anyDay.year,
        anyDay.month,
        LocalDate.daysInMonth(anyDay.year, anyDay.month),
      );
      return ref.watch(printRepositoryProvider).watchBetween(first, last);
    });
