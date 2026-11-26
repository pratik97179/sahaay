// Reference prototype of Sahaay's Today ruler, prints and History (docs/design-system.md §18).
// Not part of the app and not in the pub workspace; see README.md.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

void main() => runApp(const Proto());

const _photo = AssetImage('assets/pills.jpg');

class Med {
  const Med(this.hour, this.time, this.name, this.note, {this.paused = false});
  final double hour;
  final String time, name, note;
  final bool paused;
}

const meds = [
  Med(7.5, '7:30 am', 'Test 2', '2 tablets, after food'),
  Med(13, '1:00 pm', 'Vitamin D', '1 capsule'),
  Med(19.5, '7:30 pm', 'Eye drops', '2 drops each eye', paused: true),
  Med(22, '10:00 pm', 'Test 2', '1 tablet, before sleep'),
];

const nowHour = 11 + 40 / 60;

/// The light of an hour: page tint and ink.
({Color page, Color ink, Color soft}) lightAt(double h) {
  const stops = <(double, Color)>[
    (0, Color(0xFF101327)),
    (5.5, Color(0xFF1B1F3D)),
    (7.5, Color(0xFFF6E3D3)),
    (12, Color(0xFFEEF1F0)),
    (17, Color(0xFFF1EBE4)),
    (19.5, Color(0xFFE7DEEC)),
    (21, Color(0xFF1B1F3D)),
    (24, Color(0xFF101327)),
  ];
  var page = stops.last.$2;
  for (var i = 0; i < stops.length - 1; i++) {
    final (a, ca) = stops[i];
    final (b, cb) = stops[i + 1];
    if (h >= a && h <= b) {
      page = Color.lerp(ca, cb, (h - a) / (b - a))!;
      break;
    }
  }
  final dark = page.computeLuminance() < 0.2;
  return (
    page: page,
    ink: dark ? const Color(0xFFF4F2EE) : const Color(0xFF141414),
    soft: dark ? const Color(0xFFB4B3C4) : const Color(0xFF5F6166),
  );
}

TextStyle f(double size, FontWeight w, Color c, {double h = 1.2, double ls = 0}) =>
    TextStyle(fontFamily: 'Figtree', fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

/// What the person has marked themselves: index → the time they marked it.
/// The app never infers this.
const today = 26; // Thursday, 26 November 2026.
final _marks = <int, ValueNotifier<Map<int, String>>>{};

/// The prints the person made on [day]: medicine index → the time they marked it.
ValueNotifier<Map<int, String>> marksFor(int day) => _marks.putIfAbsent(day, () {
  if (day == today) return ValueNotifier({0: '7:42 am'});
  final seeded = <int, String>{};
  for (var i = 0; i < meds.length; i++) {
    if (meds[i].paused) continue;
    if (day % 6 == 0 || (day + i * 2) % 4 == 0) continue; // some days, not every one was marked
    final h = meds[i].hour;
    final mins = ((h - h.floor()) * 60).round() + (day + i * 5) % 14;
    final hh = h.floor() + mins ~/ 60;
    seeded[i] = '${hh % 12 == 0 ? 12 : hh % 12}:${(mins % 60).toString().padLeft(2, '0')} ${hh < 12 ? 'am' : 'pm'}';
  }
  return ValueNotifier(seeded);
});

/// Now, as an hour, on [day]: the real time today; past days are over.
double nowOn(int day) => day == today ? nowHour : 24;

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
String weekdayOf(int day) => _weekdays[DateTime(2026, 11, day).weekday - 1];

void markTaken(int day, int i) => marksFor(day).value = {...marksFor(day).value, i: day == today ? '11:40 am' : 'later'};
void unmark(int day, int i) => marksFor(day).value = {...marksFor(day).value}..remove(i);

class Proto extends StatelessWidget {
  const Proto({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Figtree', splashFactory: NoSplash.splashFactory),
    // Show it at phone size in the browser.
    builder: (context, child) => ColoredBox(
      color: const Color(0xFF2A2A2A),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(44),
          child: SizedBox(
            width: 390,
            height: 844,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(size: const Size(390, 844), padding: const EdgeInsets.only(top: 47, bottom: 34)),
              child: child!,
            ),
          ),
        ),
      ]),
    ),
    home: const DayRuler(),
  );
}

/// The medicine photo: a soft-cornered frame, never a circle.
class MedPhoto extends StatelessWidget {
  const MedPhoto({required this.ink, this.radius = 36, super.key});
  final Color ink;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final shape = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius));
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: const Image(image: _photo, fit: BoxFit.cover),
      ),
    );
  }
}

class DayRuler extends StatefulWidget {
  const DayRuler({this.day = today, super.key});
  final int day;
  @override
  State<DayRuler> createState() => _DayRulerState();
}

class _DayRulerState extends State<DayRuler> with SingleTickerProviderStateMixin {
  static const pxPerHour = 64.0;

  late final ValueNotifier<Map<int, String>> _marks = marksFor(widget.day);
  bool get _isToday => widget.day == today;
  // Today starts on the next medicine; an earlier day starts on its first.
  late int _index = _isToday ? meds.indexWhere((m) => m.hour >= nowHour).clamp(0, meds.length - 1) : 0;
  late final AnimationController _hour = AnimationController.unbounded(vsync: this, value: meds[_index].hour)
    ..addListener(() => setState(() {}));
  bool _dragging = false;
  double _dragDx = 0;

  bool get _settled => !_dragging && !_hour.isAnimating;
  Med get _med => meds[_index];

  void _onDragStart(DragStartDetails d) {
    _hour.stop();
    _dragging = true;
    _dragDx = 0;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragDx += d.delta.dx;
    var next = _hour.value - d.delta.dx / pxPerHour;
    if (next < meds.first.hour || next > meds.last.hour) next = _hour.value - d.delta.dx / pxPerHour * 0.3;
    _hour.value = next;
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
    final v = d.velocity.pixelsPerSecond.dx;
    var step = 0;
    if (_dragDx < -24 || v < -300) step = 1;
    if (_dragDx > 24 || v > 300) step = -1;
    _go(_index + step, -v / pxPerHour);
  }

  void _go(int i, [double velocity = 0]) {
    final target = i.clamp(0, meds.length - 1);
    if (target != _index) HapticFeedback.selectionClick();
    setState(() => _index = target);
    if (MediaQuery.disableAnimationsOf(context)) {
      _hour.value = meds[target].hour;
      return;
    }
    _hour.animateWith(SpringSimulation(
      SpringDescription.withDampingRatio(mass: 1, stiffness: 170, ratio: 0.92),
      _hour.value,
      meds[target].hour,
      velocity,
    ));
  }

  void _open() {
    final i = _index;
    Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a, b) => ReminderPage(day: widget.day, index: i),
      transitionsBuilder: (context, a, b, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: const Cubic(0.23, 1, 0.32, 1))),
          child: child,
        ),
      ),
    ));
  }

  String get _when {
    if (!_isToday) return weekdayOf(widget.day).toLowerCase();
    if (_med.hour < nowHour) return 'earlier today';
    final firstUpcoming = meds.indexWhere((x) => x.hour >= nowHour);
    return _index == firstUpcoming ? 'next' : 'later today';
  }

  @override
  Widget build(BuildContext context) {
    final light = lightAt(_hour.value.clamp(0, 23.99));
    final m = _med;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) _go(_index + 1);
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft) _go(_index - 1);
        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: light.page,
        body: Stack(children: [
          SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: _isToday
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Thursday, 26 November', style: f(17, FontWeight.w600, light.soft)),
                            Text('good morning.', style: f(40, FontWeight.w800, light.ink, ls: -1)),
                          ]),
                        ),
                        _HistoryButton(light: light, onTap: () => Navigator.of(context).push(historyRoute())),
                      ])
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text('‹  november', style: f(17, FontWeight.w700, light.soft)),
                        ),
                        const SizedBox(height: 4),
                        Text('${weekdayOf(widget.day)}, ${widget.day} November', style: f(17, FontWeight.w600, light.soft)),
                        Text('${widget.day} november.', style: f(40, FontWeight.w800, light.ink, ls: -1)),
                      ]),
              ),
              const Spacer(),
              // The medicine under the needle. It drifts with the ruler and cross-fades between medicines.
              Center(
                child: SizedBox(
                  child: AnimatedSwitcher(
                    // The current photo shrinks into the bottom centre; then the next one grows out of it.
                    duration: const Duration(milliseconds: 440),
                    switchInCurve: const Interval(0.45, 1, curve: Curves.easeOutBack),
                    switchOutCurve: const Interval(0.5, 1, curve: Curves.easeIn),
                    layoutBuilder: (current, previous) => Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, a) => ScaleTransition(
                      scale: a,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_index),
                      child: Hero(
                        tag: 'photo${widget.day}-$_index',
                        child: SizedBox(width: 280, height: 210, child: HoldPhoto(day: widget.day, index: _index, light: light, onTap: _open)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: SizedBox(
                  height: 96,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                      stops: [0, 0.28, 0.72, 1],
                    ).createShader(r),
                    child: ListenableBuilder(
                      listenable: Listenable.merge([_marks, variant]),
                      builder: (context, _) => CustomPaint(
                        size: Size.infinite,
                        painter: _Ruler(_hour.value, pxPerHour, light.ink, light.soft, _index, _marks.value.keys.toSet(), variant.value, _isToday ? nowHour : null),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  _settled ? m.time : _clock(_hour.value),
                  style: f(56, FontWeight.w800, light.ink, h: 1.05, ls: -2),
                ),
              ),
              AnimatedOpacity(
                duration: Duration(milliseconds: _settled ? 260 : 90),
                opacity: _settled ? 1 : 0,
                child: AnimatedSlide(
                  duration: Duration(milliseconds: _settled ? 260 : 90),
                  curve: const Cubic(0.23, 1, 0.32, 1),
                  offset: _settled ? Offset.zero : const Offset(0, 0.2),
                  child: Column(children: [
                    const SizedBox(height: 4),
                    Text('${m.name}  ·  $_when', style: f(22, FontWeight.w700, light.ink)),
                    Text(m.paused ? 'Paused, won’t notify' : m.note, style: f(18, FontWeight.w500, light.soft)),
                    const SizedBox(height: 18),
                    TakenNote(day: widget.day, index: _index, light: light),
                  ]),
                ),
              ),
              const Spacer(),
              Center(child: Text('swipe the ruler  ·  tap the photo to open', style: f(14, FontWeight.w600, light.soft))),
              const SizedBox(height: 12),
            ]),
          ),
        ]),
      ),
    );
  }

  static String _clock(double h) {
    final c = h.clamp(0.0, 23.99);
    final hh = c.floor();
    final mm = ((c - hh) * 60).floor();
    final twelve = hh % 12 == 0 ? 12 : hh % 12;
    return '$twelve:${mm.toString().padLeft(2, '0')} ${hh < 12 ? 'am' : 'pm'}';
  }

  @override
  void dispose() {
    _hour.dispose();
    super.dispose();
  }
}

bool canMark(int day, int i) => meds[i].hour <= nowOn(day) + 0.5 && !meds[i].paused;

/// Which "taken" idea is shown: 0 print, 1 ink, 2 flip.
final variant = ValueNotifier<int>(0);

/// The medicine photo. A quick tap opens it; holding it marks it taken (or,
/// if it already was, unmarks it). Letting go early rolls back. How "taken"
/// looks depends on [variant].
class HoldPhoto extends StatefulWidget {
  const HoldPhoto({required this.day, required this.index, required this.light, this.onTap, this.radius = 36, super.key});
  final int day;
  final int index;
  final ({Color page, Color ink, Color soft}) light;
  final VoidCallback? onTap;
  final double radius;
  @override
  State<HoldPhoto> createState() => _HoldPhotoState();
}

class _HoldPhotoState extends State<HoldPhoto> with TickerProviderStateMixin {
  // Hold progress, 0 to 1.
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    reverseDuration: const Duration(milliseconds: 220),
  )..addStatusListener(_onStatus);
  // The settled "taken" state, 0 (not taken) to 1 (taken), animated.
  late final AnimationController _state = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: marksFor(widget.day).value.containsKey(widget.index) ? 1 : 0,
  );
  Timer? _press;

  bool get _isTaken => marksFor(widget.day).value.containsKey(widget.index);

  @override
  void initState() {
    super.initState();
    marksFor(widget.day).addListener(_sync);
  }

  void _sync() {
    final want = _isTaken ? 1.0 : 0.0;
    if (_state.value != want) {
      _state.animateTo(want, curve: want == 1 ? const Cubic(0.23, 1, 0.32, 1) : Curves.easeInOut);
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    HapticFeedback.mediumImpact();
    final i = widget.index;
    _isTaken ? unmark(widget.day, i) : markTaken(widget.day, i);
    _hold.value = 0;
  }

  void _down(PointerDownEvent e) {
    _press = Timer(const Duration(milliseconds: 160), () {
      _press = null;
      if (canMark(widget.day, widget.index)) _hold.forward();
    });
  }

  void _up(PointerUpEvent e) {
    if (_press != null) {
      _press!.cancel();
      _press = null;
      widget.onTap?.call();
    } else if (_hold.value > 0 && _hold.value < 1) {
      _hold.reverse();
    }
  }

  void _cancel(PointerCancelEvent e) {
    _press?.cancel();
    _press = null;
    if (_hold.value < 1) _hold.reverse();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _cancel,
    child: ValueListenableBuilder(
      valueListenable: variant,
      builder: (context, v, _) => AnimatedBuilder(
        animation: Listenable.merge([_hold, _state]),
        builder: (context, _) {
          // While holding, preview the change in the direction it will go.
          final t = (_isTaken ? _state.value - _hold.value * 0.6 : _state.value + _hold.value * 0.6).clamp(0.0, 1.0);
          final at = marksFor(widget.day).value[widget.index] ?? '11:40 am';
          return switch (v) {
            0 => _print(t, at),
            1 => _ink(t),
            _ => _flip(t, at),
          };
        },
      ),
    ),
  );

  /// 1. Print: taken turns the photo into an instant print — a paper frame
  /// develops around it, it tilts slightly as if set down, and the time is
  /// written on the strip.
  Widget _print(double t, String at) {
    final l = widget.light;
    const paper = Color(0xFFFBFAF6);
    return Transform.rotate(
      angle: -0.045 * t,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(Colors.transparent, paper, t),
          borderRadius: BorderRadius.circular(widget.radius * (1 - t * 0.75)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18 * t), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12 * t, 12 * t, 12 * t, 48 * t),
          child: Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: [
            MedPhoto(ink: l.ink, radius: widget.radius * (1 - t * 0.85)),
            Positioned(
              left: 4, right: 4, bottom: -40 * t,
              child: Opacity(
                opacity: ((t - 0.5) * 2).clamp(0.0, 1.0),
                child: Text('taken  ·  $at', textAlign: TextAlign.center, style: f(18, FontWeight.w700, const Color(0xFF2A2622))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// 2. Ink: holding fills the photo with ink from the bottom; when full, the
  /// ink drains down into the ruler and the needle is inked in (see the ruler).
  Widget _ink(double t) {
    final l = widget.light;
    final holding = _hold.value;
    final shape = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(widget.radius));
    return Stack(fit: StackFit.expand, children: [
      MedPhoto(ink: l.ink, radius: widget.radius),
      ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: holding,
            widthFactor: 1,
            child: ColoredBox(color: l.ink.withValues(alpha: 0.55)),
          ),
        ),
      ),
    ]);
  }

  /// 3. Flip: taken turns the photo over. Its back is plain ink with the
  /// word and the time, like the back of a card you have dealt with.
  Widget _flip(double t, String at) {
    final l = widget.light;
    final angle = t * math.pi;
    final back = angle > math.pi / 2;
    final shape = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(widget.radius));
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(angle),
      child: back
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: DecoratedBox(
                decoration: ShapeDecoration(color: l.ink, shape: shape),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('taken.', style: f(44, FontWeight.w800, l.page, ls: -1)),
                    Text(at, style: f(20, FontWeight.w600, l.page.withValues(alpha: 0.75))),
                  ]),
                ),
              ),
            )
          : MedPhoto(ink: l.ink, radius: widget.radius),
    );
  }

  @override
  void dispose() {
    marksFor(widget.day).removeListener(_sync);
    _press?.cancel();
    _hold.dispose();
    _state.dispose();
    super.dispose();
  }
}

/// One quiet line about the mark: what to do, or when it was marked.
class TakenNote extends StatelessWidget {
  const TakenNote({required this.day, required this.index, required this.light, super.key});
  final int day;
  final int index;
  final ({Color page, Color ink, Color soft}) light;
  @override
  Widget build(BuildContext context) {
    if (!canMark(day, index)) return const SizedBox(height: 22);
    return ValueListenableBuilder(
      valueListenable: marksFor(day),
      builder: (context, marks, _) {
        final at = marks[index];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            at == null ? 'hold the photo to mark it taken' : 'taken at $at  ·  hold to undo',
            key: ValueKey(at),
            style: f(16, FontWeight.w600, at == null ? light.soft : light.ink),
          ),
        );
      },
    );
  }
}

class _Ruler extends CustomPainter {
  _Ruler(this.hour, this.px, this.ink, this.soft, this.index, this.marked, this.v, this.now);
  final double hour, px;
  final Color ink, soft;
  final int index;
  final Set<int> marked;
  final int v;
  final double? now;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final base = size.height * 0.55;
    double x(double h) => cx + (h - hour) * px;
    final first = (hour - cx / px).floor() - 1;
    final last = (hour + cx / px).ceil() + 1;
    for (var q = first * 4; q <= last * 4; q++) {
      final h = q / 4;
      if (h < 0 || h > 24) continue;
      final major = q % 4 == 0;
      final half = q % 2 == 0;
      final len = major ? 26.0 : (half ? 15.0 : 9.0);
      canvas.drawLine(
        Offset(x(h), base - len),
        Offset(x(h), base),
        Paint()
          ..strokeWidth = major ? 2.2 : 1.4
          ..strokeCap = StrokeCap.round
          ..color = ink.withValues(alpha: major ? 0.75 : 0.3),
      );
      if (major) {
        final hh = h.round() % 24;
        final label = hh == 0 ? 'midnight' : hh == 12 ? 'noon' : '${hh % 12 == 0 ? 12 : hh % 12}${hh < 12 ? 'am' : 'pm'}';
        final tp = TextPainter(text: TextSpan(text: label, style: f(13, FontWeight.w700, soft)), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(x(h) - tp.width / 2, base + 8));
      }
    }
    // Each reminder on the ruler. Not yet due: a small dot. Due and not
    // marked: a ring. Marked: depends on the idea being shown.
    final inkPaint = Paint()..color = ink;
    for (var i = 0; i < meds.length; i++) {
      final m = meds[i];
      final c = Offset(x(m.hour), base - 42);
      final isTaken = marked.contains(i);
      if (i == index) {
        // Ink: the needle itself is inked in when the medicine under it is taken.
        if (isTaken && v == 1) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - 6, 0, cx + 6, base + 2), const Radius.circular(6)), inkPaint);
        }
        continue;
      }
      if (isTaken) {
        switch (v) {
          case 0: // a tiny print
            final r = Rect.fromCenter(center: c, width: 14, height: 17);
            canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFFFBFAF6));
            canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = ink);
            canvas.drawRect(Rect.fromLTWH(r.left + 3, r.top + 3, r.width - 6, r.height - 8), inkPaint);
          case 1: // an inked stroke down to the ruler
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(c.dx - 5, c.dy - 8, c.dx + 5, base + 2), const Radius.circular(5)), inkPaint);
          default: // a card face down
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 13, height: 17), const Radius.circular(3)), inkPaint);
        }
      } else if (m.hour <= (now ?? 24)) {
        canvas.drawCircle(c, 7, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = ink);
      } else {
        canvas.drawCircle(c, 4, Paint()..color = ink.withValues(alpha: 0.55));
      }
    }
    final n = now;
    if (n != null) {
      final nx = x(n);
      canvas.drawLine(Offset(nx, base - 30), Offset(nx, base + 4), Paint()..strokeWidth = 2..color = ink.withValues(alpha: 0.5));
      final tp = TextPainter(text: TextSpan(text: 'now', style: f(12, FontWeight.w800, ink)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(nx - tp.width / 2, base - 70));
    }
    canvas.drawLine(Offset(cx, 0), Offset(cx, base + 2), Paint()..strokeWidth = 3.5..strokeCap = StrokeCap.round..color = ink);
  }

  @override
  bool shouldRepaint(_Ruler old) => old.hour != hour || old.ink != ink || old.index != index || old.marked != marked || old.v != v || old.now != now;
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({required this.day, required this.index, super.key});
  final int day;
  final int index;
  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> with SingleTickerProviderStateMixin {
  late final AnimationController _drag = AnimationController.unbounded(vsync: this)..addListener(() => setState(() {}));

  @override
  Widget build(BuildContext context) {
    final m = meds[widget.index];
    final light = lightAt(m.hour);
    final pull = _drag.value.clamp(0.0, double.infinity);
    return GestureDetector(
      onVerticalDragUpdate: (d) => _drag.value += d.delta.dy,
      onVerticalDragEnd: (d) {
        if (_drag.value > 120 || d.velocity.pixelsPerSecond.dy > 700) {
          Navigator.of(context).pop();
        } else {
          _drag.animateWith(SpringSimulation(
            SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 0.85),
            _drag.value, 0, d.velocity.pixelsPerSecond.dy,
          ));
        }
      },
      child: Transform.translate(
        offset: Offset(0, pull),
        child: Transform.scale(
          scale: 1 - (pull / 3000).clamp(0, 0.08),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(pull > 0 ? 44 : 0),
            child: Scaffold(
              backgroundColor: light.page,
              body: Stack(children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: light.ink.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(3)))),
                      const SizedBox(height: 18),
                      Text(weekdayOf(widget.day).toLowerCase(), style: f(18, FontWeight.w600, light.soft)),
                      Text('${m.time}.', style: f(60, FontWeight.w800, light.ink, h: 1.05, ls: -2)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Hero(tag: 'photo${widget.day}-${widget.index}', child: HoldPhoto(day: widget.day, index: widget.index, light: light, radius: 44)),
                      ),
                      const SizedBox(height: 24),
                      Text(m.name, style: f(36, FontWeight.w800, light.ink, ls: -0.5)),
                      Text(m.paused ? 'Paused, won’t notify' : m.note, style: f(21, FontWeight.w500, light.ink)),
                      const SizedBox(height: 2),
                      Text('every day', style: f(17, FontWeight.w500, light.soft)),
                      const SizedBox(height: 22),
                      TakenNote(day: widget.day, index: widget.index, light: light),
                      const SizedBox(height: 22),
                      Row(children: [
                        Text('Pause', style: f(19, FontWeight.w700, light.ink)),
                        const SizedBox(width: 36),
                        Text('Edit', style: f(19, FontWeight.w700, light.ink)),
                      ]),
                      const SizedBox(height: 14),
                      Center(child: Text('swipe down to go back', style: f(14, FontWeight.w600, light.soft))),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }
}

/// History opens by fading in and growing from the centre.
Route<void> historyRoute() => PageRouteBuilder<void>(
  transitionDuration: const Duration(milliseconds: 360),
  reverseTransitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (context, a, b) => const HistoryPage(),
  transitionsBuilder: (context, a, b, child) {
    final curved = CurvedAnimation(parent: a, curve: const Cubic(0.23, 1, 0.32, 1), reverseCurve: Curves.easeIn);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curved), child: child),
    );
  },
);

/// Opens a past day's ruler.
Route<void> dayRoute(int day) => PageRouteBuilder<void>(
  transitionDuration: const Duration(milliseconds: 360),
  reverseTransitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (context, a, b) => DayRuler(day: day),
  transitionsBuilder: (context, a, b, child) {
    final curved = CurvedAnimation(parent: a, curve: const Cubic(0.23, 1, 0.32, 1), reverseCurve: Curves.easeIn);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
    );
  },
);

/// A small stack of prints: the way into History.
class _HistoryButton extends StatelessWidget {
  const _HistoryButton({required this.light, required this.onTap});
  final ({Color page, Color ink, Color soft}) light;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 0, 12),
      child: Column(children: [
        SizedBox(width: 40, height: 40, child: CustomPaint(painter: _PrintStack(light.ink))),
        const SizedBox(height: 4),
        Text('history', style: f(13, FontWeight.w700, light.ink)),
      ]),
    ),
  );
}

class _PrintStack extends CustomPainter {
  _PrintStack(this.ink);
  final Color ink;
  @override
  void paint(Canvas canvas, Size s) {
    void print(double dx, double angle, double alpha) {
      canvas.save();
      canvas.translate(s.width / 2 + dx, s.height / 2);
      canvas.rotate(angle);
      final r = Rect.fromCenter(center: Offset.zero, width: s.width * 0.62, height: s.height * 0.76);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFFFBFAF6));
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = ink.withValues(alpha: alpha));
      canvas.drawRect(Rect.fromLTWH(r.left + 3, r.top + 3, r.width - 6, r.height * 0.62), Paint()..color = ink.withValues(alpha: alpha));
      canvas.restore();
    }
    print(-5, -0.18, 0.45);
    print(4, 0.08, 1);
  }
  @override
  bool shouldRepaint(_PrintStack old) => old.ink != ink;
}

/// History: the month's prints as a flipbook. Swipe through the days like a
/// stack of photos; hold the stack and every day flies out to its place in
/// the month's calendar. Hold the calendar to gather them back.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  static const daysInMonth = 30;
  static const firstWeekday = 7; // 1 November 2026 is a Sunday (Monday = 1).

  // Days with prints, most recent first: the flipbook's pages.
  late final List<int> _days = [for (var d = today - 1; d >= 1; d--) if (marksFor(d).value.isNotEmpty) d];

  // The stack, top card first. Swiping sends the top card to the bottom.
  late List<int> _deck = List.generate(_days.length, (i) => i);
  // The swipe of the top card: 0 = resting on top, 0.5 = furthest out, 1 = tucked in at the bottom.
  late final AnimationController _swipe = AnimationController.unbounded(vsync: this)
    ..addListener(_redraw)
    ..addStatusListener(_swipeStatus);
  double _sign = 1; // which way the top card is going: -1 left, 1 right
  double _dragX = 0;
  bool _goingOut = false; // the released card is on its way to the bottom
  // How far the stack is pressed in while held: the cards sink and the fan closes.
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 240),
  )..addListener(_redraw);
  Rect _stackRect = Rect.zero;
  // 0 = flipbook, 1 = calendar.
  late final AnimationController _grid = AnimationController(vsync: this, duration: const Duration(milliseconds: 720))
    ..addListener(_redraw);
  Timer? _hold;
  bool _held = false; // the press that just switched views must not also open a day
  bool _dragging = false;
  double _cardW = 260;
  Size _area = Size.zero;

  void _redraw() => setState(() {});

  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  // ---- Flipbook: only the top card is swiped, either way; it goes to the bottom. ----

  double get _reach => _cardW * 0.78; // how far out a card goes before tucking in

  void _swipeStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed && status != AnimationStatus.dismissed) return;
    // The spring settles within a hair of 1; that counts as tucked in.
    if (_goingOut && _swipe.value >= 0.98) {
      // The top card is now at the bottom.
      setState(() {
        _deck = [..._deck.skip(1), _deck.first];
        _goingOut = false;
        _swipe.value = 0;
      });
    }
  }

  void _dragStart(DragStartDetails d) {
    _hold?.cancel();
    _press.animateBack(0, curve: Curves.easeOut); // a swipe is not a press
    _dragging = true;
    _swipe.stop();
    if (_goingOut) {
      // A card still flying to the bottom lands there at once; the card you see on top is the one you grab.
      _deck = [..._deck.skip(1), _deck.first];
      _goingOut = false;
      _swipe.value = 0;
    }
    _dragX = _sign * _reach * math.sin(math.pi * _swipe.value);
  }

  void _dragUpdate(DragUpdateDetails d) {
    _dragX += d.delta.dx;
    if (_dragX != 0) _sign = _dragX.sign;
    // The card follows the finger 1:1 out to its furthest point.
    final out = (_dragX.abs() / _reach).clamp(0.0, 1.0);
    _swipe.value = math.asin(out) / math.pi;
  }

  void _dragEnd(DragEndDetails d) {
    _dragging = false;
    final v = d.velocity.pixelsPerSecond.dx;
    final towardsOut = v * _sign > 0;
    final go = _swipe.value > 0.16 && v * _sign > -300 || towardsOut && v.abs() > 450;
    _goingOut = go;
    if (_reduced) {
      _swipe.value = go ? 1 : 0;
      _swipeStatus(AnimationStatus.completed);
      return;
    }
    if (go) HapticFeedback.selectionClick();
    // Quick and soft: the card is out and tucked in well under half a second.
    _swipe.animateWith(SpringSimulation(
      SpringDescription.withDampingRatio(mass: 1, stiffness: go ? 300 : 380, ratio: 1),
      _swipe.value,
      go ? 1.0 : 0.0,
      (v.abs() / (_reach * math.pi)) * (go ? 1 : -1) * 0.5,
    )..tolerance = const Tolerance(distance: 0.002, velocity: 0.01));
  }

  // ---- Hold to switch between flipbook and calendar. ----

  void _pressDown(PointerDownEvent e) {
    _held = false;
    final at = e.localPosition;
    // Holding the stack presses it in, in step with the hold.
    final onStack = _grid.value < 0.5 && _stackRect.inflate(12).contains(at);
    final onCalendar = _grid.value >= 0.5 && _dayAt(at) != null;
    if ((onStack || onCalendar) && !_reduced) _press.animateTo(1, curve: Curves.easeOut);
    _hold = Timer(const Duration(milliseconds: 380), () {
      _hold = null;
      if (_dragging) return;
      _held = true;
      HapticFeedback.mediumImpact();
      _press.animateBack(0, curve: Curves.easeOut);
      // Gathering from the calendar: the day you held lands on top.
      if (_grid.value > 0.5) {
        final day = _dayAt(at);
        final i = day == null ? -1 : _days.indexOf(day);
        if (i >= 0) {
          final at = _deck.indexOf(i);
          _deck = [..._deck.skip(at), ..._deck.take(at)];
          _swipe.value = 0;
        }
      }
      _toggle();
    });
  }

  void _pressUp(PointerEvent e) {
    _hold?.cancel();
    _hold = null;
    // Let go early: the cards come back out.
    _press.animateBack(0, curve: Curves.easeOutBack);
  }

  void _toggle() {
    final toGrid = _grid.value < 0.5;
    if (_reduced) {
      _grid.value = toGrid ? 1 : 0;
    } else {
      toGrid ? _grid.forward() : _grid.reverse();
    }
  }

  // The calendar keeps clear of the switch on its left and leaves room under the header.
  static const gridLeft = 0.0;
  static const gridTop = 92.0;
  static const gridGap = 7.0;

  /// The day whose calendar cell is under [p], if any.
  int? _dayAt(Offset p) {
    const gap = gridGap;
    final cell = (_area.width - gridLeft - gap * 6) / 7;
    final col = ((p.dx - gridLeft) / (cell + gap)).floor();
    final row = ((p.dy - gridTop) / (cell + gap)).floor();
    if (col < 0 || col > 6 || row < 0) return null;
    final day = row * 7 + col - (firstWeekday - 1) + 1;
    return day >= 1 && day <= daysInMonth ? day : null;
  }

  void _openDay(int day) {
    if (_held) return;
    Navigator.of(context).push(dayRoute(day));
  }

  // ---- Layout. ----

  @override
  Widget build(BuildContext context) {
    const light = (page: Color(0xFFEAEDF2), ink: Color(0xFF15171A), soft: Color(0xFF6B7079));
    final g = _grid.value;
    return Scaffold(
      backgroundColor: light.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text('‹  today', style: f(17, FontWeight.w700, light.soft)),
            ),
            const SizedBox(height: 10),
            Text('november.', style: f(44, FontWeight.w800, light.ink, ls: -1)),
            Text('your prints, day by day.', style: f(17, FontWeight.w500, light.soft)),
            Expanded(
              child: Stack(children: [
                Positioned.fill(
                  child: Listener(
                    onPointerDown: _pressDown,
                    onPointerUp: _pressUp,
                    onPointerCancel: _pressUp,
                    child: LayoutBuilder(builder: (context, box) {
                      _area = box.biggest;
                      return _book(box.biggest, light, g);
                    }),
                  ),
                ),
              ]),
            ),
            Center(
              child: _ViewSwitch(
                value: g,
                light: light,
                onSelect: (calendar) {
                  if (calendar != (_grid.value >= 0.5)) _toggle();
                },
              ),
            ),
            const SizedBox(height: 14),
            _controls(light, g),
          ]),
        ),
      ),
    );
  }

  /// Every print, positioned somewhere between its place in the stack and
  /// its day in the calendar.
  Widget _book(Size area, ({Color page, Color ink, Color soft}) light, double g) {
    // The calendar's geometry.
    const gap = gridGap;
    final cell = (area.width - gridLeft - gap * 6) / 7;
    Rect cellRect(int day) {
      final slot = firstWeekday - 1 + day - 1;
      return Rect.fromLTWH(gridLeft + (slot % 7) * (cell + gap), gridTop + (slot ~/ 7) * (cell + gap), cell, cell);
    }

    // The flipbook's geometry.
    _cardW = math.min(area.width * 0.66, 250.0);
    final cardH = _cardW * 1.27;
    // The switch row below the book (40 + 14 pt) shortens this area; the stack stays where it was on screen.
    final stack = Rect.fromCenter(center: area.center(Offset.zero).translate(0, 6 + 27), width: _cardW, height: cardH);
    _stackRect = stack;
    final pr = _press.value;
    // In the calendar, a press sinks every day a little about its own centre.
    Rect sunk(Rect r, double gridness) {
      final k = 1 - 0.08 * pr * gridness;
      return Rect.fromCenter(center: r.center, width: r.width * k, height: r.height * k);
    }

    final n = _days.length;
    final p = _swipe.value.clamp(0.0, 1.0);
    final rise = Curves.easeOut.transform(p); // the cards below move up as the top one leaves
    final bottom = math.min(n - 1, 2.5).toDouble();

    // Cards showing behind the top one; deeper cards fade in as they rise to this.
    const shown = 2.0;
    Rect placed(double depth, double side, {double dx = 0}) {
      final dd = depth.clamp(0.0, shown + 1);
      // Pressed in: the whole stack sinks a little, and the cards behind tuck in under the top one.
      final scale = (1 - dd * 0.045) * (1 - 0.045 * pr);
      // Every offset changes smoothly with depth, so nothing jumps as the stack moves up.
      final fan = side * (16 * depth.clamp(0.0, 1.0) - 6 * (depth - 1).clamp(0.0, 1.0)) * (1 - 0.55 * pr);
      return Rect.fromCenter(
        center: stack.center.translate(fan + dx, -dd * 9 * (1 - 0.5 * pr)),
        width: stack.width * scale,
        height: stack.height * scale,
      );
    }

    // Each print's place in the stack.
    ({Rect rect, double angle, double opacity, double depth}) stackPlace(int i) {
      final k = _deck.indexOf(i);
      final side = i.isEven ? -1.0 : 1.0;
      if (k == 0) {
        // The top card: out to the side it was swiped, then in at the bottom.
        final out = math.sin(math.pi * p);
        final depth = bottom * Curves.easeInOut.transform(p);
        final r = placed(depth, side, dx: _sign * _reach * out);
        final angle = _sign * out * 0.17 + side * math.min(depth, 1.0) * 0.095;
        final hidden = n - 1 > 2 ? (1 - ((p - 0.55) / 0.45).clamp(0.0, 1.0)) : 1.0;
        return (rect: r, angle: angle, opacity: hidden, depth: p < 0.5 ? -1 : 99);
      }
      final depth = k - rise;
      return (rect: placed(depth, side), angle: side * depth.clamp(0.0, 1.0) * 0.095 * (1 - 0.5 * pr), opacity: (shown + 1 - depth).clamp(0.0, 1.0), depth: depth);
    }

    final children = <Widget>[];

    // The calendar's frame: weekday letters and every day's cell, fading in.
    final frame = Curves.easeOut.transform(((g - 0.25) / 0.75).clamp(0, 1));
    if (frame > 0) {
      for (var c = 0; c < 7; c++) {
        children.add(Positioned(
          left: gridLeft + c * (cell + gap), top: gridTop - 38, width: cell,
          child: Opacity(opacity: frame, child: Text('MTWTFSS'[c], textAlign: TextAlign.center, style: f(15, FontWeight.w600, light.soft))),
        ));
      }
      for (var d = 1; d <= daysInMonth; d++) {
        final r = sunk(cellRect(d), g);
        children.add(Positioned.fromRect(
          rect: r,
          child: Opacity(
            opacity: frame,
            child: GestureDetector(
              onTap: d < today ? () => _openDay(d) : (d == today ? () { if (!_held) Navigator.of(context).pop(); } : null),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDADEE6).withValues(alpha: d > today ? 0.55 : 1),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ));
      }
    }

    // The prints: back of the stack first, so the top print is drawn last.
    // Back of the stack first; the swiped card is on top until halfway, then at the bottom.
    final places = {for (var i = 0; i < n; i++) i: stackPlace(i)};
    final order = List.generate(n, (i) => i)..sort((a, b) => places[b]!.depth.compareTo(places[a]!.depth));
    for (final i in order) {
      final day = _days[i];
      // Each print leaves a moment after the one before it.
      final stagger = 0.35 / math.max(n, 1);
      final local = const Cubic(0.23, 1, 0.32, 1).transform(((g - i * stagger) / (1 - 0.35)).clamp(0.0, 1.0));
      final s = places[i]!;
      if (s.opacity == 0 && local == 0) continue;
      final rect = Rect.lerp(s.rect, sunk(cellRect(day), local), local)!;
      final angle = s.angle * (1 - local);
      final opacity = s.opacity + (1 - s.opacity) * local;
      final isTop = _deck.first == i;
      children.add(Positioned.fromRect(
        key: ValueKey(day),
        rect: rect,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: angle,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: g > 0.5 ? () => _openDay(day) : null,
              child: _DayPrint(day: day, g: local, light: light, caption: isTop ? (1 - p * 2.2).clamp(0.0, 1.0) : (_deck.indexOf(i) == 1 ? ((p - 0.45) * 2).clamp(0.0, 1.0) : 0)),
            ),
          ),
        ),
      ));
    }
    // Over the top card's resting place: swiping and tapping the top card.
    if (g < 0.5) {
      children.add(Positioned.fromRect(
        rect: stack,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openDay(_days[_goingOut ? _deck[1 % n] : _deck.first]),
          onHorizontalDragStart: _dragStart,
          onHorizontalDragUpdate: _dragUpdate,
          onHorizontalDragEnd: _dragEnd,
          onHorizontalDragCancel: () {
            _dragging = false;
            _dragEnd(DragEndDetails());
          },
        ),
      ));
    }
    return Stack(clipBehavior: Clip.none, children: children);
  }

  /// Below the book: two round buttons for the flipbook; the month pill for the calendar.
  Widget _controls(({Color page, Color ink, Color soft}) light, double g) {
    final shadow = [BoxShadow(color: const Color(0xFF3A4150).withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 8))];
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: Stack(alignment: Alignment.center, children: [
        Opacity(
          opacity: (1 - g * 2).clamp(0, 1),
          child: Text('hold to see the whole month', style: f(14, FontWeight.w600, light.soft)),
        ),
        Opacity(
          opacity: ((g - 0.5) * 2).clamp(0, 1),
          child: IgnorePointer(
            ignoring: g < 0.5,
            child: Container(
              width: 210, height: 54,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.white, boxShadow: shadow),
              child: Row(children: [
                SizedBox(width: 54, child: CustomPaint(size: const Size(54, 54), painter: _Chevron(light.ink, AxisDirection.left))),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggle,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Nov', style: f(17, FontWeight.w700, light.ink)),
                    const SizedBox(width: 6),
                    SizedBox(width: 14, height: 14, child: CustomPaint(painter: _Chevron(light.ink, AxisDirection.down, size: 9))),
                  ]),
                  ),
                ),
                SizedBox(width: 54, child: CustomPaint(size: const Size(54, 54), painter: _Chevron(light.ink, AxisDirection.right))),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _hold?.cancel();
    _swipe.dispose();
    _press.dispose();
    _grid.dispose();
    super.dispose();
  }
}

/// One day's print. In the flipbook (g = 0) it is an instant print with the
/// date and how many prints were made; in the calendar (g = 1) it is just
/// the photo, filling the day's cell.
class _DayPrint extends StatelessWidget {
  const _DayPrint({required this.day, required this.g, required this.light, this.caption = 1});
  final double caption;
  final int day;
  final double g;
  final ({Color page, Color ink, Color soft}) light;
  @override
  Widget build(BuildContext context) {
    final prints = marksFor(day).value.length;
    final caption = (1 - g * 2.5).clamp(0.0, 1.0) * this.caption;
    final radius = 22 - 12 * g;
    return Container(
      padding: EdgeInsets.fromLTRB(11 * (1 - g), 11 * (1 - g), 11 * (1 - g), 76 * (1 - g)),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, Colors.transparent, g),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: const Color(0xFF3A4150).withValues(alpha: 0.16 * (1 - g)), blurRadius: 26 - 20 * g, offset: Offset(0, 12 - 10 * g))],
      ),
      child: Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: [
        ClipRRect(borderRadius: BorderRadius.circular(radius - 6 * (1 - g)), child: const Image(image: _photo, fit: BoxFit.cover)),
        if (caption > 0)
          Positioned(
            left: 0, right: 0, bottom: -64,
            child: Opacity(
              opacity: caption,
              child: Column(children: [
                Text('Nov $day', style: f(21, FontWeight.w800, const Color(0xFF15171A))),
                Text('$prints ${prints == 1 ? 'print' : 'prints'}', style: f(15, FontWeight.w400, const Color(0xFF6B7079))),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// A plain chevron, drawn, centred in its box.
class _Chevron extends CustomPainter {
  _Chevron(this.c, this.dir, {this.size = 12});
  final Color c;
  final AxisDirection dir;
  final double size;
  @override
  void paint(Canvas canvas, Size s) {
    final o = s.center(Offset.zero);
    final h = size / 2;
    final p = switch (dir) {
      AxisDirection.left => Path()..moveTo(o.dx + h * 0.5, o.dy - h)..lineTo(o.dx - h * 0.5, o.dy)..lineTo(o.dx + h * 0.5, o.dy + h),
      AxisDirection.right => Path()..moveTo(o.dx - h * 0.5, o.dy - h)..lineTo(o.dx + h * 0.5, o.dy)..lineTo(o.dx - h * 0.5, o.dy + h),
      AxisDirection.down => Path()..moveTo(o.dx - h, o.dy - h * 0.4)..lineTo(o.dx, o.dy + h * 0.5)..lineTo(o.dx + h, o.dy - h * 0.4),
      AxisDirection.up => Path()..moveTo(o.dx - h, o.dy + h * 0.4)..lineTo(o.dx, o.dy - h * 0.5)..lineTo(o.dx + h, o.dy + h * 0.4),
    };
    canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = c);
  }
  @override
  bool shouldRepaint(_Chevron old) => old.c != c || old.dir != dir;
}

/// A small sliding switch between the flipbook and the calendar: two drawn
/// icons on a soft track, the selected one on a raised square. Its thumb
/// follows the transition itself, so it slides in step with the cards.
class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.value, required this.light, required this.onSelect});
  final double value; // 0 = flipbook, 1 = calendar
  final ({Color page, Color ink, Color soft}) light;
  final ValueChanged<bool> onSelect;

  static const _seg = 34.0;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOut.transform(value.clamp(0.0, 1.0));
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xFFDDE1E8), borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: _seg * 2,
        height: _seg,
        child: Stack(children: [
          Positioned(
            left: _seg * t,
            top: 0,
            width: _seg,
            height: _seg,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [BoxShadow(color: const Color(0xFF3A4150).withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
              ),
            ),
          ),
          Row(children: [
            for (var i = 0; i < 2; i++)
              Semantics(
                button: true,
                label: i == 0 ? 'Flipbook' : 'Calendar',
                selected: (i == 1) == (value >= 0.5),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i == 1),
                  child: SizedBox.square(
                    dimension: _seg,
                    child: CustomPaint(
                      painter: _ViewIcon(
                        calendar: i == 1,
                        color: Color.lerp(light.soft, light.ink, i == 1 ? t : 1 - t)!,
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

/// The switch's two icons, drawn: a small stack of prints, and a month grid.
class _ViewIcon extends CustomPainter {
  _ViewIcon({required this.calendar, required this.color});
  final bool calendar;
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final c = s.center(Offset.zero);
    if (!calendar) {
      // Two prints, the back one tilted.
      canvas.save();
      canvas.translate(c.dx + 2, c.dy - 1);
      canvas.rotate(0.22);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 12, height: 15), const Radius.circular(2.5)), stroke);
      canvas.restore();
      final front = RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(-2, 1.5), width: 12, height: 15), const Radius.circular(2.5));
      canvas.drawRRect(front, stroke);
      canvas.drawRect(Rect.fromLTWH(front.left + 2.6, front.top + 2.6, front.width - 5.2, front.height * 0.5), Paint()..color = color);
    } else {
      // A three-by-three month grid.
      const cell = 4.2, gap = 2.0;
      final start = c.translate(-(cell * 3 + gap * 2) / 2, -(cell * 3 + gap * 2) / 2);
      for (var r = 0; r < 3; r++) {
        for (var k = 0; k < 3; k++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(start.dx + k * (cell + gap), start.dy + r * (cell + gap), cell, cell), const Radius.circular(1.2)),
            Paint()..color = color,
          );
        }
      }
    }
  }
  @override
  bool shouldRepaint(_ViewIcon old) => old.color != color || old.calendar != calendar;
}
