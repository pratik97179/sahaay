import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';
import 'package:sahaay/features/reminders/domain/reminder.dart';
import 'package:sahaay/features/reminders/domain/reminder_schedule.dart';

void main() {
  final now = LocalDateTime(LocalDate(2026, 11, 25), LocalTime(8, 0));
  Reminder reminder({String id = 'r1', bool paused = false}) => Reminder(
    id: id,
    medicineId: 'm1',
    schedule: ReminderSchedule(
      time: LocalTime(9, 0),
      recurrence: DailyRecurrence(),
      startDate: LocalDate(2026, 11, 1),
    ),
    quantity: ' 1 tablet ',
    instruction: '   ',
    isPaused: paused,
  );

  test('stores quantity and instruction as entered, blank as absent', () {
    final r = reminder();
    expect(r.quantity, '1 tablet');
    expect(r.instruction, isNull);
  });

  test('a paused reminder has no next notification', () {
    expect(reminder().nextNotification(now), isNotNull);
    expect(reminder(paused: true).nextNotification(now), isNull);
  });

  test('copyWith changes only the given reminder', () {
    final morning = reminder();
    final evening = reminder(id: 'r2');
    final paused = morning.copyWith(
      isPaused: true,
      instruction: () => 'After food',
    );

    expect(paused.isPaused, isTrue);
    expect(paused.instruction, 'After food');
    expect(paused.quantity, '1 tablet');
    expect(morning.isPaused, isFalse);
    expect(evening.isPaused, isFalse);
  });

  test('a past one-time reminder is finished', () {
    final r = Reminder(
      id: 'r',
      medicineId: 'm',
      schedule: ReminderSchedule(
        time: LocalTime(7, 0),
        recurrence: const OneTimeRecurrence(),
        startDate: LocalDate(2026, 11, 25),
      ),
    );
    expect(r.isFinished(now), isTrue);
  });
}
