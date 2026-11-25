import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../medicines_providers.dart';

/// A stored medicine photo, clipped to the media shape.
class MedicinePhoto extends ConsumerWidget {
  /// A small square for lists.
  const MedicinePhoto.thumbnail({
    required this.photoKey,
    required this.semanticLabel,
    super.key,
  }) : _thumbnail = true;

  /// A full-width photo for recognising the medicine.
  const MedicinePhoto.large({
    required this.photoKey,
    required this.semanticLabel,
    super.key,
  }) : _thumbnail = false;

  final String photoKey;
  final String semanticLabel;
  final bool _thumbnail;

  static const double _thumbnailSize = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(medicinePhotoStorageProvider).resolve(photoKey);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final image = Image.file(
      file,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      // Decode thumbnails at display size instead of the full photo.
      cacheWidth: _thumbnail ? (_thumbnailSize * pixelRatio).round() : null,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: context.colors.surfaceContainer,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: context.colors.contentQuiet,
            semanticLabel: 'Photo unavailable',
          ),
        ),
      ),
    );
    return ClipPath(
      clipper: ShapeBorderClipper(shape: context.shapes.media),
      child: _thumbnail
          ? SizedBox.square(dimension: _thumbnailSize, child: image)
          : AspectRatio(aspectRatio: 4 / 3, child: image),
    );
  }
}
