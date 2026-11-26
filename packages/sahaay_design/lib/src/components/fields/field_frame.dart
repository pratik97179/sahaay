import 'package:flutter/material.dart';

import '../../foundations/radii.dart';
import '../../foundations/spacing.dart';
import '../../tokens/sahaay_tokens.dart';
import '../scaled_icon.dart';

/// The parts every field shares (`docs/design-system.md` §3.4, §11.3): its
/// label, the control, validation feedback below it, and the gap to the
/// next field.
///
/// Errors are shown with an icon and words, never by colour alone, and are
/// announced to screen readers when they appear.
class FieldFrame extends StatelessWidget {
  const FieldFrame({
    required this.label,
    required this.control,
    this.errorText,
    super.key,
  });

  final String label;
  final Widget control;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final f = t.field;
    final error = errorText;
    return Padding(
      padding: EdgeInsets.only(bottom: f.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: f.label),
          SizedBox(height: f.labelGap),
          control,
          AnimatedSize(
            duration: t.motion.appear.duration,
            curve: t.motion.appear.curve,
            alignment: Alignment.topCenter,
            child: error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: EdgeInsets.only(top: f.labelGap),
                    child: Semantics(
                      liveRegion: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScaledIcon(
                            Icons.error_outline,
                            besideText: f.errorText,
                            color: f.errorOutline,
                          ),
                          const SizedBox(width: Spacing.underLabel),
                          Expanded(child: Text(error, style: f.errorText)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The field outline: none at rest, the brick outline when there is an
/// error. Focus shows the theme's focus ring.
InputDecoration fieldDecoration(
  BuildContext context, {
  required bool hasError,
  String? placeholder,
  Widget? prefixIcon,
}) {
  final f = context.sahaay.field;
  final errorOutline = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(Radii.field)),
    borderSide: BorderSide(color: f.errorOutline, width: 2),
  );
  return InputDecoration(
    hintText: placeholder,
    prefixIcon: prefixIcon,
    enabledBorder: hasError ? errorOutline : null,
    focusedBorder: hasError ? errorOutline : null,
  );
}
