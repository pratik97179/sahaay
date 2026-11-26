import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_design/sahaay_design.dart';

Widget host(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  bool highContrast = false,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: theme ?? SahaayTheme.light(),
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      highContrast: highContrast,
      disableAnimations: reduceMotion,
    ),
    child: app!,
  ),
  home: child,
);

Screen screen({int sections = 6}) => Screen(
  title: 'Medicines',
  subtitle: 'For Test 2',
  children: [
    for (var i = 0; i < sections; i++)
      Section(title: 'Section $i', child: const SizedBox(height: 240)),
  ],
);

/// The title text inside the top bar.
Finder barTitle() =>
    find.descendant(of: find.byType(AppBar), matching: find.text('Medicines'));

double barTitleOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(of: barTitle(), matching: find.byType(AnimatedOpacity)),
    )
    .opacity;

void main() {
  group('Screen', () {
    testWidgets('shows the title once, as a header', (tester) async {
      await tester.pumpWidget(host(screen()));
      final semantics = tester.getSemantics(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('Medicines'),
        ),
      );
      expect(semantics.flagsCollection.isHeader, isTrue);
      expect(barTitleOpacity(tester), 0);
    });

    testWidgets('repeats the title in the top bar after it scrolls away', (
      tester,
    ) async {
      await tester.pumpWidget(host(screen()));
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(barTitleOpacity(tester), 1);

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(barTitleOpacity(tester), 0);
    });

    testWidgets('the top bar is frosted', (tester) async {
      await tester.pumpWidget(host(screen()));
      final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      expect(filter.filter, isA<ImageFilter>());
    });

    testWidgets('with high contrast, the top bar is solid', (tester) async {
      await tester.pumpWidget(host(screen(), highContrast: true));
      expect(find.byType(BackdropFilter), findsNothing);
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, SahaayTokens.light.topBar.solidBackground);
    });

    testWidgets('the title grows gently with large text', (tester) async {
      await tester.pumpWidget(host(screen(), textScale: 2));
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('Medicines'),
        ),
      );
      final max = SahaayTokens.light.screen.titleMaxScale;
      expect(title.textScaler!.scale(10), closeTo(10 * max, 0.001));
    });

    testWidgets('fits 200% text on a small phone without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          const Screen(
            title: 'A medicine with a very long name indeed',
            subtitle: 'For a reminder with a long description',
            children: [Section(title: 'Reminders', child: SizedBox())],
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('content is centred on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(screen()));
      final width = tester.getSize(find.byType(ListView)).width;
      expect(width, Screen.maxContentWidth);
    });

    testWidgets('works in dark appearance with reduced motion', (tester) async {
      await tester.pumpWidget(
        host(screen(), theme: SahaayTheme.dark(), reduceMotion: true),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(barTitleOpacity(tester), 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('Section', () {
    testWidgets('title is a header and is separated from content', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: Section(
              title: 'Reminders',
              child: SizedBox(key: Key('content'), height: 10),
            ),
          ),
        ),
      );
      final semantics = tester.getSemantics(find.text('Reminders'));
      expect(semantics.flagsCollection.isHeader, isTrue);

      final titleBottom = tester.getBottomLeft(find.text('Reminders')).dy;
      final contentTop = tester.getTopLeft(find.byKey(const Key('content'))).dy;
      expect(contentTop - titleBottom, SahaayTokens.light.section.titleGap);
    });
  });
}
