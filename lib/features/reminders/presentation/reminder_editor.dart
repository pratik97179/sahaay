import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../../design_system/design_system.dart';
import '../application/reminder_draft.dart';
import '../domain/calendar.dart';
import 'schedule_text.dart';

/// The reminder form: schedule, time, dates, quantity and instruction
/// (PRD FR-03, FR-04).
///
/// Shows only the options of the chosen repeat type. Validates on submit and
/// hands valid [ReminderDetails] to [onSubmit]; if that throws, the form stays
/// open with an error message.
class ReminderEditor extends ConsumerStatefulWidget {
  const ReminderEditor({
    required this.initial,
    required this.submitLabel,
    required this.onSubmit,
    super.key,
  });

  final ReminderDraft initial;
  final String submitLabel;
  final Future<void> Function(ReminderDetails details) onSubmit;

  @override
  ConsumerState<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends ConsumerState<ReminderEditor> {
  late ReminderDraft _draft = widget.initial;
  late final _interval = TextEditingController(
    text: widget.initial.interval?.toString() ?? '',
  );
  late final _quantity = TextEditingController(text: widget.initial.quantity);
  late final _instruction = TextEditingController(
    text: widget.initial.instruction,
  );
  bool _showErrors = false;
  bool _busy = false;

  @override
  void dispose() {
    _interval.dispose();
    _quantity.dispose();
    _instruction.dispose();
    super.dispose();
  }

  DateTime _clockNow() => ref.read(clockProvider)();

  LocalDateTime _now() => LocalDateTime.fromDateTime(_clockNow());

  void _update(ReminderDraft draft) => setState(() => _draft = draft);

  Future<void> _pickTime() async {
    final current = _draft.time;
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? TimeOfDay.fromDateTime(_clockNow())
          : TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null && mounted) {
      _update(_draft.copyWith(time: LocalTime(picked.hour, picked.minute)));
    }
  }

  Future<void> _pickStartDate() async {
    final today = _now().date;
    final start = _draft.startDate;
    // A one-time reminder must be in the future, so earlier days are not
    // offered; a repeating one may count its interval from a past date.
    final earliest = _draft.repeat == RepeatType.once && !start.isBefore(today)
        ? today
        : null;
    final picked = await _pickDate(start, earliest: earliest);
    if (picked != null && mounted) {
      _update(_draft.copyWith(startDate: picked));
    }
  }

  Future<void> _pickEndDate() async {
    final start = _draft.startDate;
    final end = _draft.endDate;
    final picked = await _pickDate(
      end ?? start,
      earliest: end == null || !end.isBefore(start) ? start : end,
    );
    if (picked != null && mounted) {
      _update(_draft.copyWith(endDate: () => picked));
    }
  }

  Future<LocalDate?> _pickDate(LocalDate initial, {LocalDate? earliest}) async {
    DateTime toDateTime(LocalDate d) => DateTime(d.year, d.month, d.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: toDateTime(initial),
      firstDate: earliest == null ? DateTime(2000) : toDateTime(earliest),
      lastDate: DateTime(2100, 12, 31),
    );
    return picked == null ? null : LocalDate.fromDateTime(picked);
  }

  Future<void> _submit() async {
    final details = _draft.toDetails(_now());
    if (details == null) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onSubmit(details);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                "The reminder couldn't be saved. Please try again.",
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final errors = _showErrors
        ? draft.errors(_now())
        : const <ReminderDraftError>{};
    String? error(ReminderDraftError e) =>
        errors.contains(e) ? _messages[e] : null;
    final time = draft.time;
    final endDate = draft.endDate;
    final once = draft.repeat == RepeatType.once;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContentSection(
          heading: 'Schedule',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: 'Repeats',
                child: _RepeatChoice(
                  selected: draft.repeat,
                  onSelected: (repeat) =>
                      _update(draft.copyWith(repeat: repeat)),
                ),
              ),
              if (_unitFor(draft.repeat) case final unit?)
                LabeledField(
                  label: 'Repeat every',
                  errorText: error(ReminderDraftError.intervalInvalid),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: TextField(
                          controller: _interval,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: const InputDecoration(hintText: '1'),
                          onChanged: (text) => _update(
                            draft.copyWith(interval: () => int.tryParse(text)),
                          ),
                        ),
                      ),
                      SizedBox(width: context.spacing.inlineSeparation),
                      Text(
                        draft.interval == 1 ? unit : '${unit}s',
                        style: context.typography.fieldValue,
                      ),
                    ],
                  ),
                ),
              if (draft.repeat == RepeatType.weekly)
                LabeledField(
                  label: 'On these days',
                  errorText: error(ReminderDraftError.weekdaysMissing),
                  child: _WeekdayChoice(
                    selected: draft.weekdays,
                    onChanged: (days) =>
                        _update(draft.copyWith(weekdays: days)),
                  ),
                ),
              if (draft.repeat == RepeatType.monthly)
                LabeledField(
                  label: 'On these days of the month',
                  errorText: error(ReminderDraftError.monthDaysMissing),
                  child: _MonthDayChoice(
                    selected: draft.monthDays,
                    onChanged: (days) =>
                        _update(draft.copyWith(monthDays: days)),
                  ),
                ),
              if (draft.repeat == RepeatType.yearly)
                LabeledField(
                  label: 'Date each year',
                  errorText: error(ReminderDraftError.yearlyDateMissing),
                  child: _YearlyDateChoice(
                    month: draft.yearlyMonth,
                    day: draft.yearlyDay,
                    onMonthChanged: (month) {
                      final day = draft.yearlyDay;
                      final fits =
                          day == null ||
                          day <= LocalDate.daysInMonth(2024, month);
                      _update(
                        draft.copyWith(
                          yearlyMonth: month,
                          yearlyDay: () => fits ? day : null,
                        ),
                      );
                    },
                    onDayChanged: (day) =>
                        _update(draft.copyWith(yearlyDay: () => day)),
                  ),
                ),
              LabeledField(
                label: 'Time',
                errorText:
                    error(ReminderDraftError.timeMissing) ??
                    error(ReminderDraftError.onceNotInFuture),
                child: PickerInput(
                  value: time == null ? null : formatTime(context, time),
                  placeholder: 'Choose a time',
                  icon: Icons.schedule,
                  onTap: _pickTime,
                  hasError:
                      errors.contains(ReminderDraftError.timeMissing) ||
                      errors.contains(ReminderDraftError.onceNotInFuture),
                ),
              ),
              LabeledField(
                label: once ? 'Date' : 'Start date',
                child: PickerInput(
                  value: formatDate(context, draft.startDate),
                  placeholder: 'Choose a date',
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickStartDate,
                ),
              ),
              if (!once)
                LabeledField(
                  label: 'End date',
                  errorText: error(ReminderDraftError.endBeforeStart),
                  child: PickerInput(
                    value: endDate == null
                        ? null
                        : formatDate(context, endDate),
                    placeholder: 'No end date',
                    icon: Icons.event_outlined,
                    onTap: _pickEndDate,
                    onClear: () => _update(draft.copyWith(endDate: () => null)),
                    clearLabel: 'Remove end date',
                    hasError: errors.contains(
                      ReminderDraftError.endBeforeStart,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ContentSection(
          heading: 'Quantity and instruction',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: 'Quantity',
                child: TextField(
                  controller: _quantity,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Optional'),
                  onChanged: (text) => _update(_draft.copyWith(quantity: text)),
                ),
              ),
              LabeledField(
                label: 'Instruction',
                child: TextField(
                  controller: _instruction,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Optional'),
                  onChanged: (text) =>
                      _update(_draft.copyWith(instruction: text)),
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  static String? _unitFor(RepeatType repeat) => switch (repeat) {
    RepeatType.daily => 'day',
    RepeatType.weekly => 'week',
    RepeatType.monthly => 'month',
    RepeatType.once || RepeatType.yearly => null,
  };

  static const _messages = {
    ReminderDraftError.timeMissing: 'Choose a time.',
    ReminderDraftError.intervalInvalid: 'Enter a number of 1 or more.',
    ReminderDraftError.weekdaysMissing: 'Choose at least one day.',
    ReminderDraftError.monthDaysMissing: 'Choose at least one day.',
    ReminderDraftError.yearlyDateMissing: 'Choose a month and a day.',
    ReminderDraftError.endBeforeStart:
        "The end date can't be before the start date.",
    ReminderDraftError.onceNotInFuture: 'Choose a date and time in the future.',
  };
}

class _RepeatChoice extends StatelessWidget {
  const _RepeatChoice({required this.selected, required this.onSelected});

  final RepeatType selected;
  final ValueChanged<RepeatType> onSelected;

  static const _labels = {
    RepeatType.once: 'Once',
    RepeatType.daily: 'Daily',
    RepeatType.weekly: 'Weekly',
    RepeatType.monthly: 'Monthly',
    RepeatType.yearly: 'Yearly',
  };

  @override
  Widget build(BuildContext context) {
    final gap = context.spacing.inlineSeparation;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final type in RepeatType.values)
          ChoiceChip(
            label: Text(_labels[type]!),
            selected: type == selected,
            onSelected: (_) => onSelected(type),
          ),
      ],
    );
  }
}

class _WeekdayChoice extends StatelessWidget {
  const _WeekdayChoice({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final gap = context.spacing.inlineSeparation;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (var day = 1; day <= 7; day++)
          FilterChip(
            label: Text(
              shortWeekdayName(day),
              semanticsLabel: weekdayNames[day - 1],
            ),
            selected: selected.contains(day),
            onSelected: (on) => onChanged(_toggle(selected, day, on)),
          ),
      ],
    );
  }
}

class _MonthDayChoice extends StatelessWidget {
  const _MonthDayChoice({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final gap = context.spacing.inlineSeparation;
    final note = monthDaysNote(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var day = 1; day <= 31; day++)
              FilterChip(
                // Without a checkmark every chip keeps its width, so the days
                // stay in a steady grid; selection also shows as a bold
                // label and is announced by screen readers.
                showCheckmark: false,
                // Tight padding fits a week's worth of days per row on a
                // phone, like a calendar; the tap target stays 48 high.
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 24),
                  child: Text(
                    '$day',
                    textAlign: TextAlign.center,
                    semanticsLabel: 'Day $day',
                    style: selected.contains(day)
                        ? const TextStyle(fontWeight: FontWeight.w700)
                        : null,
                  ),
                ),
                selected: selected.contains(day),
                onSelected: (on) => onChanged(_toggle(selected, day, on)),
              ),
          ],
        ),
        if (note != null) ...[
          SizedBox(height: context.spacing.fieldLabelControl),
          Text(note, style: context.typography.supporting),
        ],
      ],
    );
  }
}

class _YearlyDateChoice extends StatelessWidget {
  const _YearlyDateChoice({
    required this.month,
    required this.day,
    required this.onMonthChanged,
    required this.onDayChanged,
  });

  final int? month;
  final int? day;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onDayChanged;

  @override
  Widget build(BuildContext context) {
    final month = this.month;
    // Before a month is chosen every day is offered; choosing a month that
    // lacks the chosen day clears it. 29 February is allowed.
    final days = month == null ? 31 : LocalDate.daysInMonth(2024, month);
    final note = month == 2 && day == 29 ? leapDayNote : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _Dropdown(
                hint: 'Month',
                value: month,
                items: {for (var m = 1; m <= 12; m++) m: monthNames[m - 1]},
                onChanged: onMonthChanged,
              ),
            ),
            SizedBox(width: context.spacing.inlineSeparation),
            Expanded(
              flex: 2,
              child: _Dropdown(
                hint: 'Day',
                value: day,
                items: {for (var d = 1; d <= days; d++) d: '$d'},
                onChanged: onDayChanged,
              ),
            ),
          ],
        ),
        if (note != null) ...[
          SizedBox(height: context.spacing.fieldLabelControl),
          Text(note, style: context.typography.supporting),
        ],
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final int? value;
  final Map<int, String> items;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: [
            for (final MapEntry(:key, :value) in items.entries)
              DropdownMenuItem(value: key, child: Text(value)),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }
}

Set<int> _toggle(Set<int> set, int value, bool on) =>
    on ? {...set, value} : ({...set}..remove(value));
