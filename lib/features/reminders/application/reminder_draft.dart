import '../domain/calendar.dart';
import '../domain/recurrence.dart';
import '../domain/reminder_schedule.dart';

/// The recurrence patterns the user can choose from (PRD FR-03).
enum RepeatType { once, daily, weekly, monthly, yearly }

/// Why a draft cannot be saved yet.
enum ReminderDraftError {
  timeMissing,
  intervalInvalid,
  weekdaysMissing,
  monthDaysMissing,
  yearlyDateMissing,
  endBeforeStart,

  /// A one-time reminder whose date and time have already passed could never
  /// notify.
  onceNotInFuture,
}

/// What a valid draft produces: everything needed to save a reminder.
final class ReminderDetails {
  const ReminderDetails({
    required this.schedule,
    this.quantity,
    this.instruction,
  });

  final ReminderSchedule schedule;
  final String? quantity;
  final String? instruction;
}

/// A reminder being entered or edited, possibly incomplete.
///
/// Holds every option of every repeat type so switching type and back keeps
/// what the user chose; only the options of [repeat] are used when saving.
final class ReminderDraft {
  const ReminderDraft({
    required this.repeat,
    required this.startDate,
    this.time,
    this.interval = 1,
    this.weekdays = const {},
    this.monthDays = const {},
    this.yearlyMonth,
    this.yearlyDay,
    this.endDate,
    this.quantity = '',
    this.instruction = '',
  });

  /// A new reminder: daily, every day, starting [today]. The time and the
  /// days are left for the user to choose.
  factory ReminderDraft.initial(LocalDate today) =>
      ReminderDraft(repeat: RepeatType.daily, startDate: today);

  final RepeatType repeat;
  final LocalTime? time;

  /// Every N days, weeks or months; `null` while the field is empty.
  final int? interval;

  /// ISO weekdays, Monday = 1.
  final Set<int> weekdays;
  final Set<int> monthDays;
  final int? yearlyMonth;
  final int? yearlyDay;

  /// The first day it may fire; the date itself for a one-time reminder.
  final LocalDate startDate;
  final LocalDate? endDate;
  final String quantity;
  final String instruction;

  bool get _usesInterval =>
      repeat == RepeatType.daily ||
      repeat == RepeatType.weekly ||
      repeat == RepeatType.monthly;

  /// Problems that prevent saving, judged against [now].
  Set<ReminderDraftError> errors(LocalDateTime now) {
    final time = this.time;
    final interval = this.interval;
    final endDate = this.endDate;
    return {
      if (time == null) ReminderDraftError.timeMissing,
      if (_usesInterval && (interval == null || interval < 1))
        ReminderDraftError.intervalInvalid,
      if (repeat == RepeatType.weekly && weekdays.isEmpty)
        ReminderDraftError.weekdaysMissing,
      if (repeat == RepeatType.monthly && monthDays.isEmpty)
        ReminderDraftError.monthDaysMissing,
      if (repeat == RepeatType.yearly &&
          (yearlyMonth == null || yearlyDay == null))
        ReminderDraftError.yearlyDateMissing,
      if (repeat != RepeatType.once &&
          endDate != null &&
          endDate.isBefore(startDate))
        ReminderDraftError.endBeforeStart,
      if (repeat == RepeatType.once &&
          time != null &&
          LocalDateTime(startDate, time).compareTo(now) <= 0)
        ReminderDraftError.onceNotInFuture,
    };
  }

  /// The reminder details, or `null` when [errors] is not empty.
  ReminderDetails? toDetails(LocalDateTime now) {
    if (errors(now).isNotEmpty) return null;
    final recurrence = switch (repeat) {
      RepeatType.once => const OneTimeRecurrence(),
      RepeatType.daily => DailyRecurrence(interval: interval!),
      RepeatType.weekly => WeeklyRecurrence(
        weekdays: weekdays,
        interval: interval!,
      ),
      RepeatType.monthly => MonthlyRecurrence(
        days: monthDays,
        interval: interval!,
      ),
      RepeatType.yearly => YearlyRecurrence(
        month: yearlyMonth!,
        day: yearlyDay!,
      ),
    };
    return ReminderDetails(
      schedule: ReminderSchedule(
        time: time!,
        recurrence: recurrence,
        startDate: startDate,
        endDate: repeat == RepeatType.once ? null : endDate,
      ),
      quantity: quantity,
      instruction: instruction,
    );
  }

  ReminderDraft copyWith({
    RepeatType? repeat,
    LocalTime? time,
    int? Function()? interval,
    Set<int>? weekdays,
    Set<int>? monthDays,
    int? yearlyMonth,
    int? Function()? yearlyDay,
    LocalDate? startDate,
    LocalDate? Function()? endDate,
    String? quantity,
    String? instruction,
  }) => ReminderDraft(
    repeat: repeat ?? this.repeat,
    time: time ?? this.time,
    interval: interval != null ? interval() : this.interval,
    weekdays: weekdays ?? this.weekdays,
    monthDays: monthDays ?? this.monthDays,
    yearlyMonth: yearlyMonth ?? this.yearlyMonth,
    yearlyDay: yearlyDay != null ? yearlyDay() : this.yearlyDay,
    startDate: startDate ?? this.startDate,
    endDate: endDate != null ? endDate() : this.endDate,
    quantity: quantity ?? this.quantity,
    instruction: instruction ?? this.instruction,
  );
}
