import 'package:flutter/material.dart';

import '../../tokens/sahaay_tokens.dart';
import 'field_frame.dart';

/// A labelled text input (`docs/design-system.md` §11.3), such as a
/// medicine's name or a reminder's instruction.
///
/// Named `TextInputField` so it never clashes with Material's `TextField`.
class TextInputField extends StatelessWidget {
  const TextInputField({
    required this.label,
    this.controller,
    this.placeholder,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.maxLines = 1,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TextEditingController? controller;

  /// Shown while the field is empty, such as "Optional".
  final String? placeholder;

  /// Validation feedback, or `null` when the value is fine.
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  /// Lines before the field scrolls; `null` grows with the text.
  final int? maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final f = context.sahaay.field;
    return FieldFrame(
      label: label,
      errorText: errorText,
      control: TextField(
        controller: controller,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        style: f.value,
        decoration: fieldDecoration(
          context,
          hasError: errorText != null,
          placeholder: placeholder,
        ),
      ),
    );
  }
}
