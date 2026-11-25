/// The form of a medicine (PRD §3.1).
enum MedicineForm { oral, injectable }

/// A medicine the user creates reminders for (PRD §3.1).
///
/// Reminders reference a medicine by id; they are owned by the reminders
/// feature and are not embedded here.
final class Medicine {
  Medicine({
    required this.id,
    required this.form,
    required this.photoPath,
    String? name,
  }) : name = _blankToNull(name) {
    if (photoPath.trim().isEmpty) {
      throw ArgumentError.value(photoPath, 'photoPath', 'must not be empty');
    }
  }

  final String id;
  final String? name;
  final MedicineForm form;

  /// Location of the medicine photo in local app storage.
  final String photoPath;
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
