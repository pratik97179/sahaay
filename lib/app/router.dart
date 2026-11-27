import 'package:go_router/go_router.dart';

import '../core/time/clock.dart';
import '../features/day/presentation/day_page.dart';
import '../features/medicines/presentation/medicine_details_page.dart';
import '../features/medicines/presentation/new_medicine_page.dart';
import '../features/medicines/presentation/your_medicines_page.dart';
import '../features/reminders/domain/calendar.dart';
import '../features/reminders/presentation/edit_reminder_page.dart';
import '../features/reminders/presentation/medicine_reminders_section.dart';
import '../features/reminders/presentation/new_medicine_reminders.dart';
import '../features/reminders/presentation/new_reminder_page.dart';
import '../features/reminders/presentation/reminder_page.dart';
import '../features/reminders/reminders_providers.dart';
import 'routes.dart';

GoRouter createRouter({String initialLocation = AppRoutes.today}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: AppRoutes.today,
      builder: (context, state) => const DayPage(),
      routes: [
        GoRoute(
          path: 'medicines',
          builder: (context, state) => const YourMedicinesPage(),
          routes: [
            // Listed before `:id` so "new" is not read as an id.
            GoRoute(
              path: 'new',
              builder: (context, state) => NewMedicinePage(
                createExtras: (ref) => NewMedicineReminders(
                  createReminder: ref.read(createReminderProvider),
                  now: () =>
                      LocalDateTime.fromDateTime(ref.read(clockProvider)()),
                ),
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return MedicineDetailsPage(
                  medicineId: id,
                  reminders: MedicineRemindersSection(medicineId: id),
                );
              },
              routes: [
                GoRoute(
                  path: 'reminders/new',
                  builder: (context, state) =>
                      NewReminderPage(medicineId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        // A reminder's entry screen. Nested under Today so a notification
        // that opens it directly still has somewhere to go back.
        GoRoute(
          path: 'reminders/:id',
          builder: (context, state) =>
              ReminderPage(reminderId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  EditReminderPage(reminderId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),
  ],
);
