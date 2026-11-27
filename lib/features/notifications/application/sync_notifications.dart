import 'package:flutter/foundation.dart';

import '../../medicines/domain/medicine.dart';
import '../../reminders/domain/calendar.dart';
import '../../reminders/domain/reminder.dart';
import 'notification_requests.dart';
import 'notification_scheduler.dart';

/// Keeps the device's pending notifications in step with the reminders.
///
/// Each sync replaces every pending notification with the current plan, so
/// edits, pauses and deletes take effect at once and single notifications
/// are topped up whenever the app runs. Syncs run one at a time, in order.
///
/// Permission is asked once per run, once there is a reminder. When the
/// first reminder is saved during this run, Android is also asked for exact
/// timing; an app that opens with reminders already saved only asks for
/// notifications, so it doesn't send the person to a settings page.
final class SyncNotifications {
  SyncNotifications({
    required this._scheduler,
    required this._now,
    required this._formatTime,
  });

  final NotificationScheduler _scheduler;
  final LocalDateTime Function() _now;
  final String Function(LocalTime) _formatTime;

  Future<void> _last = Future.value();
  bool? _startedEmpty;
  bool _asked = false;

  Future<void> call({
    required List<Reminder> reminders,
    required List<Medicine> medicines,
  }) => _last = _last.then((_) => _sync(reminders, medicines));

  Future<void> _sync(List<Reminder> reminders, List<Medicine> medicines) async {
    try {
      _startedEmpty ??= reminders.isEmpty;
      if (reminders.isNotEmpty && !_asked) {
        _asked = true;
        await _scheduler.requestPermission(exactTiming: _startedEmpty!);
      }
      await _scheduler.replaceAll(
        buildNotificationRequests(
          reminders: reminders,
          medicines: {for (final m in medicines) m.id: m},
          now: _now(),
          formatTime: _formatTime,
        ),
      );
    } on Object catch (error, stack) {
      // A failed sync must not take the app down; the next one retries.
      debugPrint('Notification sync failed: $error\n$stack');
    }
  }
}
