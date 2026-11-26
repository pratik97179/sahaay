import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';
import 'package:widgetbook/widgetbook.dart';

/// A sample photo for catalogue use cases: an abstract gradient, not a
/// real medicine.
const samplePhoto = AssetImage('assets/sample_photo.png');

/// Bytes that are not an image, so the photo placeholder shows.
final brokenPhoto = MemoryImage(Uint8List.fromList(const [1, 2, 3]));

/// Long copy for checking wrapping at large text sizes.
const longText =
    'A medicine with an unusually long name that must wrap, never clip';

/// Hosts a component on the page background with the screen edge around
/// it. It has its own [ScaffoldMessenger] so snackbars appear inside the
/// device frame.
class Stage extends StatelessWidget {
  const Stage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: t.screen.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(t.screen.edge),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Screen.maxContentWidth,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A use case shown on a [Stage].
WidgetbookUseCase staged(String name, Widget Function(BuildContext) builder) =>
    WidgetbookUseCase(
      name: name,
      builder: (context) => Stage(child: Builder(builder: builder)),
    );

/// A knob that swaps in [longText], for checking wrapping.
extension LongTextKnob on BuildContext {
  String text(String label, String initial) =>
      knobs.boolean(label: 'Long $label')
      ? longText
      : knobs.string(label: label, initialValue: initial);
}
