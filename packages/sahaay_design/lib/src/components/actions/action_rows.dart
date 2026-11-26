import 'package:flutter/material.dart';

import '../../foundations/spacing.dart';
import '../../tokens/sahaay_tokens.dart';
import '../items/pressable.dart';
import '../scaled_icon.dart';

/// A group of action rows on one soft card (`docs/design-system.md` §11.4,
/// §11.7). Rows are separated by a thin gap of page colour, not lines, and
/// each group is followed by `row.groupGap`. Put a [DangerRow] in a group of
/// its own, at the bottom.
class ActionGroup extends StatelessWidget {
  const ActionGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    return Padding(
      padding: EdgeInsets.only(bottom: t.row.groupGap),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: t.card.shape),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: Spacing.betweenRows),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A full-width row for an everyday action, such as "Edit reminder ›".
class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showChevron = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Shows "›" when the row opens another screen.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final r = context.sahaay.row;
    return _RowSurface(
      onTap: onTap,
      semantics: (child) => Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        child: child,
      ),
      leading: ScaledIcon(icon, besideText: r.label, color: r.icon),
      body: Text(label, style: r.label),
      trailing: showChevron
          ? ScaledIcon(
              Icons.chevron_right,
              besideText: r.label,
              color: r.chevron,
            )
          : null,
    );
  }
}

/// A row with a switch, such as "Notify me". The whole row toggles it.
/// While it is off, [offNote] explains what that means, in words — for
/// example "Paused — won't notify until you turn it back on".
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.offNote,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final String? offNote;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final r = t.row;
    final icon = this.icon;
    final note = value ? null : offNote;
    final onChanged = this.onChanged;
    return _RowSurface(
      onTap: onChanged == null ? null : () => onChanged(!value),
      semantics: (child) => Semantics(
        toggled: value,
        enabled: onChanged != null,
        label: label,
        hint: note,
        excludeSemantics: true,
        child: child,
      ),
      leading: icon == null
          ? null
          : ScaledIcon(icon, besideText: r.label, color: r.icon),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: r.label),
          AnimatedSize(
            duration: t.motion.appear.duration,
            curve: t.motion.appear.curve,
            alignment: Alignment.topLeft,
            child: note == null
                ? const SizedBox(width: double.infinity)
                : Text(note, style: t.switchRow.stateNote),
          ),
        ],
      ),
      trailing: ExcludeFocus(
        child: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

/// A destructive action, such as "Delete reminder", in brick. Place it
/// alone in its own [ActionGroup] at the bottom of the screen, and confirm
/// before acting.
class DangerRow extends StatelessWidget {
  const DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = context.sahaay.dangerRow;
    return _RowSurface(
      onTap: onTap,
      semantics: (child) => Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        child: child,
      ),
      leading: ScaledIcon(icon, besideText: d.label, color: d.icon),
      body: Text(label, style: d.label),
    );
  }
}

/// The shared row surface: at least `row.minHeight` tall, card colour that
/// deepens while pressed, an optional leading icon, a body, and an optional
/// trailing widget.
class _RowSurface extends StatelessWidget {
  const _RowSurface({
    required this.onTap,
    required this.semantics,
    required this.body,
    this.leading,
    this.trailing,
  });

  final VoidCallback? onTap;
  final Widget Function(Widget child) semantics;
  final Widget body;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final r = t.row;
    final leading = this.leading;
    final trailing = this.trailing;
    return semantics(
      Pressable(
        onTap: onTap,
        shape: const RoundedRectangleBorder(),
        builder: (context, pressed) => AnimatedContainer(
          duration: t.motion.press.duration,
          curve: t.motion.press.curve,
          color: pressed ? r.pressedBackground : r.background,
          constraints: BoxConstraints(minHeight: r.minHeight),
          padding: EdgeInsets.symmetric(
            horizontal: t.card.padding.left,
            vertical: Spacing.besideIcon,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: Spacing.besideIcon),
              ],
              Expanded(child: body),
              if (trailing != null) ...[
                const SizedBox(width: Spacing.besideIcon),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
