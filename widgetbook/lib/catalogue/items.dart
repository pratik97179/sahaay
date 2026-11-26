import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stage.dart';

final List<WidgetbookNode> items = [
  WidgetbookComponent(
    name: 'ItemCard',
    useCases: [
      staged(
        'Default',
        (context) => ItemCard(
          onTap: context.knobs.boolean(label: 'Tappable', initialValue: true)
              ? () {}
              : null,
          child: Text(
            context.text('content', 'Any content sits on a card'),
            style: context.sahaay.field.value,
          ),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'PhotoTile',
    useCases: [
      staged(
        'With photo',
        (context) => _OneTile(
          PhotoTile(
            photo: samplePhoto,
            name: context.text('name', 'Test 2'),
            detail: context.knobs.stringOrNull(
              label: 'Detail',
              initialValue: '2 reminders',
            ),
            onTap: () {},
          ),
        ),
      ),
      staged(
        'Photo missing',
        (context) => _OneTile(
          PhotoTile(photo: brokenPhoto, name: 'Test 2', onTap: () {}),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'PhotoTileGrid',
    useCases: [
      staged('Many', (context) {
        final count = context.knobs.int.slider(
          label: 'Tiles',
          initialValue: 5,
          min: 1,
          max: 12,
        );
        return PhotoTileGrid(
          children: [
            for (var i = 1; i <= count; i++)
              PhotoTile(
                photo: samplePhoto,
                name: i == 3 ? longText : 'Medicine $i',
                detail: '$i reminders',
                onTap: () {},
              ),
          ],
        );
      }),
      staged(
        'Empty',
        (context) => const EmptyState(
          message: 'No medicines yet.',
          icon: Icons.medication_outlined,
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'TimeCard',
    useCases: [
      staged(
        'Default',
        (context) => TimeCard(
          time: context.knobs.string(label: 'Time', initialValue: '9:00 AM'),
          schedule: context.text('schedule', 'Every Monday and Thursday'),
          note: context.knobs.stringOrNull(
            label: 'Note',
            initialValue: '1 tablet · after food',
          ),
          onTap: () {},
        ),
      ),
      staged(
        'Paused',
        (context) => TimeCard(
          time: '9:00 PM',
          schedule: 'Every day',
          tag: const Tag(label: 'Paused', icon: Icons.pause),
          onTap: () {},
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'TakePanel',
    useCases: [
      staged(
        'Default',
        (context) => TakePanel(
          photo: samplePhoto,
          name: context.text('name', 'Test 2'),
          instruction: context.knobs.stringOrNull(
            label: 'Instruction',
            initialValue: '2 tablets · after food',
          ),
        ),
      ),
      staged(
        'Photo missing',
        (context) => TakePanel(photo: brokenPhoto, name: 'Test 2'),
      ),
    ],
  ),
];

/// One tile at the width a two-column grid would give it.
class _OneTile extends StatelessWidget {
  const _OneTile(this.tile);

  final Widget tile;

  @override
  Widget build(BuildContext context) => PhotoTileGrid(children: [tile]);
}
