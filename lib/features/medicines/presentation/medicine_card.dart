import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../domain/medicine.dart';
import 'medicine_labels.dart';
import 'medicine_photo.dart';

/// One medicine in the medicines list (`docs/design-system.md` §11.2).
class MedicineCard extends StatelessWidget {
  const MedicineCard({required this.medicine, required this.onTap, super.key});

  final Medicine medicine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Card.filled(
      margin: EdgeInsets.only(bottom: spacing.itemSeparation),
      color: context.colors.surfaceContainer,
      shape: context.shapes.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(spacing.itemInset),
          child: Row(
            children: [
              MedicinePhoto.thumbnail(
                photoKey: medicine.photoPath,
                semanticLabel: 'Photo of ${medicine.displayName}',
              ),
              SizedBox(width: spacing.itemInset),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.displayName,
                      style: context.typography.itemHeading,
                    ),
                    Text(
                      medicine.form.label,
                      style: context.typography.metadata,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.contentQuiet),
            ],
          ),
        ),
      ),
    );
  }
}
