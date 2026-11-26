import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

/// Turns on the system's reduce-motion setting for the use case, so the
/// catalogue shows what `context.sahaay` does with it: no spring, no
/// movement, short cross-fades (`docs/design-system.md` §9).
///
/// Widgetbook has no built-in addon for this.
class ReducedMotionAddon extends WidgetbookAddon<bool> {
  ReducedMotionAddon() : super(name: 'Reduced motion');

  @override
  List<Field> get fields => [
    BooleanField(name: 'enabled', initialValue: false),
  ];

  @override
  bool valueFromQueryGroup(Map<String, String> group) =>
      valueOf<bool>('enabled', group) ?? false;

  @override
  Widget buildUseCase(BuildContext context, Widget child, bool setting) =>
      MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: setting),
        child: child,
      );
}
