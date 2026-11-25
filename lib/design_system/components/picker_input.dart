import 'package:flutter/material.dart';

import '../sahaay_theme.dart';

/// A field whose value is chosen in a picker, such as a date or a time
/// (`docs/design-system.md` §11.3 `DateInput`, `TimeInput`).
///
/// Looks like a text input so all fields read alike. Shows [placeholder]
/// until a value is chosen, and a clear button when [onClear] is given.
class PickerInput extends StatelessWidget {
  const PickerInput({
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.onClear,
    this.clearLabel = 'Clear',
    this.hasError = false,
    super.key,
  });

  final String? value;
  final String placeholder;
  final IconData icon;

  /// Opens the picker; `null` disables the field.
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String clearLabel;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final enabled = onTap != null;
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        customBorder: context.shapes.input,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            enabled: enabled,
            hintText: placeholder,
            prefixIcon: Icon(icon),
            suffixIcon: onClear != null && value != null && enabled
                ? IconButton(
                    onPressed: onClear,
                    tooltip: clearLabel,
                    icon: const Icon(Icons.close),
                  )
                : null,
            enabledBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colors.stateDanger.foreground,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: value == null
              ? null
              : Text(value, style: context.typography.fieldValue),
        ),
      ),
    );
  }
}
