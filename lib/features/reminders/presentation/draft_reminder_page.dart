import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/time/clock.dart';
import '../../../design_system/design_system.dart';
import '../application/reminder_draft.dart';
import '../domain/calendar.dart';
import 'reminder_editor.dart';

/// Adds or edits a reminder for a medicine that is not saved yet. Returns the
/// [ReminderDetails] to the Add medicine form instead of saving them.
class DraftReminderPage extends ConsumerWidget {
  const DraftReminderPage({this.initial, super.key});

  /// The draft being edited, or `null` for a new reminder.
  final ReminderDraft? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = initial != null;
    return PageLayout(
      heading: editing ? 'Edit reminder' : 'Add reminder',
      supportingText: 'For the new medicine',
      children: [
        ReminderEditor(
          initial:
              initial ??
              ReminderDraft.initial(
                LocalDate.fromDateTime(ref.read(clockProvider)()),
              ),
          submitLabel: editing ? 'Save changes' : 'Add reminder',
          onSubmit: (details) async => context.pop(details),
        ),
      ],
    );
  }
}
