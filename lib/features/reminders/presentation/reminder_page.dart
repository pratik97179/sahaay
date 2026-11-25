import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../design_system/design_system.dart';
import '../../medicines/domain/medicine.dart';
import '../../medicines/medicines_providers.dart';
import '../../medicines/presentation/medicine_labels.dart';
import '../../medicines/presentation/medicine_photo.dart';
import '../domain/recurrence.dart';
import '../domain/reminder.dart';
import '../reminders_providers.dart';
import 'schedule_text.dart';

/// One reminder's entry screen: the medicine's photo and form, and the
/// reminder's details, with edit, pause or resume, and delete (PRD §5.2,
/// §5.3, FR-05 to FR-08). Notifications will open this screen.
class ReminderPage extends ConsumerWidget {
  const ReminderPage({required this.reminderId, super.key});

  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(reminderProvider(reminderId))) {
      AsyncData(value: final Reminder reminder) => switch (ref.watch(
        medicineProvider(reminder.medicineId),
      )) {
        AsyncData(value: final Medicine medicine) => _ReminderView(
          reminder: reminder,
          medicine: medicine,
        ),
        AsyncError() => const _Message.error(),
        AsyncData() => const _Message.missing(),
        _ => const _Message.loading(),
      },
      AsyncData() => const _Message.missing(),
      AsyncError() => const _Message.error(),
      _ => const _Message.loading(),
    };
  }
}

class _ReminderView extends ConsumerStatefulWidget {
  const _ReminderView({required this.reminder, required this.medicine});

  final Reminder reminder;
  final Medicine medicine;

  @override
  ConsumerState<_ReminderView> createState() => _ReminderViewState();
}

class _ReminderViewState extends ConsumerState<_ReminderView> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String failure) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePause() {
    final paused = !widget.reminder.isPaused;
    return _run(
      () => ref
          .read(manageReminderProvider)
          .setPaused(widget.reminder.id, paused: paused),
      paused
          ? "The reminder couldn't be paused."
          : "The reminder couldn't be resumed.",
    );
  }

  Future<void> _delete() async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete this reminder?',
      message:
          'Only this reminder is deleted. The medicine and its other '
          "reminders stay. This can't be undone.",
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    final router = GoRouter.of(context);
    final medicineId = widget.reminder.medicineId;
    await _run(() async {
      await ref.read(manageReminderProvider).delete(widget.reminder.id);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(AppRoutes.medicine(medicineId));
      }
    }, "The reminder couldn't be deleted.");
  }

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminder;
    final medicine = widget.medicine;
    final schedule = reminder.schedule;
    final once = schedule.recurrence is OneTimeRecurrence;
    final spacing = context.spacing;
    final typography = context.typography;
    final quantity = reminder.quantity;
    final instruction = reminder.instruction;
    final endDate = schedule.endDate;

    return PageLayout(
      heading: medicine.displayName,
      supportingText: 'Reminder',
      children: [
        ContentSection(
          heading: 'Medicine',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MedicinePhoto.large(
                photoKey: medicine.photoPath,
                semanticLabel: 'Photo of ${medicine.displayName}',
              ),
              SizedBox(height: spacing.fieldSeparation),
              ReadOnlyField(label: 'Form', value: medicine.form.label),
            ],
          ),
        ),
        ContentSection(
          heading: 'Reminder',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: spacing.fieldSeparation),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatTime(context, schedule.time),
                            style: typography.primaryValue,
                          ),
                        ),
                        if (reminder.isPaused)
                          Text('Paused', style: typography.statusLabel),
                      ],
                    ),
                    if (reminder.isPaused)
                      Text(
                        "It won't notify until you resume it.",
                        style: typography.supporting,
                      ),
                  ],
                ),
              ),
              if (once)
                ReadOnlyField(
                  label: 'Date',
                  value: formatDate(context, schedule.startDate),
                )
              else ...[
                ReadOnlyField(
                  label: 'Repeats',
                  value: describeSchedule(
                    schedule,
                    formatDate: (date) => formatDate(context, date),
                  ),
                  supporting: monthEndNote(schedule.recurrence),
                ),
                ReadOnlyField(
                  label: 'Starts',
                  value: formatDate(context, schedule.startDate),
                ),
                ReadOnlyField(
                  label: 'Ends',
                  value: endDate == null
                      ? 'No end date'
                      : formatDate(context, endDate),
                ),
              ],
              if (quantity != null)
                ReadOnlyField(label: 'Quantity', value: quantity),
              if (instruction != null)
                ReadOnlyField(label: 'Instruction', value: instruction),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => context.push(AppRoutes.editReminder(reminder.id)),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit reminder'),
        ),
        SizedBox(height: spacing.itemSeparation),
        OutlinedButton.icon(
          onPressed: _busy ? null : _togglePause,
          icon: Icon(
            reminder.isPaused
                ? Icons.play_arrow_outlined
                : Icons.pause_outlined,
          ),
          label: Text(reminder.isPaused ? 'Resume reminder' : 'Pause reminder'),
        ),
        SizedBox(height: spacing.sectionSeparation),
        DestructiveButton(
          label: 'Delete reminder',
          icon: Icons.delete_outline,
          onPressed: _busy ? null : _delete,
        ),
      ],
    );
  }
}

enum _Status { missing, error, loading }

/// The reminder screen when there is no reminder to show.
class _Message extends StatelessWidget {
  const _Message.missing() : _status = _Status.missing;
  const _Message.error() : _status = _Status.error;
  const _Message.loading() : _status = _Status.loading;

  final _Status _status;

  @override
  Widget build(BuildContext context) => PageLayout(
    heading: 'Reminder',
    children: [
      switch (_status) {
        _Status.missing => const EmptyState(
          message: 'This reminder no longer exists.',
        ),
        _Status.error => const ErrorState(
          message: "This reminder couldn't be loaded.",
        ),
        _Status.loading => const Center(child: CircularProgressIndicator()),
      },
    ],
  );
}
