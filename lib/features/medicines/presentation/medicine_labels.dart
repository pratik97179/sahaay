import '../domain/medicine.dart';

/// User-facing wording for medicine data.
extension MedicineFormLabel on MedicineForm {
  String get label => switch (this) {
    MedicineForm.oral => 'Oral / edible',
    MedicineForm.injectable => 'Injectable',
  };
}

extension MedicineDisplayName on Medicine {
  /// The medicine's name, or a generic label when none was given (PRD §3.1).
  String get displayName => name ?? 'Unnamed medicine';
}
