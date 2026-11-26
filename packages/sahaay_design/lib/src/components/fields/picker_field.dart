import 'package:flutter/material.dart';

import '../../tokens/sahaay_tokens.dart';
import 'field_frame.dart';

/// A labelled field whose value is chosen in a picker sheet
/// (`docs/design-system.md` §11.3, §11.7), such as a time, a date or how
/// often a reminder repeats.
///
/// It looks like a text input so every field in a form reads alike. Tapping
/// it calls [onTap], which opens the matching sheet.
class PickerField extends StatelessWidget {
  const PickerField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.errorText,
    super.key,
  });

  final String label;

  /// The chosen value, already formatted, or `null` when nothing is chosen.
  final String? value;

  /// Shown while nothing is chosen, such as "Choose a time".
  final String placeholder;
  final IconData icon;

  /// Opens the picker; `null` disables the field.
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final f = context.sahaay.field;
    final value = this.value;
    final enabled = onTap != null;
    return FieldFrame(
      label: label,
      errorText: errorText,
      control: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        value: value ?? placeholder,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          customBorder: f.shape,
          child: InputDecorator(
            isEmpty: value == null,
            decoration: fieldDecoration(
              context,
              hasError: errorText != null,
              placeholder: placeholder,
              prefixIcon: Icon(icon),
            ).copyWith(enabled: enabled),
            child: value == null ? null : Text(value, style: f.value),
          ),
        ),
      ),
    );
  }
}
