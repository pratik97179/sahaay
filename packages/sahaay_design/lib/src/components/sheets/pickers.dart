import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../foundations/sizing.dart';
import '../../foundations/spacing.dart';
import '../../tokens/sahaay_tokens.dart';
import '../scaled_icon.dart';
import 'picker_sheet.dart';

// The picker sheets (`docs/design-system.md` §11.3, §11.7). Each opens from
// a PickerField and returns the chosen value, or `null` when dismissed. All
// words shown to people (titles, labels, button text, month and weekday
// names) are passed in by the caller, so the design system holds no product
// copy. Every size here comes from the space available and the user's text
// size (§12).

/// A time on a wheel. Follows the device's 12- or 24-hour setting.
Future<TimeOfDay?> showTimeWheelSheet(
  BuildContext context, {
  required String title,
  required String doneLabel,
  required TimeOfDay initial,
}) {
  var chosen = initial;
  return showSahaaySheet<TimeOfDay>(
    context,
    title: title,
    builder: (context) => _WheelWithDone(
      doneLabel: doneLabel,
      onDone: () => Navigator.of(context).pop(chosen),
      wheel: (itemExtent, textStyle) => CupertinoTheme(
        data: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: textStyle),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          itemExtent: itemExtent,
          initialDateTime: DateTime(2000, 1, 1, initial.hour, initial.minute),
          onDateTimeChanged: (d) =>
              chosen = TimeOfDay(hour: d.hour, minute: d.minute),
        ),
      ),
    ),
  );
}

/// One choice from a short list, as rows with a check on the chosen one.
/// Tapping a row chooses it and closes the sheet.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  T? selected,
}) => showSahaaySheet<T>(
  context,
  title: title,
  builder: (context) => _RowGroup(
    children: [
      for (final (value, label) in options)
        _CheckRow(
          label: label,
          checked: value == selected,
          exclusive: true,
          onTap: () => Navigator.of(context).pop(value),
        ),
    ],
  ),
);

/// Several choices from a short list, such as weekdays, as rows that check
/// and uncheck. [doneLabel] confirms; it is disabled while nothing is
/// chosen.
Future<Set<T>?> showMultiChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required String doneLabel,
  required List<(T, String)> options,
  Set<T> selected = const {},
}) => showSahaaySheet<Set<T>>(
  context,
  title: title,
  builder: (context) => _MultiChoice<T>(
    options: options,
    initial: selected,
    doneLabel: doneLabel,
  ),
);

/// Days of the month, any number of them, on a grid with as many columns
/// as fit (seven on most phones). [footnote] explains anything special,
/// such as "31 means the last day of the month".
Future<Set<int>?> showDayOfMonthSheet(
  BuildContext context, {
  required String title,
  required String doneLabel,
  required String footnote,
  Set<int> selected = const {},
}) => showSahaaySheet<Set<int>>(
  context,
  title: title,
  builder: (context) =>
      _DayGrid(initial: selected, doneLabel: doneLabel, footnote: footnote),
);

/// What a calendar sheet returns: a date, or no date when the caller
/// offered [showCalendarSheet]'s `noDateLabel` and it was chosen.
final class DateChoice {
  const DateChoice(this.date);

  final DateTime? date;
}

/// A date on a month calendar, with the chosen date written out in full at
/// the top. Offer [noDateLabel] (such as "No end date") to let people
/// choose no date at all.
///
/// [weekdayLabels] are seven short names starting from [firstWeekday]
/// (1 = Monday … 7 = Sunday). [describe] writes a date out in full;
/// [describeMonth] names a month and year. The navigation labels are read
/// by screen readers.
Future<DateChoice?> showCalendarSheet(
  BuildContext context, {
  required String title,
  required String doneLabel,
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
  required String Function(DateTime) describe,
  required String Function(DateTime) describeMonth,
  required List<String> weekdayLabels,
  required String previousMonthLabel,
  required String nextMonthLabel,
  int firstWeekday = DateTime.monday,
  String? noDateLabel,
}) => showSahaaySheet<DateChoice>(
  context,
  title: title,
  builder: (context) => _Calendar(
    initial: _dateOnly(initial),
    firstDate: _dateOnly(firstDate),
    lastDate: _dateOnly(lastDate),
    describe: describe,
    describeMonth: describeMonth,
    weekdayLabels: weekdayLabels,
    firstWeekday: firstWeekday,
    previousMonthLabel: previousMonthLabel,
    nextMonthLabel: nextMonthLabel,
    doneLabel: doneLabel,
    noDateLabel: noDateLabel,
  ),
);

/// A month and a day on two wheels, for yearly reminders. February offers
/// the 29th. [monthNames] has twelve entries, January first.
Future<({int month, int day})?> showMonthDaySheet(
  BuildContext context, {
  required String title,
  required String doneLabel,
  required List<String> monthNames,
  required int month,
  required int day,
  String? footnote,
}) => showSahaaySheet<({int month, int day})>(
  context,
  title: title,
  builder: (context) => _MonthDay(
    monthNames: monthNames,
    month: month,
    day: day,
    doneLabel: doneLabel,
    footnote: footnote,
  ),
);

/// Days in each month, allowing 29 February.
const _daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The smallest square cell that holds [style]'s two-digit numbers at the
/// user's text size, and is never below the touch target.
double _minCell(BuildContext context, TextStyle style) {
  final scaled = MediaQuery.textScalerOf(context).scale(style.fontSize!);
  final forText = scaled * 1.6 + Spacing.underLabel * 2;
  return forText < Sizing.minTouchTarget ? Sizing.minTouchTarget : forText;
}

class _WheelWithDone extends StatelessWidget {
  const _WheelWithDone({
    required this.wheel,
    required this.doneLabel,
    required this.onDone,
  });

  final Widget Function(double itemExtent, TextStyle textStyle) wheel;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final style = t.field.value;
    // Rows grow with the user's text size, and the wheel shows as many as
    // fit in its share of the screen — fewer in landscape or at large text.
    final itemExtent =
        MediaQuery.textScalerOf(context)
            .scale(style.fontSize! * style.height!) +
        Spacing.besideIcon;
    final room = MediaQuery.sizeOf(context).height * Sizing.wheelScreenShare;
    final rows = (room / itemExtent).floor().clamp(
      Sizing.minWheelRows,
      Sizing.maxWheelRows,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: itemExtent * rows, child: wheel(itemExtent, style)),
        SizedBox(height: t.field.gap),
        FilledButton(onPressed: onDone, child: Text(doneLabel)),
      ],
    );
  }
}

class _RowGroup extends StatelessWidget {
  const _RowGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final r = context.sahaay.card;
    return ClipPath(
      clipper: ShapeBorderClipper(shape: r.shape),
      child: ColoredBox(
        color: r.background,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.checked,
    required this.exclusive,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final bool exclusive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final style = checked
        ? t.row.label.copyWith(
            fontWeight: FontWeight.w700,
            fontVariations: [FontVariation.weight(700)],
          )
        : t.row.label;
    return Semantics(
      button: true,
      selected: checked,
      checked: exclusive ? null : checked,
      inMutuallyExclusiveGroup: exclusive,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: t.row.minHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.card.padding.left,
              vertical: Spacing.besideIcon,
            ),
            child: Row(
              children: [
                Expanded(child: Text(label, style: style)),
                const SizedBox(width: Spacing.besideIcon),
                ScaledIcon(
                  Icons.check,
                  besideText: style,
                  color: checked ? t.focus.ring : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiChoice<T> extends StatefulWidget {
  const _MultiChoice({
    required this.options,
    required this.initial,
    required this.doneLabel,
  });

  final List<(T, String)> options;
  final Set<T> initial;
  final String doneLabel;

  @override
  State<_MultiChoice<T>> createState() => _MultiChoiceState<T>();
}

class _MultiChoiceState<T> extends State<_MultiChoice<T>> {
  late final Set<T> _chosen = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RowGroup(
          children: [
            for (final (value, label) in widget.options)
              _CheckRow(
                label: label,
                checked: _chosen.contains(value),
                exclusive: false,
                onTap: () => setState(
                  () => _chosen.contains(value)
                      ? _chosen.remove(value)
                      : _chosen.add(value),
                ),
              ),
          ],
        ),
        SizedBox(height: t.field.gap),
        FilledButton(
          onPressed: _chosen.isEmpty
              ? null
              : () => Navigator.of(context).pop({..._chosen}),
          child: Text(widget.doneLabel),
        ),
      ],
    );
  }
}

class _DayGrid extends StatefulWidget {
  const _DayGrid({
    required this.initial,
    required this.doneLabel,
    required this.footnote,
  });

  final Set<int> initial;
  final String doneLabel;
  final String footnote;

  @override
  State<_DayGrid> createState() => _DayGridState();
}

class _DayGridState extends State<_DayGrid> {
  late final Set<int> _chosen = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    const gap = Spacing.underLabel;
    final minCell = _minCell(context, t.row.label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Days of the month are not tied to weekdays, so the grid takes
            // as many columns as fit — up to seven — and cells never shrink
            // below what their numbers need.
            final width = constraints.maxWidth;
            final columns = ((width + gap) / (minCell + gap)).floor().clamp(
              1,
              7,
            );
            final cell = (width - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var day = 1; day <= 31; day++)
                  SizedBox.square(
                    dimension: cell,
                    child: _DayCell(
                      label: '$day',
                      semanticLabel: '$day',
                      chosen: _chosen.contains(day),
                      onTap: () => setState(
                        () => _chosen.contains(day)
                            ? _chosen.remove(day)
                            : _chosen.add(day),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: t.field.labelGap * 2),
        Text(widget.footnote, style: t.switchRow.stateNote),
        SizedBox(height: t.field.gap),
        FilledButton(
          onPressed: _chosen.isEmpty
              ? null
              : () => Navigator.of(context).pop({..._chosen}),
          child: Text(widget.doneLabel),
        ),
      ],
    );
  }
}

/// A round day cell: sage when chosen, card colour otherwise, quiet when
/// it can't be chosen. Its number keeps the user's text size; the cell is
/// sized to hold it.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.semanticLabel,
    required this.chosen,
    required this.onTap,
    this.marked = false,
  });

  final String label;
  final String semanticLabel;
  final bool chosen;

  /// `null` when the day can't be chosen.
  final VoidCallback? onTap;

  /// Outlines the cell, such as for today.
  final bool marked;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final enabled = onTap != null;
    final style = chosen
        ? t.button.label
        : enabled
        ? t.row.label
        : t.button.disabledLabel;
    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: chosen,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: chosen ? t.button.background : t.card.background,
        shape: CircleBorder(
          side: marked && !chosen
              ? BorderSide(color: t.focus.ring, width: t.focus.width / 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(child: Text(label, style: style, maxLines: 1)),
        ),
      ),
    );
  }
}

class _Calendar extends StatefulWidget {
  const _Calendar({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
    required this.describe,
    required this.describeMonth,
    required this.weekdayLabels,
    required this.firstWeekday,
    required this.previousMonthLabel,
    required this.nextMonthLabel,
    required this.doneLabel,
    required this.noDateLabel,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final String Function(DateTime) describe;
  final String Function(DateTime) describeMonth;
  final List<String> weekdayLabels;
  final int firstWeekday;
  final String previousMonthLabel;
  final String nextMonthLabel;
  final String doneLabel;
  final String? noDateLabel;

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  late DateTime _date = widget.initial;
  late DateTime _month = DateTime(widget.initial.year, widget.initial.month);

  bool get _canGoBack =>
      _month.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
  bool get _canGoForward =>
      _month.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  void _moveMonth(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final noDate = widget.noDateLabel;
    final heading = t.takePanel.instruction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(widget.describe(_date), style: heading),
        ),
        SizedBox(height: t.field.gap),
        Row(
          children: [
            IconButton(
              onPressed: _canGoBack ? () => _moveMonth(-1) : null,
              tooltip: widget.previousMonthLabel,
              icon: ScaledIcon(Icons.chevron_left, besideText: t.row.label),
            ),
            Expanded(
              child: Text(
                widget.describeMonth(_month),
                style: t.row.label,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: _canGoForward ? () => _moveMonth(1) : null,
              tooltip: widget.nextMonthLabel,
              icon: ScaledIcon(Icons.chevron_right, besideText: t.row.label),
            ),
          ],
        ),
        SizedBox(height: t.field.labelGap),
        _MonthGrid(
          month: _month,
          chosen: _date,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          firstWeekday: widget.firstWeekday,
          weekdayLabels: widget.weekdayLabels,
          describe: widget.describe,
          onChoose: (date) => setState(() => _date = date),
        ),
        SizedBox(height: t.field.gap),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(DateChoice(_date)),
          child: Text(widget.doneLabel),
        ),
        if (noDate != null) ...[
          SizedBox(height: t.field.labelGap),
          TextButton(
            onPressed: () => Navigator.of(context).pop(const DateChoice(null)),
            child: Text(noDate, textAlign: TextAlign.center),
          ),
        ],
      ],
    );
  }
}

/// One month as seven equal, flexible columns. Weekdays must line up, so
/// the column count is fixed; each cell is a square as wide as its column
/// and its number is limited to what that column holds, so nothing clips.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.chosen,
    required this.firstDate,
    required this.lastDate,
    required this.firstWeekday,
    required this.weekdayLabels,
    required this.describe,
    required this.onChoose,
  });

  final DateTime month;
  final DateTime chosen;
  final DateTime firstDate;
  final DateTime lastDate;
  final int firstWeekday;
  final List<String> weekdayLabels;
  final String Function(DateTime) describe;
  final ValueChanged<DateTime> onChoose;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final leading =
        (DateTime(month.year, month.month).weekday - firstWeekday + 7) % 7;
    final today = DateUtils.dateOnly(DateTime.now());
    final slots = <DateTime?>[
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
    ];
    while (slots.length % 7 != 0) {
      slots.add(null);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = Spacing.betweenRows * 2;
        final cell = (constraints.maxWidth - gap * 6) / 7;
        // Day numbers keep the user's text size until the column is full.
        final style = t.row.label;
        final fits = (cell - Spacing.underLabel) / (style.fontSize! * 1.6);
        final scaler = MediaQuery.textScalerOf(context)
            .clamp(maxScaleFactor: fits < 1 ? 1 : fits);
        Widget row(List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: gap),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: children[i]),
              ],
            ],
          ),
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: Column(
            children: [
              row([
                for (final label in weekdayLabels)
                  ExcludeSemantics(
                    child: Text(
                      label,
                      style: t.field.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
              ]),
              for (var week = 0; week < slots.length; week += 7)
                row([
                  for (final date in slots.sublist(week, week + 7))
                    if (date == null)
                      const SizedBox()
                    else
                      AspectRatio(
                        aspectRatio: 1,
                        child: _DayCell(
                          label: '${date.day}',
                          semanticLabel: describe(date),
                          chosen: DateUtils.isSameDay(date, chosen),
                          marked: DateUtils.isSameDay(date, today),
                          onTap:
                              date.isBefore(firstDate) || date.isAfter(lastDate)
                              ? null
                              : () => onChoose(date),
                        ),
                      ),
                ]),
            ],
          ),
        );
      },
    );
  }
}

class _MonthDay extends StatefulWidget {
  const _MonthDay({
    required this.monthNames,
    required this.month,
    required this.day,
    required this.doneLabel,
    required this.footnote,
  });

  final List<String> monthNames;
  final int month;
  final int day;
  final String doneLabel;
  final String? footnote;

  @override
  State<_MonthDay> createState() => _MonthDayState();
}

class _MonthDayState extends State<_MonthDay> {
  late int _month = widget.month;
  late int _day = widget.day;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final footnote = widget.footnote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WheelWithDone(
          doneLabel: widget.doneLabel,
          onDone: () => Navigator.of(context).pop((month: _month, day: _day)),
          wheel: (itemExtent, style) => Row(
            children: [
              Expanded(
                flex: 3,
                child: CupertinoPicker(
                  itemExtent: itemExtent,
                  scrollController: FixedExtentScrollController(
                    initialItem: _month - 1,
                  ),
                  onSelectedItemChanged: (i) => setState(() {
                    _month = i + 1;
                    _day = _day.clamp(1, _daysInMonth[i]);
                  }),
                  children: [
                    for (final name in widget.monthNames)
                      Center(
                        child: Text(
                          name,
                          style: style,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: CupertinoPicker(
                  key: ValueKey(_month),
                  itemExtent: itemExtent,
                  scrollController: FixedExtentScrollController(
                    initialItem: _day - 1,
                  ),
                  onSelectedItemChanged: (i) => _day = i + 1,
                  children: [
                    for (var d = 1; d <= _daysInMonth[_month - 1]; d++)
                      Center(child: Text('$d', style: style)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (footnote != null) ...[
          SizedBox(height: t.field.labelGap),
          Text(footnote, style: t.switchRow.stateNote),
        ],
      ],
    );
  }
}
