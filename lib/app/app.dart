import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sahaay_design/sahaay_design.dart';

import 'router.dart';
import 'routes.dart';

class SahaayApp extends StatefulWidget {
  const SahaayApp({this.initialLocation = AppRoutes.today, super.key});

  /// Where the app opens; tests start some flows elsewhere.
  final String initialLocation;

  @override
  State<SahaayApp> createState() => _SahaayAppState();
}

class _SahaayAppState extends State<SahaayApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sahaay',
      theme: SahaayTheme.light(),
      routerConfig: _router,
    );
  }
}
