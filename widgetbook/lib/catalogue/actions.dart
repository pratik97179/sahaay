import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stage.dart';

final List<WidgetbookNode> actions = [
  WidgetbookComponent(
    name: 'PrimaryButton',
    useCases: [
      staged(
        'Default',
        (context) => PrimaryButton(
          label: context.text('label', 'Save reminder'),
          icon: context.knobs.boolean(label: 'Icon') ? Icons.check : null,
          onPressed: () {},
        ),
      ),
      staged(
        'Disabled',
        (context) =>
            const PrimaryButton(label: 'Save reminder', onPressed: null),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'ActionRow',
    useCases: [
      staged(
        'In a group',
        (context) => ActionGroup(
          children: [
            ActionRow(
              icon: Icons.edit_outlined,
              label: context.text('label', 'Edit medicine'),
              onTap: () {},
            ),
            ActionRow(
              icon: Icons.photo_camera_outlined,
              label: 'Retake photo',
              onTap: () {},
            ),
            ActionRow(
              icon: Icons.info_outline,
              label: 'About',
              showChevron: false,
              onTap: () {},
            ),
          ],
        ),
      ),
      staged(
        'Disabled',
        (context) => const ActionGroup(
          children: [
            ActionRow(
              icon: Icons.edit_outlined,
              label: 'Edit medicine',
              onTap: null,
            ),
          ],
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'SwitchRow',
    useCases: [
      staged(
        'On and off',
        (context) => ActionGroup(
          children: [
            _Switch(label: context.text('label', 'Reminder on'), initial: true),
            const _Switch(label: 'Reminder on', initial: false),
          ],
        ),
      ),
      staged(
        'Disabled',
        (context) => const ActionGroup(
          children: [
            SwitchRow(label: 'Reminder on', value: true, onChanged: null),
          ],
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'DangerRow',
    useCases: [
      staged(
        'Default',
        (context) => ActionGroup(
          children: [
            DangerRow(
              icon: Icons.delete_outline,
              label: context.text('label', 'Delete medicine'),
              onTap: () {},
            ),
          ],
        ),
      ),
    ],
  ),
];

/// A switch row that can be toggled, with the paused note shown when off.
class _Switch extends StatefulWidget {
  const _Switch({required this.label, required this.initial});

  final String label;
  final bool initial;

  @override
  State<_Switch> createState() => _SwitchState();
}

class _SwitchState extends State<_Switch> {
  late bool _on = widget.initial;

  @override
  Widget build(BuildContext context) => SwitchRow(
    label: widget.label,
    value: _on,
    icon: Icons.notifications_outlined,
    offNote: 'Paused. No reminders until you turn it back on.',
    onChanged: (on) => setState(() => _on = on),
  );
}
