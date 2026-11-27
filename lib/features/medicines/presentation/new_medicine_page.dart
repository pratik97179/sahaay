import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../app/routes.dart';
import '../domain/medicine.dart';
import '../medicines_providers.dart';
import 'add_medicine_extras.dart';

/// Adding a medicine in the makeover's language (PRD §5.1, FR-01; §18).
///
/// While the design is being chosen, two directions are shown and a small
/// switch (debug builds only) flips between them: A, everything on one
/// page; B, one step at a time.
class NewMedicinePage extends ConsumerStatefulWidget {
  const NewMedicinePage({this.createExtras, super.key});

  final CreateAddMedicineExtras? createExtras;

  @override
  ConsumerState<NewMedicinePage> createState() => _NewMedicinePageState();
}

class _NewMedicinePageState extends ConsumerState<NewMedicinePage> {
  final _name = TextEditingController();
  late final AddMedicineExtras? _extras = widget.createExtras?.call(ref);
  final _steps = PageController();
  String? _photoPath;
  MedicineForm? _form;
  bool _showErrors = false;
  bool _busy = false;
  int _step = 0;

  /// Set once the medicine is saved; the steps are then closed.
  String? _savedId;

  @override
  void dispose() {
    _name.dispose();
    _steps.dispose();
    _extras?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() => _busy = true);
    try {
      final path = await ref.read(photoCaptureProvider).capture();
      if (path != null && mounted) setState(() => _photoPath = path);
    } on Exception {
      _say("the camera couldn't be opened.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final photoPath = _photoPath;
    final form = _form;
    if (photoPath == null || form == null) {
      setState(() => _showErrors = true);
      _goTo(photoPath == null ? 0 : 2);
      return;
    }
    if (_busy || _savedId != null) return;
    setState(() => _busy = true);
    try {
      final id = await ref.read(addMedicineProvider)(
        name: _name.text,
        form: form,
        capturedPhotoPath: photoPath,
        alsoSave: _extras?.saveFor,
      );
      if (mounted) {
        setState(() {
          _savedId = id;
          _busy = false;
        });
      }
    } on Exception {
      _say("it couldn't be saved. please try again.");
      if (mounted) {
        setState(() => _busy = false);
        _goTo(_questions.length - 1);
      }
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _steps.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: const Cubic(0.23, 1, 0.32, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final light = DayLight.screen;
    return Scaffold(
      backgroundColor: light.page,
      body: SafeArea(child: _stepByStep(light)),
    );
  }

  // ---- The steps' contents. ----

  Widget _photo(DayLight light) => _PhotoSlot(
    path: _photoPath,
    light: light,
    missing: _showErrors && _photoPath == null,
    onTap: _busy ? null : _takePhoto,
  );

  Widget _nameField(DayLight light, {double size = 30}) => TextField(
    controller: _name,
    enabled: !_busy,
    textCapitalization: TextCapitalization.sentences,
    textInputAction: TextInputAction.done,
    style: figtree(size, FontWeight.w800, light.ink, letterSpacing: -0.5),
    cursorColor: light.ink,
    decoration: InputDecoration(
      hintText: 'its name',
      hintStyle: figtree(
        size,
        FontWeight.w800,
        light.soft.withValues(alpha: 0.5),
      ),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: light.soft.withValues(alpha: 0.3)),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: light.soft.withValues(alpha: 0.3)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: light.ink, width: 1.6),
      ),
      contentPadding: const EdgeInsets.only(bottom: 6),
      isDense: true,
      filled: false,
    ),
  );

  Widget _formChoice(DayLight light) => _FormChoice(
    value: _form,
    light: light,
    missing: _showErrors && _form == null,
    onChanged: _busy ? null : (f) => setState(() => _form = f),
  );

  // ---- One step at a time. ----

  static const _questions = [
    ('take its photo.', 'so you know it at a glance.'),
    ('what is it called?', 'you can leave this empty.'),
    ('how is it taken?', ''),
    ('when?', 'you can also do this later.'),
  ];

  Widget _stepByStep(DayLight light) {
    final saved = _savedId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _step == 0 || saved
                      ? () => Navigator.of(context).maybePop()
                      : () => _goTo(_step - 1),
                  child: Text(
                    _step == 0 || saved ? '‹  your medicines' : '‹  back',
                    style: figtree(17, FontWeight.w700, light.soft),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          // Arriving at the last page saves the medicine. Only once the
          // pages have settled there, so a drag that turns back doesn't.
          child: NotificationListener<ScrollEndNotification>(
            onNotification: (_) {
              if (_steps.page?.round() == _questions.length) {
                // After this frame: a page change can't start while the
                // scroll is still finishing.
                WidgetsBinding.instance.addPostFrameCallback((_) => _save());
              }
              return false;
            },
            child: PageView(
              controller: _steps,
              physics: saved ? const NeverScrollableScrollPhysics() : null,
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                for (final (i, (q, note)) in _questions.indexed)
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q,
                          style: figtree(
                            40,
                            FontWeight.w800,
                            light.ink,
                            letterSpacing: -1,
                          ),
                        ),
                        if (note.isNotEmpty)
                          Text(
                            note,
                            style: figtree(17, FontWeight.w500, light.soft),
                          ),
                        const SizedBox(height: 28),
                        switch (i) {
                          0 => _photo(light),
                          1 => _nameField(light, size: 36),
                          2 => _formChoice(light),
                          _ =>
                            _extras?.buildSection(context, enabled: !_busy) ??
                                const SizedBox.shrink(),
                        },
                      ],
                    ),
                  ),
                _Saved(
                  photoPath: _photoPath,
                  name: _name.text.trim(),
                  saving: !saved,
                  light: light,
                  onOpen: saved
                      ? () => context.pushReplacement(
                          AppRoutes.medicine(_savedId!),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Center(
            // Rebuilt on its own as the name or the reminders change.
            child: ListenableBuilder(
              listenable: Listenable.merge([_name, ?_extras?.filled]),
              builder: (context, _) => _StepIndicator(
                controller: _steps,
                step: _step,
                light: light,
                done: [
                  _photoPath != null,
                  _name.text.trim().isNotEmpty,
                  _form != null,
                  _extras?.filled.value ?? false,
                  false,
                ],
                labels: const [
                  'photo',
                  'name',
                  'how it’s taken',
                  'when',
                  'saved',
                ],
                onSelect: saved ? (_) {} : _goTo,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The medicine's photo: a soft-cornered frame. Empty, it is a dashed
/// outline with a drawn camera; tapping takes (or retakes) the photo.
class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.path,
    required this.light,
    required this.missing,
    required this.onTap,
  });
  final String? path;
  final DayLight light;
  final bool missing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    return Semantics(
      button: true,
      label: path == null ? 'Take its photo' : 'Retake the photo',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: path == null
                  ? CustomPaint(
                      painter: _Dashed(missing ? light.ink : light.soft, 36),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: 56,
                              child: CustomPaint(painter: _Camera(light.ink)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'take its photo',
                              style: figtree(18, FontWeight.w800, light.ink),
                            ),
                          ],
                        ),
                      ),
                    )
                  : MedPhoto(image: FileImage(File(path))),
            ),
            const SizedBox(height: 8),
            Text(
              path == null
                  ? (missing ? 'a photo is needed.' : 'with the camera')
                  : 'tap the photo to take it again',
              style: figtree(
                15,
                missing ? FontWeight.w700 : FontWeight.w500,
                missing ? light.ink : light.soft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two drawn objects to choose how it's taken: a capsule (oral) and a
/// syringe (injectable). The chosen one is drawn solid, its word bold.
class _FormChoice extends StatelessWidget {
  const _FormChoice({
    required this.value,
    required this.light,
    required this.missing,
    required this.onChanged,
  });
  final MedicineForm? value;
  final DayLight light;
  final bool missing;
  final ValueChanged<MedicineForm>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 36,
        runSpacing: 16,
        children: [
          for (final (form, word) in const [
            (MedicineForm.oral, 'oral'),
            (MedicineForm.injectable, 'injectable'),
          ])
            Semantics(
              button: true,
              selected: value == form,
              label: word,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChanged == null ? null : () => onChanged!(form),
                child: Column(
                  children: [
                    SizedBox.square(
                      dimension: MediaQuery.textScalerOf(context).scale(64),
                      child: CustomPaint(
                        painter: FormMark(
                          injectable: form == MedicineForm.injectable,
                          color: value == form
                              ? light.ink
                              : light.soft.withValues(alpha: 0.6),
                          filled: value == form,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      word,
                      style: figtree(
                        18,
                        value == form ? FontWeight.w800 : FontWeight.w500,
                        value == form ? light.ink : light.soft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      if (missing)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'choose how it’s taken.',
            style: figtree(15, FontWeight.w700, light.ink),
          ),
        ),
    ],
  );
}

/// A drawn header button with a word under it, like Today's buttons.

/// A small drawn camera.
class _Camera extends CustomPainter {
  _Camera(this.ink);
  final Color ink;
  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..color = ink;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        s.width * 0.08,
        s.height * 0.28,
        s.width * 0.84,
        s.height * 0.56,
      ),
      Radius.circular(s.width * 0.12),
    );
    canvas.drawRRect(body, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * 0.34,
          s.height * 0.16,
          s.width * 0.32,
          s.height * 0.14,
        ),
        Radius.circular(s.width * 0.04),
      ),
      stroke,
    );
    canvas.drawCircle(
      Offset(s.width / 2, s.height * 0.56),
      s.width * 0.16,
      stroke,
    );
  }

  @override
  bool shouldRepaint(_Camera old) => old.ink != ink;
}

class _Dashed extends CustomPainter {
  _Dashed(this.color, this.radius);
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = color.withValues(alpha: 0.7);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed old) => old.color != color;
}

/// Where you are in adding a medicine, at the bottom of the screen: the
/// current step is its own small drawn icon (a camera, a pencil, a capsule,
/// a clock), the others are dots. As the steps change, the outgoing icon
/// turns and shrinks into a dot while the next dot turns and grows into its
/// icon, following the swipe itself. Tapping a mark goes to that step.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.controller,
    required this.step,
    required this.light,
    required this.labels,
    required this.done,
    required this.onSelect,
  });
  final PageController controller;
  final int step;
  final DayLight light;
  final List<String> labels;

  /// Per step, whether its entry is filled in: its dot is then a tick.
  final List<bool> done;
  final ValueChanged<int> onSelect;

  /// The active icon's size: a little larger than the header's drawn stamps.
  static const _icon = 34.0;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final page = controller.hasClients && controller.position.haveDimensions
          ? controller.page ?? step.toDouble()
          : step.toDouble();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            Semantics(
              button: true,
              selected: i == step,
              label:
                  'Step ${i + 1} of ${labels.length}: ${labels[i]}'
                  '${done[i] ? ', done' : ''}',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: Builder(
                  builder: (context) {
                    final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
                    // Dots sit close together; the active step widens to
                    // hold its icon.
                    return SizedBox(
                      width: 16 + (_icon + 10 - 16) * t,
                      height: 48,
                      child: CustomPaint(
                        painter: _StepMark(
                          step: i,
                          t: t,
                          done: done[i],
                          ink: light.ink,
                          size: _icon,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// One step's mark: a small dot at [t] = 0 (a small tick once [done]), its
/// drawn icon at [t] = 1. In between it turns half a revolution while it
/// grows or shrinks.
class _StepMark extends CustomPainter {
  _StepMark({
    required this.step,
    required this.t,
    required this.done,
    required this.ink,
    required this.size,
  });
  final int step;
  final double t;
  final bool done;
  final Color ink;
  final double size;

  static const _paper = Paper.sheet;

  @override
  void paint(Canvas canvas, Size box) {
    final e = Curves.easeInOut.transform(t);
    canvas.save();
    canvas.translate(box.width / 2, box.height / 2);
    // A small upright tick, drawn before the turn so it never shows upside
    // down; it fades as the icon grows out of it.
    if (done && e < 1) {
      canvas.drawPath(
        Path()
          ..moveTo(-4, 0.2)
          ..lineTo(-1.2, 3)
          ..lineTo(4.2, -2.8),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ink.withValues(alpha: 0.7 * (1 - e)),
      );
    }
    canvas.rotate((1 - e) * math.pi);
    // A crisp ink dot that fades as the icon grows out of it.
    if (!done && e < 1) {
      canvas.drawCircle(
        Offset.zero,
        3.5,
        Paint()..color = ink.withValues(alpha: 0.32 * (1 - e)),
      );
    }
    if (e > 0) {
      canvas.scale(0.2 + 0.8 * e);
      _icon(canvas, e);
    }
    canvas.restore();
  }

  /// Bold, solid icons in ink, like the bottle and the print stack.
  void _icon(Canvas canvas, double opacity) {
    final u = size / 24; // a 24-unit grid, centred on the origin
    final ink = Paint()..color = this.ink.withValues(alpha: opacity);
    final paper = Paint()..color = _paper.withValues(alpha: opacity);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = this.ink.withValues(alpha: opacity);
    switch (step) {
      case 0: // camera: solid body, a paper lens
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(-4.5 * u, -9 * u, 4.5 * u, -4 * u),
            Radius.circular(1.6 * u),
          ),
          ink,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(-11 * u, -6 * u, 11 * u, 9 * u),
            Radius.circular(4 * u),
          ),
          ink,
        );
        canvas.drawCircle(Offset(0, 1.5 * u), 4.6 * u, paper);
        canvas.drawCircle(Offset(0, 1.5 * u), 2.2 * u, ink);
      case 1: // pencil: solid body and tip, a paper band
        canvas.save();
        canvas.rotate(-math.pi / 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(-11 * u, -3.6 * u, 5 * u, 3.6 * u),
            Radius.circular(1.6 * u),
          ),
          ink,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5 * u, -3.6 * u)
            ..lineTo(11.5 * u, 0)
            ..lineTo(5 * u, 3.6 * u)
            ..close(),
          ink,
        );
        canvas.drawRect(
          Rect.fromLTRB(-7 * u, -3.6 * u, -5.4 * u, 3.6 * u),
          paper,
        );
        canvas.restore();
      case 2: // capsule: one half solid, one half paper, a bold outline
        canvas.save();
        canvas.rotate(-math.pi / 4);
        final r = RRect.fromRectAndRadius(
          Rect.fromLTRB(-11 * u, -5 * u, 11 * u, 5 * u),
          Radius.circular(5 * u),
        );
        canvas.drawRRect(r, paper);
        canvas.save();
        canvas.clipRRect(r);
        canvas.drawRect(Rect.fromLTRB(-11 * u, -5 * u, 0, 5 * u), ink);
        canvas.restore();
        canvas.drawRRect(r, line);
        canvas.restore();
      case 3: // clock: a solid face, paper hands
        canvas.drawCircle(Offset.zero, 11 * u, ink);
        final hands = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 * u
          ..strokeCap = StrokeCap.round
          ..color = _paper.withValues(alpha: opacity);
        canvas.drawLine(Offset.zero, Offset(0, -6.5 * u), hands);
        canvas.drawLine(Offset.zero, Offset(4.5 * u, 2.5 * u), hands);
      default: // saved: a solid stamp with a paper tick
        canvas.drawCircle(Offset.zero, 11 * u, ink);
        canvas.drawPath(
          Path()
            ..moveTo(-5 * u, 0.3 * u)
            ..lineTo(-1.2 * u, 4 * u)
            ..lineTo(5.5 * u, -3.6 * u),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8 * u
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = _paper.withValues(alpha: opacity),
        );
    }
  }

  @override
  bool shouldRepaint(_StepMark old) =>
      old.t != t || old.done != done || old.ink != ink || old.step != step;
}

/// The last page: the medicine, saved, set down as a print on the shelf.
/// It lays out like the steps before it, so nothing moves on arrival.
class _Saved extends StatelessWidget {
  const _Saved({
    required this.photoPath,
    required this.name,
    required this.saving,
    required this.light,
    required this.onOpen,
  });
  final String? photoPath;
  final String name;
  final bool saving;
  final DayLight light;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            saving ? 'saving…' : 'it’s saved.',
            style: figtree(40, FontWeight.w800, light.ink, letterSpacing: -1),
          ),
          Text(
            'you’ll find it in your medicines.',
            style: figtree(17, FontWeight.w500, light.soft),
          ),
          const SizedBox(height: 28),
          if (path != null)
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.62,
                child: Transform.rotate(
                  angle: -0.035,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                    decoration: BoxDecoration(
                      color: Paper.sheet,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(path), fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name.isEmpty ? 'unnamed' : name,
                          style: figtree(18, FontWeight.w800, Paper.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 28),
          AnimatedOpacity(
            opacity: onOpen == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpen,
                child: Text(
                  'see its reminders  ›',
                  style: figtree(17, FontWeight.w700, light.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
