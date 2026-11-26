import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stage.dart';

final List<WidgetbookNode> fields = [
  WidgetbookComponent(
    name: 'TextInputField',
    useCases: [
      staged(
        'Default',
        (context) => TextInputField(
          label: context.text('label', 'Name'),
          placeholder: context.knobs.stringOrNull(
            label: 'Placeholder',
            initialValue: 'For example, Test 2',
          ),
          enabled: context.knobs.boolean(label: 'Enabled', initialValue: true),
        ),
      ),
      staged(
        'Error',
        (context) => TextInputField(
          label: 'Name',
          errorText: context.text('error', 'Give the medicine a name.'),
        ),
      ),
      staged(
        'Disabled',
        (context) => const TextInputField(label: 'Name', enabled: false),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'PickerField',
    useCases: [
      staged(
        'Empty',
        (context) => PickerField(
          label: 'Repeats',
          value: null,
          placeholder: context.text('placeholder', 'Choose how often'),
          icon: Icons.repeat,
          onTap: () {},
        ),
      ),
      staged(
        'Filled',
        (context) => PickerField(
          label: 'Repeats',
          value: context.text('value', 'Every Monday and Thursday'),
          placeholder: 'Choose how often',
          icon: Icons.repeat,
          onTap: () {},
        ),
      ),
      staged(
        'Error',
        (context) => PickerField(
          label: 'Repeats',
          value: null,
          placeholder: 'Choose how often',
          icon: Icons.repeat,
          errorText: 'Choose how often it repeats.',
          onTap: () {},
        ),
      ),
      staged(
        'Disabled',
        (context) => const PickerField(
          label: 'Repeats',
          value: 'Daily',
          placeholder: 'Choose how often',
          icon: Icons.repeat,
          onTap: null,
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Picker sheets',
    useCases: [
      staged(
        'Time wheel',
        (context) => _Opens<TimeOfDay>(
          label: 'Time',
          icon: Icons.schedule,
          open: (context) => showTimeWheelSheet(
            context,
            title: 'Time',
            doneLabel: 'Done',
            initial: const TimeOfDay(hour: 9, minute: 0),
          ),
          describe: (time) => time.format(context),
        ),
      ),
      staged(
        'Choice',
        (context) => _Opens<String>(
          label: 'Repeats',
          icon: Icons.repeat,
          open: (context) => showChoiceSheet(
            context,
            title: 'Repeats',
            options: const [
              ('Daily', 'Daily'),
              ('Weekly', 'Weekly'),
              ('Monthly', 'Monthly'),
              ('Yearly', 'Yearly'),
            ],
            selected: 'Daily',
          ),
          describe: (choice) => choice,
        ),
      ),
      staged(
        'Multiple choice',
        (context) => _Opens<Set<int>>(
          label: 'On',
          icon: Icons.calendar_view_week,
          open: (context) => showMultiChoiceSheet(
            context,
            title: 'On',
            doneLabel: 'Done',
            options: [for (var i = 0; i < 7; i++) (i + 1, _weekdays[i])],
            selected: const {1, 4},
          ),
          describe: (days) =>
              [for (final d in days.toList()..sort()) _weekdays[d - 1]]
                  .join(', '),
        ),
      ),
      staged(
        'Days of the month',
        (context) => _Opens<Set<int>>(
          label: 'On days',
          icon: Icons.calendar_month,
          open: (context) => showDayOfMonthSheet(
            context,
            title: 'On days',
            doneLabel: 'Done',
            footnote: '31 means the last day of the month.',
            selected: const {1, 15},
          ),
          describe: (days) => (days.toList()..sort()).join(', '),
        ),
      ),
      staged(
        'Calendar',
        (context) => _Opens<DateChoice>(
          label: 'End date',
          icon: Icons.event,
          open: (context) {
            final today = DateUtils.dateOnly(DateTime.now());
            return showCalendarSheet(
              context,
              title: 'End date',
              doneLabel: 'Done',
              noDateLabel: 'No end date',
              initial: today,
              firstDate: today,
              lastDate: DateTime(today.year + 5),
              describe: _describeDate,
              describeMonth: (d) => '${_months[d.month - 1]} ${d.year}',
              weekdayLabels: [for (final d in _weekdays) d.substring(0, 1)],
              previousMonthLabel: 'Previous month',
              nextMonthLabel: 'Next month',
            );
          },
          describe: (choice) {
            final date = choice.date;
            return date == null ? 'No end date' : _describeDate(date);
          },
        ),
      ),
      staged(
        'Month and day',
        (context) => _Opens<({int month, int day})>(
          label: 'Every year on',
          icon: Icons.cake_outlined,
          open: (context) => showMonthDaySheet(
            context,
            title: 'Every year on',
            doneLabel: 'Done',
            monthNames: _months,
            month: 3,
            day: 1,
          ),
          describe: (d) => '${d.day} ${_months[d.month - 1]}',
        ),
      ),
    ],
  ),
];

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

String _describeDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

/// A picker field that opens a sheet and shows what was chosen, as a
/// screen would.
class _Opens<T> extends StatefulWidget {
  const _Opens({
    required this.label,
    required this.icon,
    required this.open,
    required this.describe,
  });

  final String label;
  final IconData icon;
  final Future<T?> Function(BuildContext context) open;
  final String Function(T value) describe;

  @override
  State<_Opens<T>> createState() => _OpensState<T>();
}

class _OpensState<T> extends State<_Opens<T>> {
  String? _value;

  @override
  Widget build(BuildContext context) => PickerField(
    label: widget.label,
    value: _value,
    placeholder: 'Tap to choose',
    icon: widget.icon,
    onTap: () async {
      final chosen = await widget.open(context);
      if (chosen != null && mounted) {
        setState(() => _value = widget.describe(chosen));
      }
    },
  );
}
