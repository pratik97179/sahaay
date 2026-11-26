import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_theme.dart';
import 'router.dart';

class SahaayApp extends StatefulWidget {
  const SahaayApp({super.key});

  @override
  State<SahaayApp> createState() => _SahaayAppState();
}

class _SahaayAppState extends State<SahaayApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sahaay',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
