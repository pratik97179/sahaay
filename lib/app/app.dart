import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../core/launch/launch_handoff.dart';
import '../core/navigation/go_router_navigator.dart';
import '../core/navigation/navigation.dart';
import '../features/day/day_destinations.dart';
import '../features/notifications/notifications_providers.dart';
import '../features/reminders/reminders_destinations.dart';
import 'app_screens.dart';
import 'launch_curtain.dart';

class SahaayApp extends ConsumerStatefulWidget {
  const SahaayApp({
    this.start = const TodayDestination(),
    this.launchCurtain = true,
    super.key,
  });

  /// Where the app opens; tests start some flows elsewhere.
  final Destination start;

  /// Carries the launch screen into the first screen; tests leave it out.
  final bool launchCurtain;

  @override
  ConsumerState<SahaayApp> createState() => _SahaayAppState();
}

class _SahaayAppState extends ConsumerState<SahaayApp> {
  late final GoRouterNavigator _navigator = GoRouterNavigator(
    screens: appScreens(),
    start: widget.start,
  );
  late final StreamSubscription<String> _taps;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final notifications = ref.read(notificationSchedulerProvider);
    // A tapped notification opens its reminder, with Today beneath it.
    _taps = notifications.taps.listen(_openReminder);
    unawaited(
      notifications.launchReminderId().then((id) {
        if (id == null) return;
        // Opened on a reminder, not Today: the launch screen just fades.
        ref.read(launchHandoffProvider).land(const LaunchLanding.none());
        _openReminder(id);
      }),
    );
    // Back in the foreground: time has moved on, so plan again.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationsInSyncProvider),
    );
  }

  void _openReminder(String id) => _navigator.reset(ReminderDestination(id));

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_taps.cancel());
    _navigator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationsInSyncProvider);
    return NavigationScope(
      navigator: _navigator,
      child: MaterialApp.router(
        title: 'sahaay',
        theme: SahaayTheme.light(),
        routerConfig: _navigator.router,
        builder: widget.launchCurtain
            ? (context, child) =>
                  Stack(children: [?child, const LaunchCurtain()])
            : null,
      ),
    );
  }
}
