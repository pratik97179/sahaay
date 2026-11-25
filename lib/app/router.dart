import 'package:go_router/go_router.dart';

import '../features/medicines/presentation/add_medicine_page.dart';
import '../features/medicines/presentation/medicine_details_page.dart';
import '../features/medicines/presentation/medicines_page.dart';
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
          builder: (context, state) =>
              MedicineDetailsPage(medicineId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
