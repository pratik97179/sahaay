import 'package:go_router/go_router.dart';

import '../features/medicines/presentation/medicines_page.dart';

/// Route paths, kept in one place so notification deep links and screens agree.
abstract final class AppRoutes {
  static const medicines = '/';
}

GoRouter createRouter() => GoRouter(
  initialLocation: AppRoutes.medicines,
  routes: [
    GoRoute(
      path: AppRoutes.medicines,
      builder: (context, state) => const MedicinesPage(),
    ),
  ],
);
