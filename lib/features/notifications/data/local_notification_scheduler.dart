import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../application/notification_requests.dart';
import '../application/notification_scheduler.dart';
import '../domain/notification_plan.dart';

/// [NotificationScheduler] on `flutter_local_notifications`, in the
/// device's own time zone.
final class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  // Lives as long as the app; never closed.
  // ignore: close_sinks
  final _taps = StreamController<String>.broadcast();

  /// Sets up time zones and the plugin. Permission is not asked here.
  static Future<LocalNotificationScheduler> create() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));

    final scheduler = LocalNotificationScheduler._(
      FlutterLocalNotificationsPlugin(),
    );
    await scheduler._plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = response.payload;
        if (id != null && id.isNotEmpty) scheduler._taps.add(id);
      },
    );
    return scheduler;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Your medicine reminders.',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> replaceAll(List<NotificationRequest> requests) async {
    await _plugin.cancelAllPendingNotifications();
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final r in requests) {
      final at = r.at;
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        payload: r.reminderId,
        scheduledDate: tz.TZDateTime(
          tz.local,
          at.date.year,
          at.date.month,
          at.date.day,
          at.time.hour,
          at.time.minute,
        ),
        notificationDetails: _details,
        androidScheduleMode: mode,
        matchDateTimeComponents: switch (r.repeat) {
          null => null,
          NotificationRepeat.daily => DateTimeComponents.time,
          NotificationRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
          NotificationRepeat.monthly => DateTimeComponents.dayOfMonthAndTime,
          NotificationRepeat.yearly => DateTimeComponents.dateAndTime,
        },
      );
    }
  }

  @override
  Future<void> requestPermission({required bool exactTiming}) async {
    final android = _android;
    if (android != null) {
      await android.requestNotificationsPermission();
      if (exactTiming &&
          !(await android.canScheduleExactNotifications() ?? true)) {
        await android.requestExactAlarmsPermission();
      }
      return;
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<String?> launchReminderId() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final id = details.notificationResponse?.payload;
    return id == null || id.isEmpty ? null : id;
  }

  @override
  Stream<String> get taps => _taps.stream;
}
