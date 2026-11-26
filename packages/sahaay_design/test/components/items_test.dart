import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_design/sahaay_design.dart';

/// A 1×1 transparent PNG.
final photo = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

/// Bytes that are not an image, so loading fails.
final brokenPhoto = MemoryImage(Uint8List.fromList(const [1, 2, 3]));

const longName =
    'A medicine with an unusually long name that must wrap, never clip';

/// Pumps [child] on a screen of [size] at [textScale].
Future<void> pumpHost(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? SahaayTheme.light(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
}

Color surfaceColor(WidgetTester tester, Finder within) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(of: within, matching: find.byType(AnimatedContainer)),
  );
  return (container.decoration! as ShapeDecoration).color!;
}

void main() {
  group('ItemCard', () {
    testWidgets('is one button that deepens its tint while pressed', (
      tester,
    ) async {
      var taps = 0;
      await pumpHost(
        tester,
        ItemCard(onTap: () => taps++, child: const Text('Test 2')),
      );
      final card = find.byType(ItemCard);
      final tokens = SahaayTokens.light.card;
      expect(surfaceColor(tester, card), tokens.background);

      final gesture = await tester.startGesture(tester.getCenter(card));
      await tester.pumpAndSettle();
      expect(surfaceColor(tester, card), tokens.pressedBackground);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(surfaceColor(tester, card), tokens.background);
      expect(tester.getSemantics(card).flagsCollection.isButton, isTrue);
    });

    testWidgets('without onTap it is not a button', (tester) async {
      await pumpHost(tester, const ItemCard(child: Text('Info')));
      expect(
        tester.getSemantics(find.byType(ItemCard)).flagsCollection.isButton,
        isFalse,
      );
    });
  });

  group('PhotoTile', () {
    testWidgets('reads as one button with its name and detail', (tester) async {
      await pumpHost(
        tester,

        PhotoTile(
          photo: photo,
          name: 'Test 2',
          detail: 'Injectable',
          onTap: () {},
        ),
      );
      final semantics = tester.getSemantics(find.byType(PhotoTile));
      expect(semantics.label, 'Test 2, Injectable');
      expect(semantics.flagsCollection.isButton, isTrue);
    });

    testWidgets('a photo that fails to load shows a placeholder', (
      tester,
    ) async {
      await pumpHost(
        tester,
        PhotoTile(photo: brokenPhoto, name: 'Test 2', onTap: () {}),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });
  });

  group('PhotoTileGrid', () {
    test('columns follow the room available', () {
      int columns(double width, double min) =>
          PhotoTileGrid.columnsFor(width: width, minTileWidth: min, gap: 16);
      expect(columns(342, 160), 2); // a phone at 100% text
      expect(columns(342, 320), 1); // the same phone at 200% text
      expect(columns(272, 160), 1); // a very narrow phone
      expect(columns(720, 160), 4); // a tablet
    });

    for (final (scale, expected) in [(1.0, 2), (2.0, 1)]) {
      testWidgets('shows $expected column(s) at ${scale * 100}% text', (
        tester,
      ) async {
        await pumpHost(
          tester,

          PhotoTileGrid(
            children: [
              for (var i = 0; i < 4; i++)
                PhotoTile(photo: photo, name: 'Medicine $i'),
            ],
          ),
          textScale: scale,
        );
        final first = tester.getTopLeft(find.byType(PhotoTile).at(0));
        final second = tester.getTopLeft(find.byType(PhotoTile).at(1));
        final sameRow = first.dy == second.dy;
        expect(sameRow ? 2 : 1, expected);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a long name wraps without overflow at 200% text', (
      tester,
    ) async {
      await pumpHost(
        tester,

        PhotoTileGrid(
          children: [
            PhotoTile(photo: photo, name: longName, detail: 'Oral / edible'),
          ],
        ),
        textScale: 2,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('TimeCard', () {
    testWidgets('shows the time, schedule, note and tag', (tester) async {
      await pumpHost(
        tester,

        TimeCard(
          time: '9:00 AM',
          schedule: 'Every Monday and Thursday',
          note: '1 tablet · after food',
          tag: const Text('Paused'),
          onTap: () {},
        ),
      );
      for (final text in [
        '9:00 AM',
        'Every Monday and Thursday',
        '1 tablet · after food',
        'Paused',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('a paused card keeps full contrast', (tester) async {
      await pumpHost(
        tester,
        const TimeCard(time: '9:00 AM', tag: Text('Paused')),
      );
      expect(find.byType(Opacity), findsNothing);
      expect(find.byType(AnimatedOpacity), findsNothing);
    });

    testWidgets('fits 200% text in dark appearance', (tester) async {
      await pumpHost(
        tester,

        const TimeCard(
          time: '11:37 AM',
          schedule: 'Every 2 weeks on Monday, Wednesday and Friday',
          note: '2 tablets · after food, with a full glass of water',
          tag: Text('Paused'),
        ),
        theme: SahaayTheme.dark(),
        textScale: 2,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('TakePanel', () {
    testWidgets('shows the photo, name and instruction', (tester) async {
      await pumpHost(
        tester,

        TakePanel(
          photo: photo,
          name: 'Test 2',
          instruction: '2 tablets · after food',
          photoSemanticLabel: 'Photo of Test 2',
        ),
      );
      expect(find.text('Test 2'), findsOneWidget);
      expect(find.text('2 tablets · after food'), findsOneWidget);
      expect(
        tester.widget<Image>(find.byType(Image)).semanticLabel,
        'Photo of Test 2',
      );
    });

    testWidgets('leaves out an empty instruction', (tester) async {
      await pumpHost(tester, TakePanel(photo: photo, name: 'Test 2'));
      final texts = tester.widgetList<Text>(find.byType(Text));
      expect(texts.map((t) => t.data), ['Test 2']);
    });

    testWidgets('fits a long name and 200% text', (tester) async {
      await pumpHost(
        tester,

        TakePanel(
          photo: photo,
          name: longName,
          instruction: '2 tablets · after food, with a full glass of water',
        ),
        textScale: 2,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
