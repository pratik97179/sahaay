import 'notification_requests.dart';

/// The device's notification service, as the app needs it. The plugin sits
/// behind this so the scheduling rules stay testable without one.
abstract interface class NotificationScheduler {
  /// Replaces every pending reminder notification with [requests].
  Future<void> replaceAll(List<NotificationRequest> requests);

  /// Asks the person to allow notifications. With [exactTiming], on Android
  /// it also asks to time them exactly. A refusal is accepted quietly.
  Future<void> requestPermission({required bool exactTiming});

  /// The reminder whose notification opened the app, if one did.
  Future<String?> launchReminderId();

  /// The reminder of each notification the person taps while the app runs.
  Stream<String> get taps;
}
