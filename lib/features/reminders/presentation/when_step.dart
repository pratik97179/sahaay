import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../application/reminder_draft.dart';
import '../domain/calendar.dart';
import 'reminder_marks.dart';
import 'schedule_text.dart';

/// What the "when?" step holds: one schedule, its amount and note, and the
/// times of day it reminds at. Each time becomes its own reminder when the
/// medicine is saved, so they can be changed one by one later.
///
/// Nothing counts until a time has been set.
final class WhenDraft {
  const WhenDraft({required this.draft, this.extraTimes = const []});
  final ReminderDraft draft;
  final List<LocalTime> extraTimes;

  List<LocalTime> get times => [?draft.time, ...extraTimes];

  WhenDraft copyWith({ReminderDraft? draft, List<LocalTime>? extraTimes}) =>
      WhenDraft(
        draft: draft ?? this.draft,
        extraTimes: extraTimes ?? this.extraTimes,
      );

  /// Every reminder this makes: one per time.
  List<ReminderDetails> toDetails(LocalDateTime now) => [
    for (final t in times) ?draft.copyWith(time: t).toDetails(now),
  ];
}

/// The "when?" step: the whole reminder on one screen (docs/design-system.md
/// §18.3). The time on a ruler like Today's; how often in a few words; the
/// amount and a pinned note side by side.
class WhenStep extends StatefulWidget {
  const WhenStep({required this.current, required this.enabled, super.key});

  final ValueNotifier<WhenDraft> current;
  final bool enabled;

  @override
  State<WhenStep> createState() => _WhenStepState();
}

class _WhenStepState extends State<WhenStep> {
  int _selected = 0; // which time the ruler moves

  WhenDraft get _w => widget.current.value;
  ReminderDraft get _d => _w.draft;
  void _set(ReminderDraft d) => widget.current.value = _w.copyWith(draft: d);

  void _setTime(LocalTime t) {
    if (_selected == 0 || _w.extraTimes.isEmpty) {
      _set(_d.copyWith(time: t));
    } else {
      final extra = [..._w.extraTimes]..[_selected - 1] = t;
      widget.current.value = _w.copyWith(extraTimes: extra);
    }
  }

  /// A further time of day: a few hours after the last, to be moved.
  void _addTime() {
    final times = _w.times;
    final last = times.last;
    final next = LocalTime((last.hour + 4) % 24, last.minute);
    widget.current.value = _w.copyWith(extraTimes: [..._w.extraTimes, next]);
    setState(() => _selected = times.length);
  }

  void _removeTime(int i) {
    final times = [..._w.times]..removeAt(i);
    widget.current.value = WhenDraft(
      draft: _d.copyWith(time: times.first),
      extraTimes: times.skip(1).toList(),
    );
    setState(() => _selected = math.max(0, i - 1));
  }

  @override
  Widget build(BuildContext context) {
    final light = DayLight.screen;
    return ValueListenableBuilder(
      valueListenable: widget.current,
      builder: (context, w, _) {
        final times = w.times;
        final sel = math.min(_selected, math.max(0, times.length - 1));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TimeRow(
              times: times,
              selected: sel,
              light: light,
              onSelect: (i) => setState(() => _selected = i),
              onRemove: widget.enabled && times.length > 1 ? _removeTime : null,
              onAdd: widget.enabled && times.isNotEmpty ? _addTime : null,
            ),
            const SizedBox(height: 12),
            _TimeRuler(
              time: times.isEmpty ? null : times[sel],
              others: [
                for (final (i, t) in times.indexed)
                  if (i != sel) t,
              ],
              light: light,
              onChanged: widget.enabled ? _setTime : null,
            ),
            const SizedBox(height: 12),
            _repeat(context, light),
            const SizedBox(height: 38),
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(20) + 136,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _AmountCard(
                      value: _d.quantity,
                      onChanged: widget.enabled
                          ? (q) => _set(_d.copyWith(quantity: q))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: _StickyNote(
                      text: _d.instruction,
                      onChanged: widget.enabled
                          ? (n) => _set(_d.copyWith(instruction: n))
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _repeat(BuildContext context, DayLight light) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Words<RepeatType>(
        options: const {
          RepeatType.once: 'once',
          RepeatType.daily: 'daily',
          RepeatType.weekly: 'weekly',
          RepeatType.monthly: 'monthly',
          RepeatType.yearly: 'yearly',
        },
        value: _d.repeat,
        light: light,
        onChanged: (r) => _set(
          _d.copyWith(
            repeat: r,
            yearlyMonth: _d.yearlyMonth ?? _d.startDate.month,
            yearlyDay: () => _d.yearlyDay ?? _d.startDate.day,
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: _optionHeight(context),
        child: Center(
          child: switch (_d.repeat) {
            RepeatType.weekly => _Weekdays(
              value: _d.weekdays,
              light: light,
              onChanged: (w) => _set(_d.copyWith(weekdays: w)),
            ),
            RepeatType.monthly => _MonthDays(
              value: _d.monthDays,
              light: light,
              onChanged: (m) => _set(_d.copyWith(monthDays: m)),
            ),
            RepeatType.daily => _DailyPreview(
              interval: _d.interval ?? 1,
              start: _d.startDate,
              light: light,
              onChanged: (n) => _set(_d.copyWith(interval: () => n)),
            ),
            RepeatType.once => _Context(
              'on ${formatDate(context, _d.startDate).toLowerCase()}',
              light,
            ),
            RepeatType.yearly => _YearlyDate(
              month: _d.yearlyMonth ?? _d.startDate.month,
              day: _d.yearlyDay ?? _d.startDate.day,
              light: light,
              onChanged: (m, d) =>
                  _set(_d.copyWith(yearlyMonth: m, yearlyDay: () => d)),
            ),
          },
        ),
      ),
    ],
  );
}

class _Context extends StatelessWidget {
  const _Context(this.text, this.light);
  final String text;
  final DayLight light;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: figtree(18, FontWeight.w600, light.soft));
}

/// The times of day as pills, the one on the ruler inked; a drawn clock
/// with a plus adds another time of day.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.times,
    required this.selected,
    required this.light,
    required this.onSelect,
    required this.onRemove,
    required this.onAdd,
  });
  final List<LocalTime> times;
  final int selected;
  final DayLight light;
  final ValueChanged<int> onSelect;
  final ValueChanged<int>? onRemove;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: times.isEmpty
            ? Text(
                'slide the ruler to set a time',
                style: figtree(20, FontWeight.w800, light.soft),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (i, t) in times.indexed)
                    _TimePill(
                      text: clockText(context, t.hour, t.minute),
                      selected: i == selected,
                      light: light,
                      onTap: () => onSelect(i),
                      onRemove: onRemove == null ? null : () => onRemove!(i),
                    ),
                ],
              ),
      ),
      AnimatedOpacity(
        opacity: onAdd == null ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Semantics(
          button: true,
          label: 'Add another time of day',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SizedBox.square(
                dimension: 48,
                child: CustomPaint(painter: AddTimeStamp(light.ink)),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/// A time of day as a pill. The selected one is inked and, when there is
/// more than one, carries a small cross to take it away.
class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.text,
    required this.selected,
    required this.light,
    required this.onTap,
    required this.onRemove,
  });
  final String text;
  final bool selected;
  final DayLight light;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? light.page : light.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: text,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: ShapeDecoration(
            color: selected ? light.ink : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected ? light.ink : light.soft.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(text, style: figtree(20, FontWeight.w800, fg)),
              ),
              if (selected && onRemove != null)
                Semantics(
                  button: true,
                  label: 'Remove $text',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRemove,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: SizedBox.square(
                        dimension: 12,
                        child: CustomPaint(painter: _Cross(fg)),
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
}

class _Cross extends CustomPainter {
  _Cross(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawLine(Offset.zero, Offset(s.width, s.height), p);
    canvas.drawLine(Offset(s.width, 0), Offset(0, s.height), p);
  }

  @override
  bool shouldRepaint(_Cross old) => old.color != color;
}

/// One choice among a few words: the chosen one in ink with a dot under it.
class _Words<T> extends StatelessWidget {
  const _Words({
    required this.options,
    required this.value,
    required this.light,
    required this.onChanged,
  });
  final Map<T, String> options;
  final T value;
  final DayLight light;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 18,
    alignment: WrapAlignment.center,
    children: [
      for (final MapEntry(:key, value: label) in options.entries)
        Semantics(
          button: true,
          selected: key == value,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  // An invisible bold copy holds each word's width, so
                  // choosing a word never nudges the others along.
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ExcludeSemantics(
                        child: Opacity(
                          opacity: 0,
                          child: Text(
                            label,
                            style: figtree(18, FontWeight.w800, light.ink),
                          ),
                        ),
                      ),
                      Text(
                        label,
                        style: figtree(
                          18,
                          key == value ? FontWeight.w800 : FontWeight.w600,
                          key == value ? light.ink : light.soft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: key == value ? light.ink : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// The week's days on a soft track. Chosen days fill in ink, and days
/// chosen side by side join into one run, so "Mon to Fri" reads as one bar.
class _Weekdays extends StatelessWidget {
  const _Weekdays({
    required this.value,
    required this.light,
    required this.onChanged,
  });
  final Set<int> value;
  final DayLight light;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) => _DayTrack(
    days: [
      for (var d = 1; d <= 7; d++) (d, 'MTWTFSS'[d - 1], weekdayNames[d - 1]),
    ],
    value: value,
    light: light,
    onChanged: onChanged,
  );
}

/// The month's dates on the same track, sliding sideways.
class _MonthDays extends StatelessWidget {
  const _MonthDays({
    required this.value,
    required this.light,
    required this.onChanged,
  });
  final Set<int> value;
  final DayLight light;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) => _Sliding(
    child: _DayTrack(
      days: [for (var d = 1; d <= 31; d++) (d, '$d', ordinal(d))],
      value: value,
      light: light,
      onChanged: onChanged,
      cellWidth: MediaQuery.textScalerOf(context).scale(16) + 26,
    ),
  );
}

/// Days as cells on one soft rounded track. A chosen cell fills in ink;
/// neighbouring chosen cells lose their inner corners and join up.
class _DayTrack extends StatelessWidget {
  const _DayTrack({
    required this.days,
    required this.value,
    required this.light,
    required this.onChanged,
    this.cellWidth,
  });

  /// Each day: its value, what the cell shows, and its spoken name.
  final List<(int, String, String)> days;
  final Set<int> value;
  final DayLight light;
  final ValueChanged<Set<int>> onChanged;

  /// A fixed cell width for a track that scrolls; otherwise cells share
  /// the width.
  final double? cellWidth;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.textScalerOf(context).scale(16) + 28;
    const r = Radius.circular(14);
    final cells = [
      for (final (i, (day, text, label)) in days.indexed)
        () {
          final on = value.contains(day);
          final joinLeft = on && i > 0 && value.contains(days[i - 1].$1);
          final joinRight =
              on && i < days.length - 1 && value.contains(days[i + 1].$1);
          final cell = Semantics(
            button: true,
            selected: on,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  onChanged(on ? ({...value}..remove(day)) : {...value, day}),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? light.ink : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: joinLeft ? Radius.zero : r,
                    right: joinRight ? Radius.zero : r,
                  ),
                ),
                child: Text(
                  text,
                  maxLines: 1,
                  style: figtree(
                    16,
                    on ? FontWeight.w800 : FontWeight.w600,
                    on ? light.page : light.soft,
                  ),
                ),
              ),
            ),
          );
          final w = cellWidth;
          return w == null
              ? Expanded(child: cell)
              : SizedBox(width: w, child: cell);
        }(),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: light.soft.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(r),
      ),
      child: Row(
        mainAxisSize: cellWidth == null ? MainAxisSize.max : MainAxisSize.min,
        children: cells,
      ),
    );
  }
}

/// The height every "how often" option takes, the same as the day track's,
/// so switching between them moves nothing on the screen.
double _optionHeight(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(16) + 28;

/// Daily: "every ⊖ 2 ⊕ days", centred, with drawn round steppers.
class _DailyPreview extends StatelessWidget {
  const _DailyPreview({
    required this.interval,
    required this.start,
    required this.light,
    required this.onChanged,
  });
  final int interval;
  final LocalDate start;
  final DayLight light;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget step(bool plus) {
      final to = interval + (plus ? 1 : -1);
      final enabled = to >= 1 && to <= 30;
      return Semantics(
        button: true,
        label: plus ? 'More days apart' : 'Fewer days apart',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged(to) : null,
          child: SizedBox.square(
            dimension: 44,
            child: CustomPaint(
              painter: _Stepper(
                plus: plus,
                color: enabled ? light.ink : light.soft.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Days apart',
      value: interval == 1 ? 'Every day' : 'Every $interval days',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('every', style: figtree(18, FontWeight.w600, light.soft)),
          const SizedBox(width: 8),
          step(false),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.textScalerOf(context).scale(24) * 1.4,
            ),
            child: Text(
              '$interval',
              textAlign: TextAlign.center,
              style: figtree(24, FontWeight.w800, light.ink),
            ),
          ),
          step(true),
          const SizedBox(width: 8),
          SizedBox(
            width: MediaQuery.textScalerOf(context).scale(18) * 2.6,
            child: Text(
              interval == 1 ? 'day' : 'days',
              style: figtree(18, FontWeight.w600, light.soft),
            ),
          ),
        ],
      ),
    );
  }
}

/// A round drawn stepper: a circle with a minus or a plus.
class _Stepper extends CustomPainter {
  _Stepper({required this.plus, required this.color});
  final bool plus;
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.32;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(c, r, p);
    canvas.drawLine(c.translate(-r * 0.45, 0), c.translate(r * 0.45, 0), p);
    if (plus) {
      canvas.drawLine(c.translate(0, -r * 0.45), c.translate(0, r * 0.45), p);
    }
  }

  @override
  bool shouldRepaint(_Stepper old) => old.plus != plus || old.color != color;
}

/// Yearly: two sideways dials, the date and the month, each turning under
/// a fixed notch like a camera's dial.
class _YearlyDate extends StatelessWidget {
  const _YearlyDate({
    required this.month,
    required this.day,
    required this.light,
    required this.onChanged,
  });
  final int month;
  final int day;
  final DayLight light;
  final void Function(int month, int day) onChanged;

  /// Days in a month; February counts 29, since a yearly date may be the
  /// 29th (PRD FR-03 moves it to the 28th in other years).
  static int _daysIn(int m) => switch (m) {
    2 => 29,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Date each year',
    value: '$day ${monthNames[month - 1]}',
    child: Row(
      children: [
        Expanded(
          child: _SideDial(
            light: light,
            child: _Dial(
              horizontal: true,
              items: [for (var d = 1; d <= _daysIn(month); d++) '$d'],
              index: day - 1,
              size: 18,
              color: light.ink,
              onChanged: (i) => onChanged(month, i + 1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SideDial(
            light: light,
            child: _Dial(
              horizontal: true,
              items: [
                for (final m in monthNames) m.substring(0, 3).toLowerCase(),
              ],
              index: month - 1,
              size: 18,
              color: light.ink,
              onChanged: (i) => onChanged(i + 1, math.min(day, _daysIn(i + 1))),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The soft track a sideways dial turns in, with a small notch at the
/// bottom centre marking the chosen value, and faded ends.
class _SideDial extends StatelessWidget {
  const _SideDial({required this.light, required this.child});
  final DayLight light;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: _optionHeight(context),
    decoration: BoxDecoration(
      color: light.soft.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [
                Color(0x00FFFFFF),
                Colors.white,
                Colors.white,
                Color(0x00FFFFFF),
              ],
              stops: [0, 0.3, 0.7, 1],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: child,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 14,
            height: 4,
            decoration: BoxDecoration(
              color: light.ink,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// A turning dial of a few values, like a combination lock. Values above and
/// below the chosen one fade away.
class _Dial extends StatefulWidget {
  const _Dial({
    required this.items,
    required this.index,
    required this.size,
    required this.color,
    required this.onChanged,
    this.horizontal = false,
  });
  final List<String> items;
  final int index;
  final double size;
  final Color color;
  final ValueChanged<int>? onChanged;

  /// Turns sideways, like a camera's dial, instead of up and down.
  final bool horizontal;

  @override
  State<_Dial> createState() => _DialState();
}

class _DialState extends State<_Dial> {
  late final _c = FixedExtentScrollController(initialItem: widget.index);

  @override
  void didUpdateWidget(_Dial old) {
    super.didUpdateWidget(old);
    // Follow a value changed from outside, such as a date clamped when the
    // month changes.
    if (_c.hasClients && _c.selectedItem != widget.index) {
      _c.jumpToItem(widget.index);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(widget.size);
    final wheel = ListWheelScrollView.useDelegate(
      controller: _c,
      itemExtent: widget.horizontal ? scaled * 2.6 : scaled * 1.45,
      diameterRatio: 1.3,
      overAndUnderCenterOpacity: 0.3,
      physics: widget.onChanged == null
          ? const NeverScrollableScrollPhysics()
          : const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) {
        if (i != widget.index) widget.onChanged?.call(i);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.items.length,
        builder: (context, i) {
          final text = Center(
            child: Text(
              widget.items[i],
              maxLines: 1,
              style: figtree(widget.size, FontWeight.w800, widget.color),
            ),
          );
          return widget.horizontal
              ? RotatedBox(quarterTurns: 1, child: text)
              : text;
        },
      ),
    );
    // A sideways dial is an upright wheel turned a quarter.
    return widget.horizontal
        ? RotatedBox(quarterTurns: 3, child: wheel)
        : wheel;
  }
}

/// A sideways track whose far end fades.
class _Sliding extends StatefulWidget {
  const _Sliding({required this.child});
  final Widget child;

  @override
  State<_Sliding> createState() => _SlidingState();
}

class _SlidingState extends State<_Sliding> {
  final _c = ScrollController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (r) => const LinearGradient(
      colors: [Colors.white, Colors.white, Color(0x00FFFFFF)],
      stops: [0, 0.82, 1],
    ).createShader(r),
    blendMode: BlendMode.dstIn,
    child: SingleChildScrollView(
      controller: _c,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    ),
  );
}

// ---- The amount: a small print with two dials. ----

const _paper = Paper.sheet;
const _paperInk = Paper.ink;
const _paperSoft = Paper.soft;

/// How much is taken each time, set on two dials like a combination lock:
/// a number and what it counts. It starts empty; Sahaay never suggests an
/// amount, it only records the one the person sets.
class _AmountCard extends StatefulWidget {
  const _AmountCard({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  State<_AmountCard> createState() => _AmountCardState();
}

class _AmountCardState extends State<_AmountCard> {
  static const _numbers = [
    '–',
    '½',
    '1',
    '1½',
    '2',
    '2½',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '12',
    '15',
    '20',
    '25',
    '30',
    '40',
    '50',
  ];
  static const _units = ['tablet', 'capsule', 'units', 'drops', 'spoon'];
  static const _countable = {'tablet', 'capsule', 'spoon'};

  late int _n;
  late int _u;

  @override
  void initState() {
    super.initState();
    final (n, u) = _parse(widget.value);
    _n = n;
    _u = u;
  }

  static (int, int) _parse(String value) {
    final parts = value.trim().split(' ');
    if (parts.length < 2) return (0, 0);
    final n = _numbers.indexOf(parts.first);
    final unit = parts.sublist(1).join(' ');
    final u = _units.indexWhere((x) => unit == x || unit == '${x}s');
    return (math.max(n, 0), math.max(u, 0));
  }

  void _emit() {
    if (_n == 0) return widget.onChanged?.call('');
    final number = _numbers[_n];
    final unit = _units[_u];
    final plural = number != '1' && number != '½' && _countable.contains(unit);
    widget.onChanged?.call('$number $unit${plural ? 's' : ''}');
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Amount each time',
    value: widget.value.isEmpty ? 'Not set' : widget.value,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
      decoration: BoxDecoration(
        color: _paper,
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
          Text('each time', style: figtree(13, FontWeight.w700, _paperSoft)),
          Expanded(
            child: ClipRect(
              child: Stack(
                children: [
                  // The band the dials read along.
                  Center(
                    child: Container(
                      height: MediaQuery.textScalerOf(context).scale(22) * 1.45,
                      decoration: BoxDecoration(
                        color: _paperInk.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _Dial(
                          items: _numbers,
                          index: _n,
                          size: 22,
                          color: _paperInk,
                          onChanged: widget.onChanged == null
                              ? null
                              : (i) {
                                  setState(() => _n = i);
                                  _emit();
                                },
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: _Dial(
                          items: _units,
                          index: _u,
                          size: 16,
                          color: _n == 0 ? _paperSoft : _paperInk,
                          onChanged: widget.onChanged == null
                              ? null
                              : (i) {
                                  setState(() => _u = i);
                                  _emit();
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---- The note: a sticky note pinned to the page. ----

const _noteYellow = Paper.note;
const _noteInk = Paper.noteInk;

/// A small sticky note, tilted as if pinned up. Tapping lifts it off the
/// page: it flies to the middle, straightens and grows while the page behind
/// blurs and dims; the keyboard comes once it has landed. Closing flies it
/// back to its place.
class _StickyNote extends StatefulWidget {
  const _StickyNote({required this.text, required this.onChanged});
  final String text;
  final ValueChanged<String>? onChanged;

  @override
  State<_StickyNote> createState() => _StickyNoteState();
}

const _pinnedTilt = -0.05;
const _liftedTilt = -0.02;

class _StickyNoteState extends State<_StickyNote> {
  final _tag = Object();

  /// The note's text while it is being written, so the note in flight shows
  /// what is on it.
  late final _live = ValueNotifier(widget.text);

  @override
  void didUpdateWidget(_StickyNote old) {
    super.didUpdateWidget(old);
    _live.value = widget.text;
  }

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final result = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (context, animation, _) =>
            _NoteDialog(tag: _tag, live: _live, animation: animation),
        transitionsBuilder: (context, animation, _, child) => child,
      ),
    );
    if (result != null) widget.onChanged?.call(result.trim());
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.text.trim().isEmpty;
    return Semantics(
      button: true,
      label: empty ? 'Add a note' : 'Note: ${widget.text}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onChanged == null ? null : _open,
        child: Hero(
          tag: _tag,
          flightShuttleBuilder: _noteInFlight(_live),
          child: Transform.rotate(
            angle: _pinnedTilt,
            child: _NotePaper(child: _PinnedText(widget.text)),
          ),
        ),
      ),
    );
  }
}

/// What the pinned note shows: its text, or a few drawn scribble lines.
class _PinnedText extends StatelessWidget {
  const _PinnedText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => text.trim().isEmpty
      ? Center(
          child: SizedBox(
            width: 46,
            height: 30,
            child: CustomPaint(
              painter: _Scribble(_noteInk.withValues(alpha: 0.4)),
            ),
          ),
        )
      : Text(
          text,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: handwritten(19, _noteInk, height: 1.2),
        );
}

/// The note between the page and the middle of the screen: the pinned note
/// fading into the lifted one as it grows, its tilt easing out.
HeroFlightShuttleBuilder _noteInFlight(ValueNotifier<String> live) =>
    (context, animation, direction, from, to) => AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        Widget layout(Size size, Widget note) => FittedBox(
          child: SizedBox.fromSize(size: size, child: note),
        );
        // In flight the note sits in the overlay, outside the page's
        // Material; without one its text gets the debug underline.
        return Material(
          type: MaterialType.transparency,
          child: Transform.rotate(
            angle: _pinnedTilt + (_liftedTilt - _pinnedTilt) * t,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 1 - t,
                  child: layout(
                    const Size.square(160),
                    _NotePaper(child: _PinnedText(live.value)),
                  ),
                ),
                // The lifted note exactly as it lands: same size, text or
                // hint, and tick, so nothing changes once it arrives.
                Opacity(
                  opacity: t,
                  child: layout(
                    _liftedSize(context),
                    _LiftedNote(
                      field: Text(
                        live.value.isEmpty ? _noteHint : live.value,
                        style: live.value.isEmpty ? _hintStyle : _writingStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

/// The note's paper: pale yellow, a strip of tape at the top, and a shadow
/// deeper at the bottom, where it lifts off the page.
class _NotePaper extends StatelessWidget {
  const _NotePaper({required this.child, this.tape = 44});
  final Widget child;
  final double tape;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _noteYellow,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(3, 11),
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
        child: SizedBox.expand(child: child),
      ),
      // The tape holding it up.
      Positioned(
        top: -9,
        left: 0,
        right: 0,
        child: Center(
          child: Transform.rotate(
            angle: 0.06,
            child: Container(
              width: tape,
              height: 18,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    ],
  );
}

/// The note lifted off the page, to write on. Tapping outside it, or its
/// tick, puts it back with what was written.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.tag,
    required this.live,
    required this.animation,
  });
  final Object tag;
  final ValueNotifier<String> live;
  final Animation<double> animation;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _c = TextEditingController(text: widget.live.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _c.addListener(() => widget.live.value = _c.text);
    // The keyboard waits until the note has landed, so the note doesn't
    // jump while it is still flying.
    widget.animation.addStatusListener(_landed);
  }

  void _landed(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) _focus.requestFocus();
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_landed);
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _done() {
    _focus.unfocus();
    Navigator.of(context).pop(_c.text);
  }

  @override
  Widget build(BuildContext context) {
    final size = _liftedSize(context);
    return Material(
      type: MaterialType.transparency,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _done();
        },
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            final t = Curves.easeOut.transform(widget.animation.value);
            return Stack(
              children: [
                // The page behind blurs and dims as the note lifts.
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _done,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12 * t, sigmaY: 12 * t),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.32 * t),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(36, 28, 36, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [child!],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: Hero(
            tag: widget.tag,
            flightShuttleBuilder: _noteInFlight(widget.live),
            child: Transform.rotate(
              angle: _liftedTilt,
              child: SizedBox.fromSize(
                size: size,
                child: _LiftedNote(
                  onDone: _done,
                  field: TextField(
                    controller: _c,
                    focusNode: _focus,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: _noteInk,
                    style: _writingStyle,
                    decoration: InputDecoration(
                      hintText: _noteHint,
                      hintStyle: _hintStyle,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The lifted note's size: one size from start to finish. A little taller
/// than wide, using the room above the keyboard without filling it.
Size _liftedSize(BuildContext context) {
  final screen = MediaQuery.sizeOf(context);
  final width = math.min(screen.width - 56, 360.0);
  final height = math.min(width * 1.2, screen.height * 0.46);
  return Size(width, height);
}

const _noteHint = 'after food, with water…';
final _writingStyle = handwritten(28, _noteInk, height: 1.2);
final _hintStyle = handwritten(
  28,
  _noteInk.withValues(alpha: 0.35),
  height: 1.2,
);

/// The lifted note's face: the paper, what is written (or the field to
/// write in) and the tick in its corner. Drawn the same in flight and once
/// landed.
class _LiftedNote extends StatelessWidget {
  const _LiftedNote({required this.field, this.onDone});
  final Widget field;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _NotePaper(
        tape: 70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The note's own heading, printed small at the top like a notepad's.
            Text(
              'note to self',
              style: rounded(
                16,
                FontWeight.w700,
                _noteInk.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                // Room for the tick, so writing never runs under it.
                padding: const EdgeInsets.only(bottom: 48),
                child: field,
              ),
            ),
          ],
        ),
      ),
      Positioned(
        right: 10,
        bottom: 10,
        child: Semantics(
          button: true,
          label: 'Done',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onDone,
            child: SizedBox.square(
              dimension: 44,
              child: CustomPaint(painter: _InkTick()),
            ),
          ),
        ),
      ),
    ],
  );
}

/// A round ink stamp with a tick, in the note's corner: done.
class _InkTick extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.42;
    canvas.drawCircle(c, r, Paint()..color = _noteInk);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.42, c.dy + r * 0.02)
        ..lineTo(c.dx - r * 0.1, c.dy + r * 0.34)
        ..lineTo(c.dx + r * 0.46, c.dy - r * 0.3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _noteYellow,
    );
  }

  @override
  bool shouldRepaint(_InkTick old) => false;
}

/// Three loose handwritten lines: something can be written here.
class _Scribble extends CustomPainter {
  _Scribble(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final (y, w) in [(0.15, 1.0), (0.5, 0.85), (0.85, 0.55)]) {
      final path = Path()..moveTo(0, s.height * y);
      for (var x = 0.0; x <= s.width * w; x += 2) {
        path.lineTo(x, s.height * y + math.sin(x / 2.6) * 1.8);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_Scribble old) => old.color != color;
}

// ---- The time ruler. ----

/// A day ruler, like Today's, for setting a time: drag it under the fixed
/// needle. The other times show as small dots. Snaps to 5 minutes.
class _TimeRuler extends StatefulWidget {
  const _TimeRuler({
    required this.time,
    required this.others,
    required this.light,
    required this.onChanged,
  });
  final LocalTime? time;
  final List<LocalTime> others;
  final DayLight light;
  final ValueChanged<LocalTime>? onChanged;

  @override
  State<_TimeRuler> createState() => _TimeRulerState();
}

class _TimeRulerState extends State<_TimeRuler> {
  static const _hourPx = 64.0;
  static const _start = 9 * 60.0; // where an unset ruler rests
  double? _dragMinutes;

  double get _minutes =>
      _dragMinutes ?? widget.time?.minutesSinceMidnight.toDouble() ?? _start;

  void _emit(double m) {
    final snapped = ((m / 5).round() * 5) % (24 * 60);
    widget.onChanged?.call(LocalTime(snapped ~/ 60, snapped % 60));
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Time',
    value: widget.time == null
        ? 'Not set'
        : clockText(context, widget.time!.hour, widget.time!.minute),
    increasedValue: 'Later',
    decreasedValue: 'Earlier',
    onIncrease: () => _emit(_minutes + 15),
    onDecrease: () => _emit(_minutes - 15),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => setState(() => _dragMinutes = _minutes),
      onHorizontalDragUpdate: (d) {
        final m = (_dragMinutes! - d.delta.dx / _hourPx * 60) % (24 * 60);
        setState(() => _dragMinutes = m);
        _emit(m);
      },
      onHorizontalDragEnd: (_) => setState(() => _dragMinutes = null),
      onTap: widget.time == null ? () => _emit(_start) : null,
      child: SizedBox(
        height: MediaQuery.textScalerOf(context).scale(16) + 58,
        width: double.infinity,
        child: CustomPaint(
          painter: _TimeRulerPainter(
            minutes: _minutes,
            set: widget.time != null,
            others: [for (final t in widget.others) t.minutesSinceMidnight],
            light: widget.light,
            hourPx: _hourPx,
            scaler: MediaQuery.textScalerOf(context),
            use24: MediaQuery.alwaysUse24HourFormatOf(context),
          ),
        ),
      ),
    ),
  );
}

class _TimeRulerPainter extends CustomPainter {
  _TimeRulerPainter({
    required this.minutes,
    required this.set,
    required this.others,
    required this.light,
    required this.hourPx,
    required this.scaler,
    required this.use24,
  });
  final double minutes;
  final bool set;
  final List<int> others;
  final DayLight light;
  final double hourPx;
  final TextScaler scaler;
  final bool use24;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const base = 44.0;
    double x(double m) {
      // The shortest way round the clock, so the day wraps.
      var d = m - minutes;
      if (d > 720) d -= 1440;
      if (d < -720) d += 1440;
      return cx + d / 60 * hourPx;
    }

    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    for (var q = 0; q < 24 * 4; q++) {
      final m = q * 15.0;
      final px = x(m);
      if (px < -20 || px > size.width + 20) continue;
      final edge = (1 - ((px - cx).abs() / cx)).clamp(0.0, 1.0);
      final hour = q % 4 == 0;
      tick.color = light.soft.withValues(alpha: (hour ? 0.8 : 0.4) * edge);
      canvas.drawLine(
        Offset(px, base),
        Offset(px, base - (hour ? 16 : 8)),
        tick,
      );
      if (hour) {
        final h = q ~/ 4;
        final label = use24
            ? '$h'
            : '${h % 12 == 0 ? 12 : h % 12}${h < 12 ? 'am' : 'pm'}';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: figtree(
              13,
              FontWeight.w700,
              light.soft.withValues(alpha: edge),
            ),
          ),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        tp.paint(canvas, Offset(px - tp.width / 2, base + 6));
      }
    }
    for (final m in others) {
      final px = x(m.toDouble());
      if ((px - cx).abs() < 4) continue;
      canvas.drawCircle(
        Offset(px, base - 26),
        3.5,
        Paint()..color = light.soft,
      );
    }
    canvas.drawLine(
      Offset(cx, base + 2),
      Offset(cx, base - 34),
      Paint()
        ..color = set ? light.ink : light.soft.withValues(alpha: 0.5)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimeRulerPainter old) =>
      old.minutes != minutes ||
      old.set != set ||
      !listEquals(old.others, others) ||
      old.light != light;
}
