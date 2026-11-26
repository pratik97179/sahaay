import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../foundations/motion.dart';
import '../../foundations/spacing.dart';
import '../../tokens/sahaay_tokens.dart';

/// Opens a bottom sheet in Sahaay's style (`docs/design-system.md` §8, §9,
/// §11.3) and returns what the sheet pops with.
///
/// The sheet rises on the no-bounce spring, can be dragged down and flung
/// away (tracking the finger), and leaves faster than it arrived. With
/// reduced motion it appears and disappears at once.
Future<T?> showSahaaySheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  final t = context.sahaay;
  final spring = t.sheet.spring;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: t.sheet.scrim,
    sheetAnimationStyle: spring == null
        ? AnimationStyle.noAnimation
        : AnimationStyle(
            duration: _springDuration,
            curve: SpringCurve(spring),
            reverseDuration: Motion.expand,
            reverseCurve: Motion.easeIn,
          ),
    builder: (context) => SheetFrame(title: title, child: builder(context)),
  );
}

const _springDuration = Duration(milliseconds: 350);

/// A curve that follows a spring from 0 to 1, so time-based sheet
/// animations move like the physical spring in the motion tokens.
class SpringCurve extends Curve {
  SpringCurve(SpringDescription spring)
    : _simulation = SpringSimulation(spring, 0, 1, 0);

  final SpringSimulation _simulation;

  @override
  double transformInternal(double t) =>
      _simulation.x(t * _springDuration.inMicroseconds / 1e6);
}

/// The sheet's surface: soft top corners, the floating shadow (light
/// appearance) or raised surface (dark), a drag handle, a title, and the
/// content. It scrolls when the content is taller than the screen.
class SheetFrame extends StatelessWidget {
  const SheetFrame({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final s = t.sheet;
    final bottom =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: s.background,
        shape: s.shape,
        shadows: s.shadow,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          t.screen.edge,
          Spacing.besideIcon,
          t.screen.edge,
          t.screen.edge + bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: ShapeDecoration(
                  color: s.handle,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: Spacing.underSectionTitle),
            Semantics(header: true, child: Text(title, style: t.section.title)),
            SizedBox(height: t.section.titleGap),
            child,
          ],
        ),
      ),
    );
  }
}
