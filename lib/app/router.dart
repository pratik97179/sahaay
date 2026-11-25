import 'package:go_router/go_router.dart';

import '../features/medicines/presentation/add_medicine_page.dart';
import '../features/medicines/presentation/medicine_details_page.dart';
import '../features/medicines/presentation/medicines_page.dart';
import '../features/reminders/presentation/edit_reminder_page.dart';
import '../features/reminders/presentation/medicine_reminders_section.dart';
import '../features/reminders/presentation/new_reminder_page.dart';
import '../features/reminders/presentation/reminder_page.dart';
import 'routes.dart';

GoRouter createRouter() => GoRouter(
  initialLocation: AppRoutes.medicines,
  routes: [
    GoRoute(
      path: AppRoutes.medicines,
      builder: (context, state) => const MedicinesPage(),
      routes: [
        // Listed before `medicines/:id` so "new" is not read as an id.
        GoRoute(
          path: 'medicines/new',
          builder: (context, state) => const AddMedicinePage(),
        ),
        GoRoute(
          path: 'medicines/:id',
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
        // A reminder's entry screen. Nested under the medicines list so a
        // notification that opens it directly still has somewhere to go back.
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
