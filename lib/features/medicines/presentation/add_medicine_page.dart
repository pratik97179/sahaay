import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../design_system/design_system.dart';
import '../domain/medicine.dart';
import '../medicines_providers.dart';
import 'add_medicine_extras.dart';
import 'medicine_labels.dart';

/// Add-medicine flow (PRD §5.1, FR-01): optional name, camera photo, form,
/// and whatever [createExtras] adds, such as reminders.
class AddMedicinePage extends ConsumerStatefulWidget {
  const AddMedicinePage({this.createExtras, super.key});

  final CreateAddMedicineExtras? createExtras;

  @override
  ConsumerState<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends ConsumerState<AddMedicinePage> {
  final _name = TextEditingController();
  String? _photoPath;
  MedicineForm? _form;
  bool _showErrors = false;
  bool _busy = false;
  late final AddMedicineExtras? _extras = widget.createExtras?.call(ref);

  @override
  void dispose() {
    _name.dispose();
    _extras?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() => _busy = true);
    try {
      final path = await ref.read(photoCaptureProvider).capture();
      if (path != null && mounted) setState(() => _photoPath = path);
    } on Exception {
      _showMessage("The camera couldn't be opened.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final photoPath = _photoPath;
    final form = _form;
    if (photoPath == null || form == null) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await ref.read(addMedicineProvider)(
        name: _name.text,
        form: form,
        capturedPhotoPath: photoPath,
        alsoSave: _extras?.saveFor,
      );
      if (mounted) context.pushReplacement(AppRoutes.medicine(id));
    } on Exception {
      _showMessage("The medicine couldn't be saved. Please try again.");
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = _photoPath;
    final spacing = context.spacing;
    return PageLayout(
      heading: 'Add medicine',
      children: [
        ContentSection(
          heading: 'Medicine details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: 'Name',
                child: TextField(
                  controller: _name,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(hintText: 'Optional'),
                ),
              ),
              LabeledField(
                label: 'Photo',
                errorText: _showErrors && photoPath == null
                    ? 'Take a photo of the medicine.'
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photoPath != null) ...[
                      ClipPath(
                        clipper: ShapeBorderClipper(
                          shape: context.shapes.media,
                        ),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.file(
                            File(photoPath),
                            fit: BoxFit.cover,
                            semanticLabel: 'Captured medicine photo',
                            errorBuilder: (context, error, stackTrace) =>
                                ColoredBox(
                                  color: context.colors.surfaceContainer,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: context.colors.contentQuiet,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.fieldLabelControl),
                    ],
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _takePhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(
                        photoPath == null ? 'Take photo' : 'Retake photo',
                      ),
                    ),
                  ],
                ),
              ),
              LabeledField(
                label: 'Form',
                errorText: _showErrors && _form == null
                    ? 'Choose the medicine form.'
                    : null,
                child: SegmentedButton<MedicineForm>(
                  segments: [
                    for (final form in MedicineForm.values)
                      ButtonSegment(value: form, label: Text(form.label)),
                  ],
                  selected: {?_form},
                  emptySelectionAllowed: true,
                  onSelectionChanged: _busy
                      ? null
                      : (selection) =>
                            setState(() => _form = selection.firstOrNull),
                ),
              ),
            ],
          ),
        ),
        ?_extras?.buildSection(context, enabled: !_busy),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Save medicine'),
        ),
      ],
    );
  }
}
