import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_navigator.dart';
import 'destination.dart';
import 'screen_route.dart';

/// [AppNavigator] on go_router. Screens are pages, so they take the app
/// theme's screen change and the edge swipe back.
final class GoRouterNavigator implements AppNavigator {
  GoRouterNavigator({
    required List<ScreenRoute> screens,
    required Destination start,
  }) : _table = ScreenTable(screens) {
    router = GoRouter(
      initialLocation: _table.locationOf(start),
      routes: [_table.root],
    );
  }

  final ScreenTable _table;

  /// For `MaterialApp.router`.
  late final GoRouter router;

  NavigatorState get _navigator =>
      router.routerDelegate.navigatorKey.currentState!;

  @override
  Future<T?> open<T extends Object?>(Destination to) =>
      router.push<T>(_table.locationOf(to));

  @override
  void replace(Destination to) =>
      unawaited(router.pushReplacement<Object?>(_table.locationOf(to)));

  @override
  void reset(Destination to) => router.go(_table.locationOf(to));

  @override
  void back<T extends Object?>([T? result]) =>
      unawaited(_navigator.maybePop<T>(result));

  @override
  Future<T?> overlay<T extends Object?>(
    OverlayBuilder<T> builder, {
    required Duration duration,
    required Duration reverseDuration,
  }) {
    late final PageRouteBuilder<T> route;
    void close([T? result]) {
      final navigator = route.navigator;
      if (navigator == null || !route.isActive) return;
      if (route.isCurrent) {
        navigator.pop<T>(result);
      } else {
        navigator.removeRoute<T>(route, result);
      }
    }

    route = PageRouteBuilder<T>(
      opaque: false,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, _) =>
          builder(context, animation, close),
      // The overlay animates itself.
      transitionsBuilder: (context, animation, _, child) => child,
    );
    return _navigator.push<T>(route);
  }

  void dispose() => router.dispose();
}
