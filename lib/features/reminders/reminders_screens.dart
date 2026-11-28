// Where the reminders feature's destinations sit and what they show
// (docs/architecture.md, Navigation).
import '../../core/navigation/screen_route.dart';
import '../day/day_destinations.dart';
import '../medicines/medicines_destinations.dart';
import 'presentation/new_reminder_page.dart';
import 'presentation/reminder_page.dart';
import 'reminders_destinations.dart';

final List<ScreenRoute> remindersScreens = [
  // Under Today, so a notification that opens it still has somewhere to
  // go back to.
  ScreenRoute<ReminderDestination>(
    path: 'reminders/:id',
    parent: TodayDestination,
    decode: (v) => ReminderDestination(v['id']!),
    encode: (d) => {'id': d.reminderId},
    build: (d) => ReminderPage(reminderId: d.reminderId),
  ),
  // Shares its medicine's `:id`.
  ScreenRoute<NewReminderDestination>(
    path: 'reminders/new',
    parent: MedicineDestination,
    decode: (v) => NewReminderDestination(v['id']!),
    encode: (d) => {'id': d.medicineId},
    build: (d) => NewReminderPage(medicineId: d.medicineId),
  ),
];
