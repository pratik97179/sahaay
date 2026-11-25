import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../design_system/design_system.dart';
import '../domain/medicine.dart';
import '../medicines_providers.dart';
import 'medicine_labels.dart';
import 'medicine_photo.dart';

/// One medicine: its photo, details and reminders (PRD §5.3, §5.4).
///
/// The reminders feature supplies [reminders], so this feature does not
/// depend on it; reminders depend on medicines, not the other way round.
class MedicineDetailsPage extends ConsumerWidget {
  const MedicineDetailsPage({
    required this.medicineId,
    required this.reminders,
    super.key,
  });

  final String medicineId;
  final Widget reminders;

  Future<void> _delete(BuildContext context, WidgetRef ref, Medicine m) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: m.name == null ? 'Delete this medicine?' : 'Delete ${m.name}?',
      message:
          'This deletes the medicine, its photo and all of its reminders. '
          "This can't be undone.",
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(deleteMedicineProvider)(m.id);
      if (context.mounted) context.go(AppRoutes.medicines);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The medicine couldn't be deleted.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(medicineProvider(medicineId))) {
      AsyncData(value: final Medicine medicine) => PageLayout(
        heading: medicine.displayName,
        children: [
          ContentSection(
            heading: 'Medicine information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MedicinePhoto.large(
                  photoKey: medicine.photoPath,
                  semanticLabel: 'Photo of ${medicine.displayName}',
                ),
                SizedBox(height: context.spacing.fieldSeparation),
                Text('Form', style: context.typography.fieldLabel),
                SizedBox(height: context.spacing.fieldLabelControl),
                Text(medicine.form.label, style: context.typography.fieldValue),
              ],
            ),
          ),
          reminders,
          DestructiveButton(
            label: 'Delete medicine',
            icon: Icons.delete_outline,
            onPressed: () => _delete(context, ref, medicine),
          ),
        ],
      ),
      AsyncData() => const PageLayout(
        heading: 'Medicine',
        children: [EmptyState(message: 'This medicine no longer exists.')],
      ),
      AsyncError() => const PageLayout(
        heading: 'Medicine',
        children: [ErrorState(message: "This medicine couldn't be loaded.")],
      ),
      _ => const PageLayout(
        heading: 'Medicine',
        children: [Center(child: CircularProgressIndicator())],
      ),
    };
  }
}
