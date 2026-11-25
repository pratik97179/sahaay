import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A section another feature adds to the Add medicine form, whose records are
/// saved together with the new medicine in one transaction (PRD §5.1).
///
/// This is how reminders are created while adding a medicine without the
/// medicines feature depending on the reminders feature.
abstract interface class AddMedicineExtras {
  /// The form section; [enabled] is false while the medicine is being saved.
  Widget buildSection(BuildContext context, {required bool enabled});

  /// Saves this section's records for the new medicine. Called inside the
  /// medicine's transaction, so a failure here also undoes the medicine.
  Future<void> saveFor(String medicineId);

  void dispose();
}

/// Creates the extras for one visit to the Add medicine form.
typedef CreateAddMedicineExtras = AddMedicineExtras Function(WidgetRef ref);
