import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../app/routes.dart';
import '../domain/medicine.dart';
import '../medicines_providers.dart';
import 'medicine_labels.dart';

/// One medicine: its photo, its form and its reminders
/// (docs/design-system.md §18.3).
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
    try {
      await ref.read(deleteMedicineProvider)(m.id);
      if (context.mounted) context.go(AppRoutes.medicines);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("the medicine couldn't be deleted.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = DayLight.screen;
    final medicine = ref.watch(medicineProvider(medicineId));
    return Scaffold(
      backgroundColor: light.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
          child: switch (medicine) {
            AsyncData(value: final Medicine m) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Delete sits level with the first header line, where the
                // other screens keep their buttons.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Header(medicine: m, light: light),
                    ),
                    HoldToDelete(
                      light: light,
                      label: 'Delete ${m.displayName}',
                      hint: 'Deletes the medicine, its photo, its reminders and their prints',
                      onDelete: () => _delete(context, ref, m),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Semantics(
                    image: true,
                    label: 'Photo of ${m.displayName}',
                    child: MedPhoto(
                      radius: 28,
                      image: FileImage(
                        ref
                            .watch(medicinePhotoStorageProvider)
                            .resolve(m.photoPath),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                reminders,
              ],
            ),
            AsyncData() => _Message(
              'this medicine no longer exists.',
              light: light,
            ),
            AsyncError() => _Message(
              "this medicine couldn't be loaded.",
              light: light,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.medicine, required this.light});
  final Medicine medicine;
  final DayLight light;

  @override
  Widget build(BuildContext context) {
    final injectable = medicine.form == MedicineForm.injectable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Text(
            '‹  your medicines',
            style: figtree(17, FontWeight.w700, light.soft),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          medicine.displayName,
          style: figtree(44, FontWeight.w800, light.ink, letterSpacing: -1),
        ),
        Semantics(
          container: true,
          label: injectable ? 'Injectable' : 'Oral',
          excludeSemantics: true,
          child: Row(
            children: [
              SizedBox.square(
                dimension: MediaQuery.textScalerOf(context).scale(18),
                child: CustomPaint(
                  painter: FormMark(injectable: injectable, color: light.soft),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  injectable ? 'injectable' : 'oral',
                  style: figtree(17, FontWeight.w500, light.soft),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.light});
  final String text;
  final DayLight light;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Text(
          '‹  your medicines',
          style: figtree(17, FontWeight.w700, light.soft),
        ),
      ),
      const SizedBox(height: 24),
      Text(text, style: figtree(20, FontWeight.w700, light.ink)),
    ],
  );
}
