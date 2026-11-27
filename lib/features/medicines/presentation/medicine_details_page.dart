import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../app/routes.dart';
import '../domain/medicine.dart';
import '../medicines_providers.dart';
import 'medicine_labels.dart';

/// One medicine: its photo, its form and its reminders (PRD §5.3, §5.4;
/// docs/design-system.md §18.3).
///
/// The reminders feature supplies [reminders], so this feature does not
/// depend on it; reminders depend on medicines, not the other way round.
class MedicineDetailsPage extends ConsumerWidget {
  const MedicineDetailsPage({
    required this.medicineId,
    required this.reminders,
    super.key,
  });

  final String medicineId;
  final Widget reminders;

  Future<void> _delete(BuildContext context, WidgetRef ref, Medicine m) async {
    try {
      await ref.read(deleteMedicineProvider)(m.id);
      if (context.mounted) context.go(AppRoutes.medicines);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("the medicine couldn't be deleted.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = DayLight.screen;
    final medicine = ref.watch(medicineProvider(medicineId));
    return Scaffold(
      backgroundColor: light.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
          child: switch (medicine) {
            AsyncData(value: final Medicine m) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Delete sits level with the first header line, where the
                // other screens keep their buttons.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Header(medicine: m, light: light),
                    ),
                    _HoldToDelete(
                      light: light,
                      name: m.displayName,
                      onDelete: () => _delete(context, ref, m),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Semantics(
                    image: true,
                    label: 'Photo of ${m.displayName}',
                    child: MedPhoto(
                      radius: 28,
                      image: FileImage(
                        ref
                            .watch(medicinePhotoStorageProvider)
                            .resolve(m.photoPath),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                reminders,
              ],
            ),
            AsyncData() => _Message(
              'this medicine no longer exists.',
              light: light,
            ),
            AsyncError() => _Message(
              "this medicine couldn't be loaded.",
              light: light,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.medicine, required this.light});
  final Medicine medicine;
  final DayLight light;

  @override
  Widget build(BuildContext context) {
    final injectable = medicine.form == MedicineForm.injectable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Text(
            '‹  your medicines',
            style: figtree(17, FontWeight.w700, light.soft),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          medicine.displayName,
          style: figtree(44, FontWeight.w800, light.ink, letterSpacing: -1),
        ),
        Semantics(
          container: true,
          label: injectable ? 'Injectable' : 'Oral',
          excludeSemantics: true,
          child: Row(
            children: [
              SizedBox.square(
                dimension: MediaQuery.textScalerOf(context).scale(18),
                child: CustomPaint(
                  painter: FormMark(injectable: injectable, color: light.soft),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  injectable ? 'injectable' : 'oral',
                  style: figtree(17, FontWeight.w500, light.soft),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.light});
  final String text;
  final DayLight light;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Text(
          '‹  your medicines',
          style: figtree(17, FontWeight.w700, light.soft),
        ),
      ),
      const SizedBox(height: 24),
      Text(text, style: figtree(20, FontWeight.w700, light.ink)),
    ],
  );
}

/// A drawn bin with "delete" under it. Holding it (about a second) deletes
/// the medicine: a ring fills around the bin while held, and letting go
/// early rolls it back. A quick tap only says to hold.
class _HoldToDelete extends StatefulWidget {
  const _HoldToDelete({
    required this.light,
    required this.name,
    required this.onDelete,
  });
  final DayLight light;
  final String name;
  final VoidCallback onDelete;

  @override
  State<_HoldToDelete> createState() => _HoldToDeleteState();
}

class _HoldToDeleteState extends State<_HoldToDelete>
    with SingleTickerProviderStateMixin {
  late final _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    reverseDuration: const Duration(milliseconds: 250),
  )..addStatusListener(_done);
  bool _hint = false;

  void _done(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onDelete();
  }

  void _tapped() {
    setState(() => _hint = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.light.ink;
    return Semantics(
      button: true,
      label: 'Delete ${widget.name}',
      hint: 'Deletes the medicine, its photo, its reminders and their prints',
      excludeSemantics: true,
      onLongPress: widget.onDelete,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tapped,
        onLongPressStart: (_) => _hold.forward(),
        onLongPressEnd: (_) {
          if (!_hold.isCompleted) _hold.reverse();
        },
        onLongPressCancel: () {
          if (!_hold.isCompleted) _hold.reverse();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 12),
          child: Column(
            children: [
              SizedBox.square(
                dimension: 40,
                child: AnimatedBuilder(
                  animation: _hold,
                  builder: (context, _) => CustomPaint(
                    painter: _Bin(ink, Curves.easeIn.transform(_hold.value)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Both words keep their space, so the header never shifts.
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: _hint ? 0 : 1,
                    child: Text(
                      'delete',
                      style: figtree(13, FontWeight.w700, ink),
                    ),
                  ),
                  Opacity(
                    opacity: _hint ? 1 : 0,
                    child: Text(
                      'hold',
                      style: figtree(13, FontWeight.w700, ink),
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
}

/// A drawn bin with its lid; [held] (0–1) fills a ring around it and lifts
/// the lid as the hold goes on.
class _Bin extends CustomPainter {
  _Bin(this.ink, this.held);
  final Color ink;
  final double held;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.47;
    if (held > 0) {
      canvas.drawCircle(
        c,
        r,
        Paint()..color = ink.withValues(alpha: 0.08 * held),
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * held,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = ink,
      );
    }
    final u = s.width / 40;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;
    // The body, a little narrower at the bottom.
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 9 * u, c.dy - 6 * u)
        ..lineTo(c.dx - 7.5 * u, c.dy + 12 * u)
        ..lineTo(c.dx + 7.5 * u, c.dy + 12 * u)
        ..lineTo(c.dx + 9 * u, c.dy - 6 * u),
      line,
    );
    for (final x in [-3.5, 3.5]) {
      canvas.drawLine(
        Offset(c.dx + x * u, c.dy - 2 * u),
        Offset(c.dx + x * u, c.dy + 8 * u),
        line,
      );
    }
    // The lid, lifting as it is held.
    canvas.save();
    canvas.translate(c.dx, c.dy - 9 * u - 3 * u * held);
    canvas.rotate(-0.25 * held);
    canvas.drawLine(Offset(-11 * u, 0), Offset(11 * u, 0), line);
    canvas.drawLine(
      Offset(-3.5 * u, -3.5 * u),
      Offset(3.5 * u, -3.5 * u),
      line,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Bin old) => old.ink != ink || old.held != held;
}
