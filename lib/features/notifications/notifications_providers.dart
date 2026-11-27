import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/clock.dart';
import '../medicines/medicines_providers.dart';
import '../reminders/domain/calendar.dart';
import '../reminders/reminders_providers.dart';
import 'application/notification_scheduler.dart';
import 'application/sync_notifications.dart';

/// The device's notification service; set up in `main` before the app runs.
final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => throw UnimplementedError(
    'notificationSchedulerProvider must be overridden at start-up.',
  ),
);

final syncNotificationsProvider = Provider<SyncNotifications>(
  (ref) => SyncNotifications(
    scheduler: ref.watch(notificationSchedulerProvider),
    now: () => LocalDateTime.fromDateTime(ref.read(clockProvider)()),
    formatTime: _formatTime,
  ),
);

/// Watched by the app for as long as it runs: every change to the
/// reminders or medicines reschedules the notifications. Invalidating it
/// syncs again, such as when the app comes back to the foreground.
final notificationsInSyncProvider = Provider<void>((ref) {
  void sync() {
    final reminders = ref.read(allRemindersProvider).value;
    final medicines = ref.read(medicinesProvider).value;
    if (reminders == null || medicines == null) return;
    ref.read(syncNotificationsProvider)(
      reminders: reminders,
      medicines: medicines,
    );
  }

  ref.listen(allRemindersProvider, (_, _) => sync(), fireImmediately: true);
  ref.listen(medicinesProvider, (_, _) => sync(), fireImmediately: true);
});

/// A reminder's time as the phone shows times: "8:00 am" or "20:00".
String _formatTime(LocalTime t) {
  final minutes = t.minute.toString().padLeft(2, '0');
  if (PlatformDispatcher.instance.alwaysUse24HourFormat) {
    return '${t.hour.toString().padLeft(2, '0')}:$minutes';
  }
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$hour:$minutes ${t.hour < 12 ? 'am' : 'pm'}';
}
