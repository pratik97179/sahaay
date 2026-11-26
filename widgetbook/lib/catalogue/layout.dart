import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stage.dart';

final List<WidgetbookNode> layout = [
  WidgetbookComponent(
    name: 'Screen',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (context) => _SampleScreen(
          title: context.text('title', 'Medicines'),
          subtitle: context.knobs.stringOrNull(
            label: 'Subtitle',
            initialValue: 'Take with water',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'With floating action',
        builder: (context) => _SampleScreen(
          title: context.text('title', 'Medicines'),
          floatingAction: PrimaryButton(
            label: context.text('action', 'Add medicine'),
            icon: Icons.add,
            onPressed: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Long title',
        builder: (context) => const _SampleScreen(
          title: longText,
          subtitle: 'For a reminder with a long description',
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Section',
    useCases: [
      staged(
        'Default',
        (context) => Section(
          title: context.text('title', 'Reminders'),
          child: const TimeCard(time: '9:00 AM', schedule: 'Every day'),
        ),
      ),
      staged(
        'With trailing action',
        (context) => Section(
          title: context.text('title', 'Reminders'),
          trailing: TextButton(onPressed: () {}, child: const Text('Add')),
          child: const TimeCard(time: '9:00 AM', schedule: 'Every day'),
        ),
      ),
    ],
  ),
];

/// A screen with enough content to scroll, so the frosted top bar and its
/// fading title can be seen.
class _SampleScreen extends StatelessWidget {
  const _SampleScreen({
    required this.title,
    this.subtitle,
    this.floatingAction,
  });

  final String title;
  final String? subtitle;
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) => Screen(
    title: title,
    subtitle: subtitle,
    actions: [
      IconButton(
        onPressed: () {},
        tooltip: 'Settings',
        icon: const Icon(Icons.settings_outlined),
      ),
    ],
    floatingAction: floatingAction,
    children: [
      Section(
        title: 'Reminders',
        child: Column(
          children: [
            TimeCard(
              time: '9:00 AM',
              schedule: 'Every day',
              note: '1 tablet · after food',
              onTap: () {},
            ),
            SizedBox(height: context.sahaay.card.gap),
            TimeCard(
              time: '9:00 PM',
              schedule: 'Every Monday and Thursday',
              tag: const Tag(label: 'Paused', icon: Icons.pause),
              onTap: () {},
            ),
          ],
        ),
      ),
      Section(
        title: 'Settings',
        child: ActionGroup(
          children: [
            SwitchRow(label: 'Reminders on', value: true, onChanged: (_) {}),
            ActionRow(
              icon: Icons.edit_outlined,
              label: 'Edit medicine',
              onTap: () {},
            ),
          ],
        ),
      ),
      Section(
        title: 'Photo',
        child: TakePanel(photo: samplePhoto, name: title),
      ),
    ],
  );
}
