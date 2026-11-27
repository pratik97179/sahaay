import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../core/launch/launch_handoff.dart';
import '../features/notifications/notifications_providers.dart';
import 'launch_curtain.dart';
import 'router.dart';
import 'routes.dart';

class SahaayApp extends ConsumerStatefulWidget {
  const SahaayApp({
    this.initialLocation = AppRoutes.today,
    this.launchCurtain = true,
    super.key,
  });

  /// Where the app opens; tests start some flows elsewhere.
  final String initialLocation;

  /// Carries the launch screen into the first screen; tests leave it out.
  final bool launchCurtain;

  @override
  ConsumerState<SahaayApp> createState() => _SahaayAppState();
}

class _SahaayAppState extends ConsumerState<SahaayApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
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

  void _openReminder(String id) => _router.go(AppRoutes.reminder(id));

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_taps.cancel());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationsInSyncProvider);
    return MaterialApp.router(
      title: 'sahaay',
      theme: SahaayTheme.light(),
      routerConfig: _router,
      builder: widget.launchCurtain
          ? (context, child) => Stack(children: [?child, const LaunchCurtain()])
          : null,
    );
  }
}
