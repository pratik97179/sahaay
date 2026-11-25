import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Home destination: the user's medicines.
class MedicinesPage extends StatelessWidget {
  const MedicinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageLayout(
      heading: 'Medicines',
      children: [
        EmptyState(
          icon: Icons.medication_outlined,
          message: 'No medicines yet.',
        ),
      ],
    );
  }
}
