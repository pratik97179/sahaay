import 'package:flutter/widgets.dart';

import 'destination.dart';

/// Builds what an overlay shows. [animation] runs as it comes in and goes
/// out; [close] takes it away, with an optional result for whoever opened
/// it.
typedef OverlayBuilder<T> = Widget Function(
  BuildContext context,
  Animation<double> animation,
  void Function([T? result]) close,
);

/// The one way screens move around the app (`docs/architecture.md`,
/// Navigation). Every screen change goes through it, so every screen change
/// looks the same: Sahaay's screen change, and its reverse going back.
///
/// Widgets reach it with [AppNavigator.of]. Nothing else may use Flutter's
/// `Navigator`, go_router or a page route directly; `tool/check_navigation.sh`
/// checks this with analyze.
abstract interface class AppNavigator {
  /// The app's navigator, from the [NavigationScope] above every screen.
  static AppNavigator of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<NavigationScope>();
    assert(scope != null, 'No NavigationScope above this context.');
    return scope!.navigator;
  }

  /// Opens [to] over the current screen. Completes with the result it is
  /// closed with, if any.
  Future<T?> open<T extends Object?>(Destination to);

  /// Opens [to] in place of the current screen, which goes away (after
  /// saving a new medicine, its page replaces the steps that made it).
  void replace(Destination to);

  /// Shows [to] with exactly its parents beneath it, whatever was open
  /// before (a tapped notification).
  void reset(Destination to);

  /// Goes back one screen, as the system back does: a screen or overlay
  /// that guards leaving (`PopScope`) is asked first.
  void back<T extends Object?>([T? result]);

  /// Shows a see-through layer over the current screen, drawn and animated
  /// entirely by [builder] (the lifted sticky note). Completes with the
  /// result [OverlayBuilder]'s `close` was given.
  Future<T?> overlay<T extends Object?>(
    OverlayBuilder<T> builder, {
    required Duration duration,
    required Duration reverseDuration,
  });
}

/// Puts [navigator] above every screen, for [AppNavigator.of].
class NavigationScope extends InheritedWidget {
  const NavigationScope({
    required this.navigator,
    required super.child,
    super.key,
  });

  final AppNavigator navigator;

  @override
  bool updateShouldNotify(NavigationScope oldWidget) =>
      navigator != oldWidget.navigator;
}
