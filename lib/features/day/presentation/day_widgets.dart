// Ported exactly from the reference prototype (prototypes/day_and_history,
// docs/design-system.md §18), with its sample data replaced by real
// reminders and prints.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sahaay_design/sahaay_design.dart';

typedef Light = ({Color page, Color ink, Color soft});

/// The one screen colour for now: the 1 pm light. The colour that followed
/// the hour is on hold (docs/design-system.md §18.3).
final Light screenLight = lightAt(13);

/// The light of an hour: page tint and ink.
Light lightAt(double h) {
  final l = DayLight.at(h);
  return (page: l.page, ink: l.ink, soft: l.soft);
}

TextStyle f(
  double size,
  FontWeight w,
  Color c, {
  double h = 1.2,
  double ls = 0,
}) => figtree(size, w, c, height: h, letterSpacing: ls);

/// A time as the prototype writes it: "7:30 am".
String clockText(BuildContext context, int hour, int minute) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(
          TimeOfDay(hour: hour, minute: minute),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        )
        .toLowerCase();

/// The medicine photo: a soft-cornered frame, never a circle.
class MedPhoto extends StatelessWidget {
  const MedPhoto({required this.image, this.radius = 36, super.key});
  final ImageProvider image;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Image(
          image: image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) =>
              const ColoredBox(color: Color(0x22000000)),
        ),
      ),
    );
  }
}

/// The medicine photo. A quick tap opens it; holding it prints it (or, if
/// it already was, undoes the print). Letting go early rolls back.
class HoldPhoto extends StatefulWidget {
  const HoldPhoto({
    required this.image,
    required this.takenAt,
    required this.canMark,
    required this.onToggle,
    required this.light,
    this.onTap,
    this.radius = 36,
    super.key,
  });
  final ImageProvider image;

  /// When it was printed, or `null` when it isn't.
  final String? takenAt;
  final bool canMark;
  final VoidCallback onToggle;
  final Light light;
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
    value: _isTaken ? 1 : 0,
  );
  Timer? _press;

  bool get _isTaken => widget.takenAt != null;

  @override
  void didUpdateWidget(HoldPhoto old) {
    super.didUpdateWidget(old);
    final want = _isTaken ? 1.0 : 0.0;
    if (_state.value != want) {
      _state.animateTo(
        want,
        curve: want == 1 ? const Cubic(0.23, 1, 0.32, 1) : Curves.easeInOut,
      );
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    HapticFeedback.mediumImpact();
    widget.onToggle();
    _hold.value = 0;
  }

  void _down(PointerDownEvent e) {
    _press = Timer(const Duration(milliseconds: 160), () {
      _press = null;
      if (widget.canMark || _isTaken) _hold.forward();
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
    child: AnimatedBuilder(
      animation: Listenable.merge([_hold, _state]),
      builder: (context, _) {
        // While holding, preview the change in the direction it will go.
        final t =
            (_isTaken
                    ? _state.value - _hold.value * 0.6
                    : _state.value + _hold.value * 0.6)
                .clamp(0.0, 1.0);
        return _print(t, widget.takenAt ?? '');
      },
    ),
  );

  /// Print: taken turns the photo into an instant print — a paper frame
  /// develops around it, it tilts slightly as if set down, and the time is
  /// written on the strip.
  Widget _print(double t, String at) {
    const paper = Color(0xFFFBFAF6);
    return Transform.rotate(
      angle: -0.045 * t,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(Colors.transparent, paper, t),
          borderRadius: BorderRadius.circular(widget.radius * (1 - t * 0.75)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18 * t),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12 * t, 12 * t, 12 * t, 48 * t),
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              MedPhoto(
                image: widget.image,
                radius: widget.radius * (1 - t * 0.85),
              ),
              Positioned(
                left: 4,
                right: 4,
                bottom: -40 * t,
                child: Opacity(
                  opacity: ((t - 0.5) * 2).clamp(0.0, 1.0),
                  child: Text(
                    'taken  ·  $at',
                    textAlign: TextAlign.center,
                    style: f(18, FontWeight.w700, const Color(0xFF2A2622)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _press?.cancel();
    _hold.dispose();
    _state.dispose();
    super.dispose();
  }
}

/// One quiet line about the mark: what to do, or when it was marked.
class TakenNote extends StatelessWidget {
  const TakenNote({
    required this.takenAt,
    required this.canMark,
    required this.light,
    super.key,
  });
  final String? takenAt;
  final bool canMark;
  final Light light;
  @override
  Widget build(BuildContext context) {
    final at = takenAt;
    if (!canMark && at == null) return const SizedBox(height: 22);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        at == null
            ? 'hold the photo to mark it taken'
            : 'taken at $at  ·  hold to undo',
        key: ValueKey(at),
        style: f(16, FontWeight.w600, at == null ? light.soft : light.ink),
      ),
    );
  }
}

/// The day's ruler.
class RulerPainter extends CustomPainter {
  RulerPainter(
    this.hour,
    this.px,
    this.ink,
    this.soft,
    this.index,
    this.hours,
    this.marked,
    this.now,
    this.scaler,
    this.use24,
  );
  final double hour, px;
  final Color ink, soft;
  final int index;

  /// Each reminder's hour, in ruler order.
  final List<double> hours;

  /// The indexes of the printed reminders.
  final Set<int> marked;
  final double? now;
  final TextScaler scaler;
  final bool use24;

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
        final label = use24
            ? hh.toString().padLeft(2, '0')
            : hh == 0
            ? 'midnight'
            : hh == 12
            ? 'noon'
            : '${hh % 12 == 0 ? 12 : hh % 12}${hh < 12 ? 'am' : 'pm'}';
        final tp = TextPainter(
          text: TextSpan(text: label, style: f(13, FontWeight.w700, soft)),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        tp.paint(canvas, Offset(x(h) - tp.width / 2, base + 8));
      }
    }
    // Each reminder on the ruler. Not yet due: a small dot. Due and not
    // printed: a ring. Printed: a tiny print.
    final inkPaint = Paint()..color = ink;
    for (var i = 0; i < hours.length; i++) {
      final c = Offset(x(hours[i]), base - 42);
      if (i == index) continue;
      if (marked.contains(i)) {
        final r = Rect.fromCenter(center: c, width: 14, height: 17);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(2)),
          Paint()..color = const Color(0xFFFBFAF6),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = ink,
        );
        canvas.drawRect(
          Rect.fromLTWH(r.left + 3, r.top + 3, r.width - 6, r.height - 8),
          inkPaint,
        );
      } else if (hours[i] <= (now ?? 24)) {
        canvas.drawCircle(
          c,
          7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = ink,
        );
      } else {
        canvas.drawCircle(c, 4, Paint()..color = ink.withValues(alpha: 0.55));
      }
    }
    final n = now;
    if (n != null) {
      final nx = x(n);
      canvas.drawLine(
        Offset(nx, base - 30),
        Offset(nx, base + 4),
        Paint()
          ..strokeWidth = 2
          ..color = ink.withValues(alpha: 0.5),
      );
      final tp = TextPainter(
        text: TextSpan(text: 'now', style: f(12, FontWeight.w800, ink)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      tp.paint(canvas, Offset(nx - tp.width / 2, base - 70));
    }
    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, base + 2),
      Paint()
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(RulerPainter old) =>
      old.hour != hour ||
      old.ink != ink ||
      old.index != index ||
      old.marked != marked ||
      old.hours != hours ||
      old.now != now ||
      old.scaler != scaler ||
      old.use24 != use24;
}

/// A small stack of prints: the way into History.
class HistoryButton extends StatelessWidget {
  const HistoryButton({required this.light, required this.onTap, super.key});
  final Light light;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'History',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 0, 12),
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(painter: PrintStack(light.ink)),
            ),
            const SizedBox(height: 4),
            Text('history', style: f(13, FontWeight.w700, light.ink)),
          ],
        ),
      ),
    ),
  );
}

class PrintStack extends CustomPainter {
  PrintStack(this.ink);
  final Color ink;
  @override
  void paint(Canvas canvas, Size s) {
    void print(double dx, double angle, double alpha) {
      canvas.save();
      canvas.translate(s.width / 2 + dx, s.height / 2);
      canvas.rotate(angle);
      final r = Rect.fromCenter(
        center: Offset.zero,
        width: s.width * 0.62,
        height: s.height * 0.76,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()..color = const Color(0xFFFBFAF6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = ink.withValues(alpha: alpha),
      );
      canvas.drawRect(
        Rect.fromLTWH(r.left + 3, r.top + 3, r.width - 6, r.height * 0.62),
        Paint()..color = ink.withValues(alpha: alpha),
      );
      canvas.restore();
    }

    print(-5, -0.18, 0.45);
    print(4, 0.08, 1);
  }

  @override
  bool shouldRepaint(PrintStack old) => old.ink != ink;
}

/// Opens by fading in and growing from the centre (History, a past day).
Route<void> growRoute(Widget page, {double from = 0.9}) =>
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, a, b) => page,
      transitionsBuilder: (context, a, b, child) {
        final curved = CurvedAnimation(
          parent: a,
          curve: const Cubic(0.23, 1, 0.32, 1),
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: from, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
