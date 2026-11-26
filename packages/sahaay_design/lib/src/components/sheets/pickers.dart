import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../foundations/spacing.dart';
import '../../tokens/sahaay_tokens.dart';
import 'picker_sheet.dart';

// The picker sheets (`docs/design-system.md` §11.7). Each opens from a
// PickerField and returns the chosen value, or `null` when dismissed. All
// words shown to people (titles, labels, button text) are passed in by the
// caller, so the design system stays free of product copy.

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

/// Days of the month on a 7-column grid, any number of them. [footnote]
/// explains anything special, such as "31 means the last day of the
/// month".
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
Future<DateChoice?> showCalendarSheet(
  BuildContext context, {
  required String title,
  required String doneLabel,
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
  required String Function(DateTime) describe,
  String? noDateLabel,
}) => showSahaaySheet<DateChoice>(
  context,
  title: title,
  builder: (context) => _Calendar(
    initial: initial,
    firstDate: firstDate,
    lastDate: lastDate,
    describe: describe,
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
    // Wheel rows grow with the user's text size so large text never clips.
    final scaler = MediaQuery.textScalerOf(context);
    final style = t.field.value;
    final itemExtent = scaler.scale(style.fontSize! * style.height! + 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: itemExtent * 5, child: wheel(itemExtent, style)),
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
                Expanded(
                  child: Text(
                    label,
                    style: checked
                        ? t.row.label.copyWith(
                            fontWeight: FontWeight.w700,
                            fontVariations: [FontVariation.weight(700)],
                          )
                        : t.row.label,
                  ),
                ),
                const SizedBox(width: Spacing.besideIcon),
                Icon(
                  Icons.check,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = Spacing.underLabel;
            final cell = (constraints.maxWidth - gap * 6) / 7;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var day = 1; day <= 31; day++)
                  SizedBox(
                    width: cell,
                    height: cell.clamp(48, double.infinity),
                    child: _DayCell(
                      day: day,
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

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.chosen,
    required this.onTap,
  });

  final int day;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final style = chosen ? t.button.label : t.row.label;
    return Semantics(
      button: true,
      checked: chosen,
      label: '$day',
      excludeSemantics: true,
      child: Material(
        color: chosen ? t.button.background : t.card.background,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$day', style: style),
            ),
          ),
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
    required this.doneLabel,
    required this.noDateLabel,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final String Function(DateTime) describe;
  final String doneLabel;
  final String? noDateLabel;

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  late DateTime _date = widget.initial;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final noDate = widget.noDateLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(widget.describe(_date), style: t.takePanel.instruction),
        ),
        SizedBox(height: t.field.labelGap),
        Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              dayStyle: t.row.label,
              weekdayStyle: t.field.label,
              yearStyle: t.row.label,
              todayBorder: BorderSide(color: t.focus.ring),
            ),
          ),
          child: CalendarDatePicker(
            initialDate: widget.initial,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            onDateChanged: (date) => setState(() => _date = date),
          ),
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
            child: Text(noDate),
          ),
        ],
      ],
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
                      Center(child: Text(name, style: style)),
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
