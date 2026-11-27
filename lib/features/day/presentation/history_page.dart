// Ported exactly from the reference prototype's HistoryPage
// (prototypes/day_and_history, docs/design-system.md §18.3), on real prints.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../reminders/domain/calendar.dart';
import 'day_data.dart';
import 'day_page.dart';
import 'day_widgets.dart';

/// History: the month's prints as a flipbook. Swipe through the days like a
/// stack of photos; hold the stack and every day flies out to its place in
/// the month's calendar. Hold the calendar to gather them back (FR-13).
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = nowOf(ref).date;
    return _History(today: today, days: ref.watch(printedDaysProvider(today)));
  }
}

class _History extends StatefulWidget {
  const _History({required this.today, required this.days});
  final LocalDate today;
  final List<PrintedDay> days;
  @override
  State<_History> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_History> with TickerProviderStateMixin {
  LocalDate get _month => widget.today;
  int get today => widget.today.day;
  int get daysInMonth => LocalDate.daysInMonth(_month.year, _month.month);
  int get firstWeekday => LocalDate(_month.year, _month.month, 1).weekday;

  // Days with prints, most recent first: the flipbook's pages.
  List<int> get _days => [for (final d in widget.days) d.day];
  PrintedDay _printed(int day) => widget.days.firstWhere((d) => d.day == day);

  // The stack, top card first. Swiping sends the top card to the bottom.
  late List<int> _deck = List.generate(_days.length, (i) => i);
  // The swipe of the top card: 0 = resting on top, 0.5 = furthest out, 1 = tucked in at the bottom.
  late final AnimationController _swipe =
      AnimationController.unbounded(vsync: this)
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
  late final AnimationController _grid = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..addListener(_redraw);
  Timer? _hold;
  bool _held =
      false; // the press that just switched views must not also open a day
  bool _dragging = false;
  double _cardW = 260;
  Size _area = Size.zero;

  @override
  void didUpdateWidget(_History old) {
    super.didUpdateWidget(old);
    if (old.days.length != widget.days.length) {
      _deck = List.generate(_days.length, (i) => i);
      _swipe.value = 0;
      _goingOut = false;
    }
  }

  void _redraw() => setState(() {});

  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  // ---- Flipbook: only the top card is swiped, either way; it goes to the bottom. ----

  double get _reach =>
      _cardW * 0.78; // how far out a card goes before tucking in

  void _swipeStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed &&
        status != AnimationStatus.dismissed) {
      return;
    }
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
    final go =
        _swipe.value > 0.16 && v * _sign > -300 || towardsOut && v.abs() > 450;
    _goingOut = go;
    if (_reduced) {
      _swipe.value = go ? 1 : 0;
      _swipeStatus(AnimationStatus.completed);
      return;
    }
    if (go) HapticFeedback.selectionClick();
    // Quick and soft: the card is out and tucked in well under half a second.
    _swipe.animateWith(
      SpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 1,
          stiffness: go ? 300 : 380,
          ratio: 1,
        ),
        _swipe.value,
        go ? 1.0 : 0.0,
        (v.abs() / (_reach * math.pi)) * (go ? 1 : -1) * 0.5,
      )..tolerance = const Tolerance(distance: 0.002, velocity: 0.01),
    );
  }

  // ---- Hold to switch between flipbook and calendar. ----

  void _pressDown(PointerDownEvent e) {
    _held = false;
    final at = e.localPosition;
    // Holding the stack presses it in, in step with the hold.
    final onStack = _grid.value < 0.5 && _stackRect.inflate(12).contains(at);
    final onCalendar = _grid.value >= 0.5 && _dayAt(at) != null;
    if ((onStack || onCalendar) && !_reduced) {
      _press.animateTo(1, curve: Curves.easeOut);
    }
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
    Navigator.of(context).push(
      growRoute(
        DayPage(day: LocalDate(_month.year, _month.month, day)),
        from: 0.94,
      ),
    );
  }

  // ---- Layout. ----

  @override
  Widget build(BuildContext context) {
    // The same 1 pm colour as the ruler screens, with History's own ink.
    final light = DayLight.screen.withInk(
      ink: const Color(0xFF15171A),
      soft: const Color(0xFF6B7079),
    );
    final g = _grid.value;
    return Scaffold(
      backgroundColor: light.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  '‹  today',
                  style: figtree(17, FontWeight.w700, light.soft),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${monthName(_month.month).toLowerCase()}.',
                style: figtree(
                  44,
                  FontWeight.w800,
                  light.ink,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'your prints, day by day.',
                style: figtree(17, FontWeight.w500, light.soft),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Listener(
                        onPointerDown: _pressDown,
                        onPointerUp: _pressUp,
                        onPointerCancel: _pressUp,
                        child: LayoutBuilder(
                          builder: (context, box) {
                            _area = box.biggest;
                            return _book(box.biggest, light, g);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
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
            ],
          ),
        ),
      ),
    );
  }

  /// Every print, positioned somewhere between its place in the stack and
  /// its day in the calendar.
  Widget _book(Size area, DayLight light, double g) {
    // The calendar's geometry.
    const gap = gridGap;
    final cell = (area.width - gridLeft - gap * 6) / 7;
    Rect cellRect(int day) {
      final slot = firstWeekday - 1 + day - 1;
      return Rect.fromLTWH(
        gridLeft + (slot % 7) * (cell + gap),
        gridTop + (slot ~/ 7) * (cell + gap),
        cell,
        cell,
      );
    }

    // The flipbook's geometry.
    _cardW = math.min(area.width * 0.66, 250.0);
    final cardH = _cardW * 1.27;
    // The switch row below the book (40 + 14 pt) shortens this area; the stack stays where it was on screen.
    final stack = Rect.fromCenter(
      center: area.center(Offset.zero).translate(0, 6 + 27),
      width: _cardW,
      height: cardH,
    );
    _stackRect = stack;
    final pr = _press.value;
    // In the calendar, a press sinks every day a little about its own centre.
    Rect sunk(Rect r, double gridness) {
      final k = 1 - 0.08 * pr * gridness;
      return Rect.fromCenter(
        center: r.center,
        width: r.width * k,
        height: r.height * k,
      );
    }

    final n = _days.length;
    final p = _swipe.value.clamp(0.0, 1.0);
    final rise = Curves.easeOut.transform(
      p,
    ); // the cards below move up as the top one leaves
    final bottom = math.min(n - 1, 2.5).toDouble();

    // Cards showing behind the top one; deeper cards fade in as they rise to this.
    const shown = 2.0;
    Rect placed(double depth, double side, {double dx = 0}) {
      final dd = depth.clamp(0.0, shown + 1);
      // Pressed in: the whole stack sinks a little, and the cards behind tuck in under the top one.
      final scale = (1 - dd * 0.045) * (1 - 0.045 * pr);
      // Every offset changes smoothly with depth, so nothing jumps as the stack moves up.
      final fan =
          side *
          (16 * depth.clamp(0.0, 1.0) - 6 * (depth - 1).clamp(0.0, 1.0)) *
          (1 - 0.55 * pr);
      return Rect.fromCenter(
        center: stack.center.translate(fan + dx, -dd * 9 * (1 - 0.5 * pr)),
        width: stack.width * scale,
        height: stack.height * scale,
      );
    }

    // Each print's place in the stack.
    ({Rect rect, double angle, double opacity, double depth}) stackPlace(
      int i,
    ) {
      final k = _deck.indexOf(i);
      final side = i.isEven ? -1.0 : 1.0;
      if (k == 0) {
        // The top card: out to the side it was swiped, then in at the bottom.
        final out = math.sin(math.pi * p);
        final depth = bottom * Curves.easeInOut.transform(p);
        final r = placed(depth, side, dx: _sign * _reach * out);
        final angle = _sign * out * 0.17 + side * math.min(depth, 1.0) * 0.095;
        final hidden = n - 1 > 2
            ? (1 - ((p - 0.55) / 0.45).clamp(0.0, 1.0))
            : 1.0;
        return (
          rect: r,
          angle: angle,
          opacity: hidden,
          depth: p < 0.5 ? -1 : 99,
        );
      }
      final depth = k - rise;
      return (
        rect: placed(depth, side),
        angle: side * depth.clamp(0.0, 1.0) * 0.095 * (1 - 0.5 * pr),
        opacity: (shown + 1 - depth).clamp(0.0, 1.0),
        depth: depth,
      );
    }

    final children = <Widget>[];

    // The calendar's frame: weekday letters and every day's cell, fading in.
    final frame = Curves.easeOut.transform(((g - 0.25) / 0.75).clamp(0, 1));
    if (frame > 0) {
      for (var c = 0; c < 7; c++) {
        children.add(
          Positioned(
            left: gridLeft + c * (cell + gap),
            top: gridTop - 38,
            width: cell,
            child: Opacity(
              opacity: frame,
              child: Text(
                'MTWTFSS'[c],
                textAlign: TextAlign.center,
                style: figtree(15, FontWeight.w600, light.soft),
              ),
            ),
          ),
        );
      }
      for (var d = 1; d <= daysInMonth; d++) {
        final r = sunk(cellRect(d), g);
        children.add(
          Positioned.fromRect(
            rect: r,
            child: Opacity(
              opacity: frame,
              child: GestureDetector(
                onTap: d < today
                    ? () => _openDay(d)
                    : (d == today
                          ? () {
                              if (!_held) Navigator.of(context).pop();
                            }
                          : null),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDADEE6)
                        .withValues(alpha: d > today ? 0.55 : 1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    if (n == 0) {
      // No prints yet this month: nothing to stack.
      children.add(
        Positioned.fromRect(
          rect: stack,
          child: Opacity(
            opacity: 1 - frame,
            child: Center(
              child: Text(
                'no prints yet this month.',
                textAlign: TextAlign.center,
                style: figtree(17, FontWeight.w600, light.soft),
              ),
            ),
          ),
        ),
      );
      return Stack(clipBehavior: Clip.none, children: children);
    }

    // The prints: back of the stack first, so the top print is drawn last.
    // Back of the stack first; the swiped card is on top until halfway, then at the bottom.
    final places = {for (var i = 0; i < n; i++) i: stackPlace(i)};
    final order = List.generate(n, (i) => i)
      ..sort((a, b) => places[b]!.depth.compareTo(places[a]!.depth));
    for (final i in order) {
      final day = _days[i];
      // Each print leaves a moment after the one before it.
      final stagger = 0.35 / math.max(n, 1);
      final local = const Cubic(
        0.23,
        1,
        0.32,
        1,
      ).transform(((g - i * stagger) / (1 - 0.35)).clamp(0.0, 1.0));
      final s = places[i]!;
      if (s.opacity == 0 && local == 0) continue;
      final rect = Rect.lerp(s.rect, sunk(cellRect(day), local), local)!;
      final angle = s.angle * (1 - local);
      final opacity = s.opacity + (1 - s.opacity) * local;
      final isTop = _deck.first == i;
      children.add(
        Positioned.fromRect(
          key: ValueKey(day),
          rect: rect,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: angle,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: g > 0.5 ? () => _openDay(day) : null,
                child: _DayPrint(
                  printed: _printed(day),
                  month: _month.month,
                  g: local,
                  light: light,
                  caption: isTop
                      ? (1 - p * 2.2).clamp(0.0, 1.0)
                      : (_deck.indexOf(i) == 1
                            ? ((p - 0.45) * 2).clamp(0.0, 1.0)
                            : 0),
                ),
              ),
            ),
          ),
        ),
      );
    }
    // Over the top card's resting place: swiping and tapping the top card.
    if (g < 0.5) {
      children.add(
        Positioned.fromRect(
          rect: stack,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                _openDay(_days[_goingOut ? _deck[1 % n] : _deck.first]),
            onHorizontalDragStart: _dragStart,
            onHorizontalDragUpdate: _dragUpdate,
            onHorizontalDragEnd: _dragEnd,
            onHorizontalDragCancel: () {
              _dragging = false;
              _dragEnd(DragEndDetails());
            },
          ),
        ),
      );
    }
    return Stack(clipBehavior: Clip.none, children: children);
  }

  /// Below the book: a hint for the flipbook; the month pill for the calendar.
  Widget _controls(DayLight light, double g) {
    final shadow = [
      BoxShadow(
        color: const Color(0xFF3A4150).withValues(alpha: 0.10),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: (1 - g * 2).clamp(0, 1),
            child: Text(
              'hold to see the whole month',
              style: figtree(14, FontWeight.w600, light.soft),
            ),
          ),
          Opacity(
            opacity: ((g - 0.5) * 2).clamp(0, 1),
            child: IgnorePointer(
              ignoring: g < 0.5,
              child: Container(
                width: 210,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                  boxShadow: shadow,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 54,
                      child: CustomPaint(
                        size: const Size(54, 54),
                        painter: _Chevron(light.ink, AxisDirection.left),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              monthName(_month.month).substring(0, 3),
                              style: figtree(17, FontWeight.w700, light.ink),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CustomPaint(
                                painter: _Chevron(
                                  light.ink,
                                  AxisDirection.down,
                                  size: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 54,
                      child: CustomPaint(
                        size: const Size(54, 54),
                        painter: _Chevron(light.ink, AxisDirection.right),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
  const _DayPrint({
    required this.printed,
    required this.month,
    required this.g,
    required this.light,
    this.caption = 1,
  });
  final double caption;
  final PrintedDay printed;
  final int month;
  final double g;
  final DayLight light;
  @override
  Widget build(BuildContext context) {
    final prints = printed.prints;
    final caption = (1 - g * 2.5).clamp(0.0, 1.0) * this.caption;
    final radius = 22 - 12 * g;
    return Container(
      padding: EdgeInsets.fromLTRB(
        11 * (1 - g),
        11 * (1 - g),
        11 * (1 - g),
        76 * (1 - g),
      ),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, Colors.transparent, g),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A4150).withValues(alpha: 0.16 * (1 - g)),
            blurRadius: 26 - 20 * g,
            offset: Offset(0, 12 - 10 * g),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius - 6 * (1 - g)),
            child: Image(image: printed.photo, fit: BoxFit.cover),
          ),
          if (caption > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: -64,
              child: Opacity(
                opacity: caption,
                child: Column(
                  children: [
                    Text(
                      '${monthName(month).substring(0, 3)} ${printed.day}',
                      style: figtree(
                        21,
                        FontWeight.w800,
                        const Color(0xFF15171A),
                      ),
                    ),
                    Text(
                      '$prints ${prints == 1 ? 'print' : 'prints'}',
                      style: figtree(
                        15,
                        FontWeight.w400,
                        const Color(0xFF6B7079),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
      AxisDirection.left =>
        Path()
          ..moveTo(o.dx + h * 0.5, o.dy - h)
          ..lineTo(o.dx - h * 0.5, o.dy)
          ..lineTo(o.dx + h * 0.5, o.dy + h),
      AxisDirection.right =>
        Path()
          ..moveTo(o.dx - h * 0.5, o.dy - h)
          ..lineTo(o.dx + h * 0.5, o.dy)
          ..lineTo(o.dx - h * 0.5, o.dy + h),
      AxisDirection.down =>
        Path()
          ..moveTo(o.dx - h, o.dy - h * 0.4)
          ..lineTo(o.dx, o.dy + h * 0.5)
          ..lineTo(o.dx + h, o.dy - h * 0.4),
      AxisDirection.up =>
        Path()
          ..moveTo(o.dx - h, o.dy + h * 0.4)
          ..lineTo(o.dx, o.dy - h * 0.5)
          ..lineTo(o.dx + h, o.dy + h * 0.4),
    };
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = c,
    );
  }

  @override
  bool shouldRepaint(_Chevron old) => old.c != c || old.dir != dir;
}

/// A small sliding switch between the flipbook and the calendar: two drawn
/// icons on a soft track, the selected one on a raised square. Its thumb
/// follows the transition itself, so it slides in step with the cards.
class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({
    required this.value,
    required this.light,
    required this.onSelect,
  });
  final double value; // 0 = flipbook, 1 = calendar
  final DayLight light;
  final ValueChanged<bool> onSelect;

  static const _seg = 34.0;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOut.transform(value.clamp(0.0, 1.0));
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE1E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: _seg * 2,
        height: _seg,
        child: Stack(
          children: [
            Positioned(
              left: _seg * t,
              top: 0,
              width: _seg,
              height: _seg,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3A4150).withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
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
                            color: Color.lerp(
                              light.soft,
                              light.ink,
                              i == 1 ? t : 1 - t,
                            )!,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
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
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 12, height: 15),
          const Radius.circular(2.5),
        ),
        stroke,
      );
      canvas.restore();
      final front = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(-2, 1.5), width: 12, height: 15),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(front, stroke);
      canvas.drawRect(
        Rect.fromLTWH(
          front.left + 2.6,
          front.top + 2.6,
          front.width - 5.2,
          front.height * 0.5,
        ),
        Paint()..color = color,
      );
    } else {
      // A three-by-three month grid.
      const cell = 4.2, gap = 2.0;
      final start = c.translate(
        -(cell * 3 + gap * 2) / 2,
        -(cell * 3 + gap * 2) / 2,
      );
      for (var r = 0; r < 3; r++) {
        for (var k = 0; k < 3; k++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                start.dx + k * (cell + gap),
                start.dy + r * (cell + gap),
                cell,
                cell,
              ),
              const Radius.circular(1.2),
            ),
            Paint()..color = color,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ViewIcon old) =>
      old.color != color || old.calendar != calendar;
}
