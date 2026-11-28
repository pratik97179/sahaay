// Where the medicines feature's destinations sit and what they show
// (docs/architecture.md, Navigation).
import 'package:flutter/widgets.dart';

import '../../core/navigation/screen_route.dart';
import '../day/day_destinations.dart';
import 'medicines_destinations.dart';
import 'presentation/add_medicine_extras.dart';
import 'presentation/medicine_details_page.dart';
import 'presentation/new_medicine_page.dart';
import 'presentation/your_medicines_page.dart';

/// The medicines screens. The app fills the two places another feature
/// adds to them: a medicine's reminders, and the reminders made while
/// adding a medicine.
List<ScreenRoute> medicinesScreens({
  required Widget Function(String medicineId) remindersOf,
  required CreateAddMedicineExtras addMedicineExtras,
}) => [
  ScreenRoute<MedicinesDestination>(
    path: 'medicines',
    parent: TodayDestination,
    decode: (_) => const MedicinesDestination(),
    build: (_) => const YourMedicinesPage(),
  ),
  ScreenRoute<AddMedicineDestination>(
    path: 'new',
    parent: MedicinesDestination,
    decode: (_) => const AddMedicineDestination(),
    build: (_) => NewMedicinePage(createExtras: addMedicineExtras),
  ),
  ScreenRoute<MedicineDestination>(
    path: ':id',
    parent: MedicinesDestination,
    decode: (v) => MedicineDestination(v['id']!),
    encode: (d) => {'id': d.medicineId},
    build: (d) => MedicineDetailsPage(
      medicineId: d.medicineId,
      reminders: remindersOf(d.medicineId),
    ),
  ),
];
