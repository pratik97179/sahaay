import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../design_system/design_system.dart';
import '../medicines_providers.dart';
import 'medicine_card.dart';

/// Home destination: the user's medicines.
class MedicinesPage extends ConsumerWidget {
  const MedicinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicines = ref.watch(medicinesProvider);
    return PageLayout(
      heading: 'Medicines',
      primaryAction: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addMedicine),
        icon: const Icon(Icons.add),
        label: const Text('Add medicine'),
      ),
      children: [
        switch (medicines) {
          AsyncData(value: final list) when list.isEmpty => const EmptyState(
            icon: Icons.medication_outlined,
            message: 'No medicines yet.',
          ),
          AsyncData(value: final list) => Column(
            children: [
              for (final medicine in list)
                MedicineCard(
                  medicine: medicine,
                  onTap: () => context.push(AppRoutes.medicine(medicine.id)),
                ),
            ],
          ),
          AsyncError() => const ErrorState(
            message: "Your medicines couldn't be loaded.",
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}
