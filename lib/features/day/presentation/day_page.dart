// Ported exactly from the reference prototype's DayRuler
// (prototypes/day_and_history, docs/design-system.md §18.3), on real
// reminders and prints.
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../app/routes.dart';
import '../../prints/prints_providers.dart';
import '../../reminders/domain/calendar.dart';
import 'day_data.dart';
import 'day_reminder_page.dart';
import 'day_widgets.dart';
import 'history_page.dart';

/// A day's ruler: Today (the home screen, PRD FR-12) or an earlier day
/// opened from History (FR-13).
class DayPage extends ConsumerWidget {
  const DayPage({this.day, super.key});

  /// The day shown; `null` for today.
  final LocalDate? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = nowOf(ref);
    final day = this.day ?? now.date;
    final entries = ref.watch(dayEntriesProvider(day));
    return switch (entries) {
      AsyncData(value: final list) => _DayRuler(
        day: day,
        now: now,
        meds: list,
        marks: ref.watch(dayMarksProvider(day)),
        onToggle: (e) => ref.read(togglePrintProvider)(e.reminder, day),
      ),
      _ => ColoredBox(color: DayLight.screen.page),
    };
  }
}

class _DayRuler extends StatefulWidget {
  const _DayRuler({
    required this.day,
    required this.now,
    required this.meds,
    required this.marks,
    required this.onToggle,
  });
  final LocalDate day;
  final LocalDateTime now;
  final List<DayEntry> meds;
  final Map<String, LocalTime> marks;
  final ValueChanged<DayEntry> onToggle;
  @override
  State<_DayRuler> createState() => _DayRulerState();
}

class _DayRulerState extends State<_DayRuler>
    with SingleTickerProviderStateMixin {
  static const pxPerHour = 64.0;

  List<DayEntry> get meds => widget.meds;
  bool get _isToday => widget.day == widget.now.date;
  double get nowHour => nowHourOn(widget.day, widget.now);
  // Today starts on the next medicine; an earlier day starts on its first.
  late int _index = _start();
  late final AnimationController _hour = AnimationController.unbounded(
    vsync: this,
    value: meds.isEmpty ? nowHour.clamp(0, 23.99) : meds[_index].hour,
  )..addListener(() => setState(() {}));
  bool _dragging = false;
  double _dragDx = 0;

  int _start() {
    if (meds.isEmpty || !_isToday) return 0;
    final next = meds.indexWhere((m) => m.hour >= nowHour);
    return (next == -1 ? meds.length - 1 : next).clamp(0, meds.length - 1);
  }

  @override
  void didUpdateWidget(_DayRuler old) {
    super.didUpdateWidget(old);
    if (meds.isEmpty) return;
    // Stay on the same reminder when the day's list changes around it.
    final id = old.meds.isEmpty
        ? null
        : old.meds[_index.clamp(0, old.meds.length - 1)].reminder.id;
    final kept = meds.indexWhere((m) => m.reminder.id == id);
    _index = kept == -1 ? _start() : kept;
    if (!_hour.isAnimating && !_dragging) _hour.value = meds[_index].hour;
  }

  bool get _settled => !_dragging && !_hour.isAnimating;
  DayEntry get _med => meds[_index];

  void _onDragStart(DragStartDetails d) {
    _hour.stop();
    _dragging = true;
    _dragDx = 0;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (meds.isEmpty) return;
    _dragDx += d.delta.dx;
    var next = _hour.value - d.delta.dx / pxPerHour;
    if (next < meds.first.hour || next > meds.last.hour) {
      next = _hour.value - d.delta.dx / pxPerHour * 0.3;
    }
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
    if (meds.isEmpty) return;
    final target = i.clamp(0, meds.length - 1);
    if (target != _index) HapticFeedback.selectionClick();
    setState(() => _index = target);
    if (MediaQuery.disableAnimationsOf(context)) {
      _hour.value = meds[target].hour;
      return;
    }
    _hour.animateWith(
      SpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 1,
          stiffness: 170,
          ratio: 0.92,
        ),
        _hour.value,
        meds[target].hour,
        velocity,
      ),
    );
  }

  void _open() {
    final e = _med;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, a, b) =>
            DayReminderPage(day: widget.day, reminderId: e.reminder.id),
        transitionsBuilder: (context, a, b, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: a,
                    curve: const Cubic(0.23, 1, 0.32, 1),
                  ),
                ),
            child: child,
          ),
        ),
      ),
    );
  }

  String get _when {
    if (!_isToday) return _weekdays[widget.day.weekday - 1].toLowerCase();
    if (_med.hour < nowHour) return 'earlier today';
    final firstUpcoming = meds.indexWhere((x) => x.hour >= nowHour);
    return _index == firstUpcoming ? 'next' : 'later today';
  }

  String? _takenAt(DayEntry e) {
    final t = widget.marks[e.reminder.id];
    return t == null ? null : clockText(context, t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final light = DayLight.screen;
    final d = widget.day;
    final date =
        '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';
    // The phone's status bar follows the colour of the hour.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: light.page.computeLuminance() < 0.2
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.arrowRight) _go(_index + 1);
          if (e.logicalKey == LogicalKeyboardKey.arrowLeft) _go(_index - 1);
          return KeyEventResult.handled;
        },
        child: Scaffold(
          backgroundColor: light.page,
          body: Stack(
            children: [
              SafeArea(
                // Laid out exactly as the prototype wherever it fits; on a
                // small screen or with large text it scrolls instead of
                // overflowing (§12.1).
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                              child: _isToday
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                date,
                                                style: figtree(
                                                  17,
                                                  FontWeight.w600,
                                                  light.soft,
                                                ),
                                              ),
                                              Text(
                                                _greeting,
                                                style: figtree(
                                                  40,
                                                  FontWeight.w800,
                                                  light.ink,
                                                  letterSpacing: -1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Side by side; with large text they
                                        // wrap instead of overflowing.
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.sizeOf(context)
                                                    .width *
                                                0.5,
                                          ),
                                          child: Wrap(
                                            alignment: WrapAlignment.end,
                                            children: [
                                              MedicinesButton(
                                                light: light,
                                                onTap: () => context.push(
                                                  AppRoutes.medicines,
                                                ),
                                              ),
                                              HistoryButton(
                                                light: light,
                                                onTap: () =>
                                                    Navigator.of(context).push(
                                                      growRoute(
                                                        const HistoryPage(),
                                                      ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: Text(
                                            '‹  ${_months[d.month - 1].toLowerCase()}',
                                            style: figtree(
                                              17,
                                              FontWeight.w700,
                                              light.soft,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          date,
                                          style: figtree(
                                            17,
                                            FontWeight.w600,
                                            light.soft,
                                          ),
                                        ),
                                        Text(
                                          '${d.day} ${_months[d.month - 1].toLowerCase()}.',
                                          style: figtree(
                                            40,
                                            FontWeight.w800,
                                            light.ink,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const Spacer(),
                            if (meds.isEmpty)
                              _empty(light)
                            else
                              ..._ruler(light),
                            const Spacer(),
                            Center(
                              child: meds.isEmpty
                                  ? GestureDetector(
                                      onTap: () =>
                                          context.push(AppRoutes.medicines),
                                      child: Text(
                                        'add a medicine',
                                        style: figtree(
                                          14,
                                          FontWeight.w600,
                                          light.soft,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'swipe the ruler  ·  tap the photo to open',
                                      style: figtree(
                                        14,
                                        FontWeight.w600,
                                        light.soft,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _greeting {
    final h = widget.now.time.hour;
    return h < 12
        ? 'good morning.'
        : h < 17
        ? 'good afternoon.'
        : 'good evening.';
  }

  Widget _empty(DayLight light) => Center(
    child: Text(
      _isToday ? 'nothing for today.' : 'nothing on this day.',
      style: figtree(22, FontWeight.w700, light.ink),
    ),
  );

  List<Widget> _ruler(DayLight light) {
    final m = _med;
    final takenAt = _takenAt(m);
    final markable = canMark(m, widget.day, widget.now);
    return [
      // The medicine under the needle. It cross-fades between medicines.
      Center(
        child: SizedBox(
          child: AnimatedSwitcher(
            // The current photo shrinks into the bottom centre; then the
            // next one grows out of it.
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
              key: ValueKey(m.reminder.id),
              child: Hero(
                tag: 'photo${widget.day}-${m.reminder.id}',
                child: SizedBox(
                  width: 280,
                  height: 210,
                  child: HoldPhoto(
                    image: m.photo,
                    takenAt: takenAt,
                    canMark: markable,
                    onToggle: () => widget.onToggle(m),
                    light: light,
                    onTap: _open,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 28),
      GestureDetector(
        key: const ValueKey('ruler'),
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: SizedBox(
          height: 96,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0, 0.28, 0.72, 1],
            ).createShader(r),
            child: CustomPaint(
              size: Size.infinite,
              painter: RulerPainter(
                _hour.value,
                pxPerHour,
                light.ink,
                light.soft,
                _index,
                [for (final e in meds) e.hour],
                {
                  for (final (i, e) in meds.indexed)
                    if (widget.marks.containsKey(e.reminder.id)) i,
                },
                _isToday ? nowHour : null,
                MediaQuery.textScalerOf(context),
                MediaQuery.alwaysUse24HourFormatOf(context),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: Text(
          _settled
              ? clockText(
                  context,
                  m.reminder.schedule.time.hour,
                  m.reminder.schedule.time.minute,
                )
              : _clock(_hour.value),
          style: figtree(
            56,
            FontWeight.w800,
            light.ink,
            height: 1.05,
            letterSpacing: -2,
          ),
        ),
      ),
      AnimatedOpacity(
        duration: Duration(milliseconds: _settled ? 260 : 90),
        opacity: _settled ? 1 : 0,
        child: AnimatedSlide(
          duration: Duration(milliseconds: _settled ? 260 : 90),
          curve: const Cubic(0.23, 1, 0.32, 1),
          offset: _settled ? Offset.zero : const Offset(0, 0.2),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Text(
                '${m.name}  ·  $_when',
                textAlign: TextAlign.center,
                style: figtree(22, FontWeight.w700, light.ink),
              ),
              Text(
                m.paused ? 'Paused, won’t notify' : m.note,
                textAlign: TextAlign.center,
                style: figtree(18, FontWeight.w500, light.soft),
              ),
              const SizedBox(height: 18),
              TakenNote(takenAt: takenAt, canMark: markable, light: light),
            ],
          ),
        ),
      ),
    ];
  }

  String _clock(double h) {
    final c = h.clamp(0.0, 23.99);
    final hh = c.floor();
    final mm = ((c - hh) * 60).floor();
    return clockText(context, hh, mm);
  }

  @override
  void dispose() {
    _hour.dispose();
    super.dispose();
  }
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String monthName(int month) => _months[month - 1];
