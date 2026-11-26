import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stage.dart';

final List<WidgetbookNode> feedback = [
  WidgetbookComponent(
    name: 'Tag',
    useCases: [
      staged(
        'Paused',
        (context) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: Tag(label: context.text('label', 'Paused'), icon: Icons.pause),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'ConfirmDialog',
    useCases: [
      staged(
        'Shown',
        (context) => ConfirmDialog(
          title: context.text('title', 'Delete this medicine?'),
          message: context.text(
            'message',
            'Its photo and all its reminders will be deleted.',
          ),
          confirmLabel: 'Delete medicine',
          cancelLabel: 'Cancel',
        ),
      ),
      staged(
        'Opened from a row',
        (context) => ActionGroup(
          children: [
            DangerRow(
              icon: Icons.delete_outline,
              label: 'Delete medicine',
              onTap: () => showConfirmDialog(
                context,
                title: 'Delete this medicine?',
                message: 'Its photo and all its reminders will be deleted.',
                confirmLabel: 'Delete medicine',
                cancelLabel: 'Cancel',
              ),
            ),
          ],
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Snackbar',
    useCases: [
      staged('Default', (context) {
        final message = context.text('message', 'Reminder saved');
        return PrimaryButton(
          label: 'Show snackbar',
          onPressed: () => showSahaaySnackbar(context, message),
        );
      }),
    ],
  ),
  WidgetbookComponent(
    name: 'EmptyState',
    useCases: [
      staged(
        'Default',
        (context) => EmptyState(
          message: context.text('message', 'No medicines yet.'),
          icon: Icons.medication_outlined,
          action: context.knobs.boolean(label: 'Action', initialValue: true)
              ? PrimaryButton(
                  label: 'Add medicine',
                  icon: Icons.add,
                  onPressed: () {},
                )
              : null,
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'ErrorState',
    useCases: [
      staged(
        'Default',
        (context) => ErrorState(
          message: context.text(
            'message',
            "Your medicines couldn't be loaded.",
          ),
          action: context.knobs.boolean(label: 'Action', initialValue: true)
              ? TextButton(onPressed: () {}, child: const Text('Try again'))
              : null,
        ),
      ),
    ],
  ),
];
