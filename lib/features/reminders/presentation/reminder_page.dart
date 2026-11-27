import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../app/routes.dart';
import '../../../core/time/clock.dart';
import '../../medicines/domain/medicine.dart';
import '../../medicines/medicines_providers.dart';
import '../../medicines/presentation/medicine_labels.dart';
import '../application/reminder_draft.dart';
import '../domain/calendar.dart';
import '../domain/reminder.dart';
import '../reminders_providers.dart';
import 'when_step.dart';

/// One reminder (docs/design-system.md
/// §18.3): the medicine it is for, then the reminder itself, set the same
/// way as on Add medicine's "when?" step. Every change is saved as it is
/// made. Pause or resume and delete sit at the top right. Notifications open
/// this screen.
class ReminderPage extends ConsumerWidget {
  const ReminderPage({required this.reminderId, super.key});

  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminder = ref.watch(reminderProvider(reminderId));
    final medicine = switch (reminder) {
      AsyncData(value: final Reminder r) => ref.watch(
        medicineProvider(r.medicineId),
      ),
      _ => null,
    };
    return Scaffold(
      backgroundColor: DayLight.screen.page,
      body: SafeArea(
        child: switch ((reminder, medicine)) {
          (
            AsyncData(value: final Reminder r),
            AsyncData(value: final Medicine m),
          ) =>
            _ReminderView(reminder: r, medicine: m),
          (AsyncError(), _) || (_, AsyncError()) => const _Message(
            "this reminder couldn't be loaded.",
          ),
          (AsyncData(value: null), _) || (_, AsyncData(value: null)) =>
            const _Message('this reminder no longer exists.'),
          _ => const SizedBox.shrink(),
        },
      ),
    );
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
  late final _draft = ValueNotifier(
    WhenDraft(draft: ReminderDraft.fromReminder(widget.reminder)),
  );

  @override
  void initState() {
    super.initState();
    // Touch the up-front reads while `ref` is usable.
    _manage;
    _clock;
    _draft.addListener(_changed);
  }

  Timer? _save;

  /// A saved reminder is locked until the edit mark unlocks it.
  bool _editing = false;

  // Read up front: the last change may be saved while the screen closes,
  // when `ref` can no longer be used.
  late final _manage = ref.read(manageReminderProvider);
  late final _clock = ref.read(clockProvider);

  LocalDateTime _now() => LocalDateTime.fromDateTime(_clock());

  /// Saves a moment after the last change, so dragging the ruler doesn't
  /// write on every frame. A change that isn't complete yet (a weekly
  /// reminder with no days chosen) waits until it is.
  void _changed() {
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 450), () async {
      final details = _draft.value.toDetails(_now());
      if (details.isEmpty) return;
      try {
        await _manage.update(widget.reminder.id, details.first);
      } on Exception {
        _say("the change couldn't be saved.");
      }
    });
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _togglePause() async {
    final paused = !widget.reminder.isPaused;
    try {
      await _manage.setPaused(widget.reminder.id, paused: paused);
    } on Exception {
      _say(
        paused
            ? "the reminder couldn't be paused."
            : "the reminder couldn't be resumed.",
      );
    }
  }

  Future<void> _delete() async {
    _save?.cancel();
    final router = GoRouter.of(context);
    final medicineId = widget.reminder.medicineId;
    try {
      await _manage.delete(widget.reminder.id);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(AppRoutes.medicine(medicineId));
      }
    } on Exception {
      _say("the reminder couldn't be deleted.");
    }
  }

  @override
  void dispose() {
    // A change still waiting is saved before leaving.
    if (_save?.isActive ?? false) {
      _save!.cancel();
      final details = _draft.value.toDetails(_now());
      if (details.isNotEmpty) {
        unawaited(_manage.update(widget.reminder.id, details.first));
      }
    }
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = DayLight.screen;
    final medicine = widget.medicine;
    final paused = widget.reminder.isPaused;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Text(
                        '‹  ${medicine.displayName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: figtree(17, FontWeight.w700, light.soft),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'reminder',
                      style: figtree(
                        44,
                        FontWeight.w800,
                        light.ink,
                        letterSpacing: -1,
                      ),
                    ),
                    // Both lines keep their space, so nothing moves when it
                    // is paused or resumed.
                    Stack(
                      children: [
                        Opacity(
                          opacity: paused ? 0 : 1,
                          child: Text(
                            _editing
                                ? 'changes save as you make them.'
                                : 'tap edit to change it.',
                            style: figtree(17, FontWeight.w500, light.soft),
                          ),
                        ),
                        Opacity(
                          opacity: paused ? 1 : 0,
                          child: Text(
                            "paused. it won't notify until resumed.",
                            style: figtree(17, FontWeight.w700, light.ink),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _PauseButton(paused: paused, light: light, onTap: _togglePause),
              HoldToDelete(
                light: light,
                label: 'Delete this reminder',
                hint:
                    'Only this reminder is deleted; the medicine and its other '
                    'reminders stay',
                onDelete: _delete,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: Semantics(
                  image: true,
                  label: 'Photo of ${medicine.displayName}',
                  child: MedPhoto(
                    radius: 18,
                    image: FileImage(
                      ref
                          .watch(medicinePhotoStorageProvider)
                          .resolve(medicine.photoPath),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  medicine.displayName,
                  style: figtree(20, FontWeight.w800, light.ink),
                ),
              ),
              // Unlocks the reminder below for changing.
              _EditButton(
                editing: _editing,
                light: light,
                onTap: () => setState(() => _editing = !_editing),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Opacity(
            opacity: paused ? 0.55 : 1,
            // Locked until edit is tapped: nothing below responds.
            child: IgnorePointer(
              ignoring: !_editing,
              child: WhenStep(
                current: _draft,
                enabled: _editing,
                form: widget.medicine.form,
                singleTime: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A drawn pencil with "edit" under it; while editing it turns to a tick
/// with "done", which locks the reminder again.
class _EditButton extends StatelessWidget {
  const _EditButton({
    required this.editing,
    required this.light,
    required this.onTap,
  });
  final bool editing;
  final DayLight light;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: editing ? 'Done editing' : 'Edit this reminder',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 0, 12),
        child: Column(
          children: [
            SizedBox.square(
              dimension: 40,
              child: CustomPaint(painter: _EditMark(light.ink, editing)),
            ),
            const SizedBox(height: 4),
            // Both words keep their space, so the header never shifts.
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: editing ? 0 : 1,
                  child: Text(
                    'edit',
                    style: figtree(13, FontWeight.w700, light.ink),
                  ),
                ),
                Opacity(
                  opacity: editing ? 1 : 0,
                  child: Text(
                    'done',
                    style: figtree(13, FontWeight.w700, light.ink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EditMark extends CustomPainter {
  _EditMark(this.ink, this.editing);
  final Color ink;
  final bool editing;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.42;
    canvas.drawCircle(c, r, Paint()..color = ink);
    final u = r / 10;
    final paper = Paint()..color = Paper.sheet;
    if (editing) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 4.5 * u, c.dy + 0.2 * u)
          ..lineTo(c.dx - 1.2 * u, c.dy + 3.6 * u)
          ..lineTo(c.dx + 5 * u, c.dy - 3.2 * u),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Paper.sheet,
      );
      return;
    }
    // A pencil, set at an angle.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.785);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-6 * u, -1.8 * u, 3 * u, 1.8 * u),
        Radius.circular(0.8 * u),
      ),
      paper,
    );
    canvas.drawPath(
      Path()
        ..moveTo(3 * u, -1.8 * u)
        ..lineTo(6.5 * u, 0)
        ..lineTo(3 * u, 1.8 * u)
        ..close(),
      paper,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EditMark old) => old.ink != ink || old.editing != editing;
}

/// A drawn pause (two bars) or resume (a triangle) mark with its word under
/// it, the same size as the other header buttons.
class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.paused,
    required this.light,
    required this.onTap,
  });
  final bool paused;
  final DayLight light;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: paused ? 'Resume this reminder' : 'Pause this reminder',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 0, 12),
        child: Column(
          children: [
            SizedBox.square(
              dimension: 40,
              child: CustomPaint(painter: _PauseMark(light.ink, paused)),
            ),
            const SizedBox(height: 4),
            // Both words keep their space, so the header never shifts.
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: paused ? 0 : 1,
                  child: Text(
                    'pause',
                    style: figtree(13, FontWeight.w700, light.ink),
                  ),
                ),
                Opacity(
                  opacity: paused ? 1 : 0,
                  child: Text(
                    'resume',
                    style: figtree(13, FontWeight.w700, light.ink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PauseMark extends CustomPainter {
  _PauseMark(this.ink, this.paused);
  final Color ink;
  final bool paused;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.42;
    canvas.drawCircle(c, r, Paint()..color = ink);
    final paper = Paint()..color = Paper.sheet;
    if (paused) {
      // Resume: a soft triangle.
      final u = r / 10;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 3 * u, c.dy - 5 * u)
          ..lineTo(c.dx + 5.5 * u, c.dy)
          ..lineTo(c.dx - 3 * u, c.dy + 5 * u)
          ..close(),
        paper,
      );
    } else {
      for (final x in [-2.6, 2.6]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c.translate(x * r / 10, 0),
              width: r * 0.22,
              height: r * 0.95,
            ),
            Radius.circular(r * 0.08),
          ),
          paper,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PauseMark old) => old.ink != ink || old.paused != paused;
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final light = DayLight.screen;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Text(
              '‹  back',
              style: figtree(17, FontWeight.w700, light.soft),
            ),
          ),
          const SizedBox(height: 24),
          Text(text, style: figtree(20, FontWeight.w700, light.ink)),
        ],
      ),
    );
  }
}
