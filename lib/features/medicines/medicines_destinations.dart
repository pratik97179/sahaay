// The medicines feature's screens, for anyone to open
// (docs/architecture.md, Navigation).
import '../../core/navigation/destination.dart';

/// Your medicines: the shelf of medicine prints.
final class MedicinesDestination extends Destination {
  const MedicinesDestination();
}

/// The steps that add a medicine.
final class AddMedicineDestination extends Destination {
  const AddMedicineDestination();
}

/// One medicine's page, with its reminders.
final class MedicineDestination extends Destination {
  const MedicineDestination(this.medicineId);
  final String medicineId;
}
