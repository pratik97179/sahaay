import '../core/navigation/screen_route.dart';
import '../core/time/clock.dart';
import '../features/day/day_screens.dart';
import '../features/medicines/medicines_screens.dart';
import '../features/reminders/domain/calendar.dart';
import '../features/reminders/presentation/medicine_reminders_section.dart';
import '../features/reminders/presentation/new_medicine_reminders.dart';
import '../features/reminders/reminders_providers.dart';
import '../features/reminders/reminders_screens.dart';

/// Every screen of the app: one line per feature, written when the feature
/// is added. A new screen goes in its own feature's `*_screens.dart`, never
/// here (docs/architecture.md, Navigation).
List<ScreenRoute> appScreens() => [
  ...dayScreens,
  ...medicinesScreens(
    remindersOf: (id) => MedicineRemindersSection(medicineId: id),
    addMedicineExtras: (ref) => NewMedicineReminders(
      createReminder: ref.read(createReminderProvider),
      now: () => LocalDateTime.fromDateTime(ref.read(clockProvider)()),
    ),
  ),
  ...remindersScreens,
];
