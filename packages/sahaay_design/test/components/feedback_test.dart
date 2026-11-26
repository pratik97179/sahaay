import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_design/sahaay_design.dart';

Future<void> pumpHost(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  bool reduceMotion = false,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? SahaayTheme.light(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
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

/// Opens the delete confirmation and records the answer.
class DeleteButton extends StatefulWidget {
  const DeleteButton({super.key});

  @override
  State<DeleteButton> createState() => DeleteButtonState();
}

class DeleteButtonState extends State<DeleteButton> {
  bool? answer;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        onPressed: () async {
          final confirmed = await showConfirmDialog(
            context,
            title: 'Delete Test 2?',
            message:
                "This deletes the medicine, its photo and all of its "
                "reminders. This can't be undone.",
            confirmLabel: 'Delete',
            cancelLabel: 'Cancel',
          );
          setState(() => answer = confirmed);
        },
        child: const Text('Open'),
      ),
      TextButton(
        onPressed: () => showSahaaySnackbar(context, 'Reminder saved'),
        child: const Text('Save'),
      ),
    ],
  );
}

bool? answer(WidgetTester tester) =>
    tester.state<DeleteButtonState>(find.byType(DeleteButton)).answer;

void main() {
  final tokens = SahaayTokens.light;

  group('Tag', () {
    testWidgets('is an icon and a word on a neutral pill', (tester) async {
      await pumpHost(tester, const Tag(label: 'Paused', icon: Icons.pause));
      expect(find.text('Paused'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(Tag),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as ShapeDecoration).color, tokens.tag.background);
    });
  });

  group('ConfirmDialog', () {
    testWidgets('confirm is a filled brick button and returns true', (
      tester,
    ) async {
      await pumpHost(tester, const DeleteButton());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete'),
      );
      expect(
        confirm.style!.backgroundColor!.resolve({}),
        tokens.dialog.confirmBackground,
      );
      expect(
        confirm.style!.foregroundColor!.resolve({}),
        tokens.dialog.confirmLabel.color,
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(answer(tester), isTrue);
    });

    testWidgets('cancel and dismiss both return false', (tester) async {
      await pumpHost(tester, const DeleteButton());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(answer(tester), isFalse);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(answer(tester), isFalse);
    });

    testWidgets('with reduced motion it appears at once', (tester) async {
      await pumpHost(tester, const DeleteButton(), reduceMotion: true);
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Delete Test 2?'), findsOneWidget);
    });

    for (final dark in [false, true]) {
      testWidgets(
        'fits 200% text on a small phone (${dark ? 'dark' : 'light'})',
        (tester) async {
          await pumpHost(
            tester,
            const DeleteButton(),
            theme: dark ? SahaayTheme.dark() : null,
            textScale: 2,
            size: const Size(320, 568),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Snackbar', () {
    testWidgets('shows a quiet message', (tester) async {
      await pumpHost(tester, const DeleteButton());
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.backgroundColor, tokens.snackbar.background);
      expect(find.text('Reminder saved'), findsOneWidget);
    });
  });

  group('EmptyState and ErrorState', () {
    testWidgets('empty state: icon, message and an optional action', (
      tester,
    ) async {
      await pumpHost(
        tester,
        EmptyState(
          icon: Icons.medication_outlined,
          message: 'No medicines yet.',
          action: PrimaryButton(label: 'Add medicine', onPressed: () {}),
        ),
      );
      expect(find.text('No medicines yet.'), findsOneWidget);
      expect(find.text('Add medicine'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.medication_outlined));
      expect(icon.color, tokens.emptyState.icon);
    });

    testWidgets('error state is announced and uses the brick icon', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const ErrorState(message: "Your medicines couldn't be loaded."),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, tokens.errorState.icon);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.liveRegion ?? false),
        ),
        findsOneWidget,
      );
    });

    testWidgets('icons grow with text size', (tester) async {
      await pumpHost(
        tester,
        const EmptyState(icon: Icons.inbox, message: 'Nothing yet.'),
        textScale: 2,
      );
      final small = tokens.emptyState.message.fontSize! * 2.5;
      expect(tester.widget<Icon>(find.byIcon(Icons.inbox)).size, small * 2);
      expect(tester.takeException(), isNull);
    });
  });
}
