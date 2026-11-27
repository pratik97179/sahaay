import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../core/time/clock.dart';
import '../../medicines/medicines_providers.dart';
import '../../medicines/presentation/medicine_labels.dart';
import '../application/reminder_draft.dart';
import '../domain/calendar.dart';
import '../reminders_providers.dart';
import 'when_step.dart';

/// Adds reminders to an existing medicine (PRD §5.3, FR-02;
/// docs/design-system.md §18.3), with the same controls as Add medicine's
/// "when?" step. Each time of day becomes its own reminder. The drawn tick
/// at the top right saves them; it shows once a time is set.
class NewReminderPage extends ConsumerStatefulWidget {
  const NewReminderPage({required this.medicineId, super.key});

  final String medicineId;

  @override
  ConsumerState<NewReminderPage> createState() => _NewReminderPageState();
}

class _NewReminderPageState extends ConsumerState<NewReminderPage> {
  late final _draft = ValueNotifier(
    WhenDraft(
      draft: ReminderDraft.initial(
        LocalDate.fromDateTime(ref.read(clockProvider)()),
      ),
    ),
  );
  bool _busy = false;

  Future<void> _save() async {
    final now = LocalDateTime.fromDateTime(ref.read(clockProvider)());
    final details = _draft.value.toDetails(now);
    if (details.isEmpty) return;
    setState(() => _busy = true);
    try {
      final create = ref.read(createReminderProvider);
      for (final d in details) {
        await create(medicineId: widget.medicineId, details: d);
      }
      if (mounted) context.pop();
    } on Exception {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("the reminder couldn't be saved.")),
        );
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = DayLight.screen;
    final medicine = ref.watch(medicineProvider(widget.medicineId)).value;
    return Scaffold(
      backgroundColor: light.page,
      body: SafeArea(
        child: SingleChildScrollView(
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
                            '‹  ${medicine?.displayName ?? 'back'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: figtree(17, FontWeight.w700, light.soft),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'new reminder',
                          style: figtree(
                            44,
                            FontWeight.w800,
                            light.ink,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Shown once a time is set; its space is always kept, so
                  // nothing moves when it appears.
                  ValueListenableBuilder(
                    valueListenable: _draft,
                    builder: (context, w, _) {
                      final ready = w.times.isNotEmpty && !_busy;
                      return IgnorePointer(
                        ignoring: !ready,
                        child: AnimatedOpacity(
                          opacity: ready ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: _SaveButton(light: light, onTap: _save),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              WhenStep(current: _draft, enabled: !_busy),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round ink stamp with a paper tick and "save" under it.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.light, required this.onTap});
  final DayLight light;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Save the reminder',
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
              child: CustomPaint(painter: _Tick(light.ink)),
            ),
            const SizedBox(height: 4),
            Text('save', style: figtree(13, FontWeight.w700, light.ink)),
          ],
        ),
      ),
    ),
  );
}

class _Tick extends CustomPainter {
  _Tick(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.42;
    canvas.drawCircle(c, r, Paint()..color = ink);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.45, c.dy + r * 0.02)
        ..lineTo(c.dx - r * 0.12, c.dy + r * 0.36)
        ..lineTo(c.dx + r * 0.5, c.dy - r * 0.32),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Paper.sheet,
    );
  }

  @override
  bool shouldRepaint(_Tick old) => old.ink != ink;
}
