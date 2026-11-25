import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/medicines/domain/medicine.dart';
import 'package:sahaay/features/notifications/application/notification_requests.dart';
import 'package:sahaay/features/notifications/domain/notification_plan.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/reminder.dart';

import '../../../support/builders.dart';

void main() {
  final now = LocalDateTime(LocalDate(2026, 3, 10), LocalTime(8, 0));
  final past = LocalDate(2026, 1, 1);
  String formatTime(LocalTime t) => 'TIME($t)';

  List<NotificationRequest> build(
    List<Medicine> medicines,
    List<Reminder> reminders,
  ) => buildNotificationRequests(
    reminders: reminders,
    medicines: {for (final m in medicines) m.id: m},
    now: now,
    formatTime: formatTime,
  );

  test('names the medicine and gives quantity and instruction', () {
    final request = build(
      [aMedicine(name: 'Paracetamol')],
      [aReminder(start: past, quantity: '1 tablet', instruction: 'After food')],
    ).single;

    expect(request.title, 'Paracetamol');
    expect(request.body, '1 tablet · After food');
  });

  test('gives whichever of quantity or instruction was entered', () {
    expect(
      build(
        [aMedicine()],
        [aReminder(start: past, quantity: '2 ml')],
      ).single.body,
      '2 ml',
    );
    expect(
      build(
        [aMedicine()],
        [aReminder(start: past, instruction: 'Shake well')],
      ).single.body,
      'Shake well',
    );
  });

  test('gives the time when there is no quantity or instruction', () {
    final request = build(
      [aMedicine()],
      [aReminder(start: past, time: LocalTime(21, 30))],
    ).single;

    expect(request.body, 'Reminder for TIME(21:30)');
  });

  test('uses a generic label for an unnamed medicine', () {
    final request = build(
      [aMedicine(name: null)],
      [aReminder(start: past)],
    ).single;

    expect(request.title, 'Unnamed medicine');
  });

  test('carries the reminder, its time and repeat, with unique ids', () {
    final requests = build(
      [aMedicine(id: 'm1', name: 'A'), aMedicine(id: 'm2', name: 'B')],
      [
        aReminder(id: 'r1', medicineId: 'm1', start: past),
        aReminder(
          id: 'r2',
          medicineId: 'm2',
          start: past,
          time: LocalTime(21, 0),
          end: LocalDate(2026, 3, 11),
        ),
      ],
    );

    expect(requests.map((r) => r.id), [1, 2, 3]);
    expect(requests.map((r) => r.reminderId), ['r1', 'r2', 'r2']);
    expect(requests.map((r) => r.title), ['A', 'B', 'B']);
    expect(requests.first.repeat, NotificationRepeat.daily);
    expect(
      requests.first.at,
      LocalDateTime(LocalDate(2026, 3, 10), LocalTime(9, 0)),
    );
    expect(requests[1].repeat, isNull);
  });

  test('skips a reminder whose medicine is missing', () {
    expect(build([aMedicine(id: 'other')], [aReminder(start: past)]), isEmpty);
  });
}
