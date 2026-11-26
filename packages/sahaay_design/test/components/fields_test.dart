import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
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

/// A button that opens a sheet and keeps what it returned.
class Opener<T> extends StatefulWidget {
  const Opener(this.open, {super.key});

  final Future<T?> Function(BuildContext context) open;

  @override
  State<Opener<T>> createState() => OpenerState<T>();
}

class OpenerState<T> extends State<Opener<T>> {
  T? result;
  bool closed = false;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () async {
      final value = await widget.open(context);
      setState(() {
        result = value;
        closed = true;
      });
    },
    child: const Text('Open'),
  );
}

OpenerState<T> opener<T>(WidgetTester tester) =>
    tester.state<OpenerState<T>>(find.byType(Opener<T>));

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

const weekdays = [
  (1, 'Monday'),
  (2, 'Tuesday'),
  (3, 'Wednesday'),
  (4, 'Thursday'),
  (5, 'Friday'),
  (6, 'Saturday'),
  (7, 'Sunday'),
];

void main() {
  group('TextInputField', () {
    testWidgets('shows its label and placeholder', (tester) async {
      await pumpHost(
        tester,
        const TextInputField(label: 'Name', placeholder: 'Optional'),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
    });

    testWidgets('an error shows an icon, words and a brick outline', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const TextInputField(label: 'Quantity', errorText: 'Too long.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Too long.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      final border = decoration.enabledBorder! as OutlineInputBorder;
      expect(border.borderSide.color, SahaayTokens.light.field.errorOutline);
    });
  });

  group('PickerField', () {
    testWidgets('reads as a button with its label and value', (tester) async {
      var taps = 0;
      await pumpHost(
        tester,
        PickerField(
          label: 'Time',
          value: '9:00 AM',
          placeholder: 'Choose a time',
          icon: Icons.schedule,
          onTap: () => taps++,
        ),
      );
      final semantics = tester.getSemantics(
        find.descendant(
          of: find.byType(PickerField),
          matching: find.byType(InkWell),
        ),
      );
      expect(semantics.label, 'Time');
      expect(semantics.value, '9:00 AM');
      await tester.tap(find.text('9:00 AM'));
      expect(taps, 1);
    });

    testWidgets('shows the placeholder until a value is chosen', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const PickerField(
          label: 'Time',
          value: null,
          placeholder: 'Choose a time',
          icon: Icons.schedule,
          onTap: null,
        ),
      );
      expect(find.text('Choose a time'), findsOneWidget);
    });
  });

  group('Sheets', () {
    testWidgets('a sheet has a title and can be dismissed', (tester) async {
      await pumpHost(
        tester,
        Opener<String>(
          (context) => showChoiceSheet(
            context,
            title: 'Repeats',
            options: const [('daily', 'Daily'), ('weekly', 'Weekly')],
          ),
        ),
      );
      await open(tester);
      expect(find.text('Repeats'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10)); // the scrim
      await tester.pumpAndSettle();
      expect(find.text('Repeats'), findsNothing);
      expect(opener<String>(tester).closed, isTrue);
      expect(opener<String>(tester).result, isNull);
    });

    testWidgets('with reduced motion the sheet appears at once', (
      tester,
    ) async {
      await pumpHost(
        tester,
        Opener<String>(
          (context) => showChoiceSheet(
            context,
            title: 'Repeats',
            options: const [('daily', 'Daily')],
          ),
        ),
        reduceMotion: true,
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Daily'), findsOneWidget);
    });

    testWidgets('choice: tapping a row chooses it', (tester) async {
      await pumpHost(
        tester,
        Opener<String>(
          (context) => showChoiceSheet(
            context,
            title: 'Repeats',
            options: const [('daily', 'Daily'), ('weekly', 'Weekly')],
            selected: 'daily',
          ),
        ),
      );
      await open(tester);
      expect(
        tester.getSemantics(find.text('Daily')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      expect(opener<String>(tester).result, 'weekly');
    });

    testWidgets('weekdays: check several, then confirm', (tester) async {
      await pumpHost(
        tester,
        Opener<Set<int>>(
          (context) => showMultiChoiceSheet(
            context,
            title: 'On',
            doneLabel: 'Done',
            options: weekdays,
          ),
        ),
      );
      await open(tester);
      final done = find.widgetWithText(FilledButton, 'Done');
      expect(tester.widget<FilledButton>(done).onPressed, isNull);

      await tester.tap(find.text('Monday'));
      await tester.tap(find.text('Thursday'));
      await tester.pump();
      await tester.ensureVisible(done);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(opener<Set<int>>(tester).result, {1, 4});
    });

    testWidgets('days of the month: a grid of 31 with a footnote', (
      tester,
    ) async {
      await pumpHost(
        tester,
        Opener<Set<int>>(
          (context) => showDayOfMonthSheet(
            context,
            title: 'On days',
            doneLabel: 'Done',
            footnote: '31 means the last day of the month.',
            selected: const {1},
          ),
        ),
      );
      await open(tester);
      expect(find.text('31 means the last day of the month.'), findsOneWidget);
      await tester.tap(find.text('15'));
      await tester.tap(find.text('31'));
      await tester.pump();
      final done = find.widgetWithText(FilledButton, 'Done');
      await tester.ensureVisible(done);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(opener<Set<int>>(tester).result, {1, 15, 31});
    });

    testWidgets('calendar: done returns the date; no date is a choice', (
      tester,
    ) async {
      Future<void> pump() => pumpHost(
        tester,
        Opener<DateChoice>(
          (context) => showCalendarSheet(
            context,
            title: 'End date',
            doneLabel: 'Done',
            noDateLabel: 'No end date',
            initial: DateTime(2026, 11, 26),
            firstDate: DateTime(2026, 11, 1),
            lastDate: DateTime(2030),
            describe: (d) => 'Chosen ${d.day}/${d.month}/${d.year}',
          ),
        ),
      );

      await pump();
      await open(tester);
      expect(find.text('Chosen 26/11/2026'), findsOneWidget);
      await tester.tap(find.text('28'));
      await tester.pump();
      expect(find.text('Chosen 28/11/2026'), findsOneWidget);
      final done = find.widgetWithText(FilledButton, 'Done');
      await tester.ensureVisible(done);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(opener<DateChoice>(tester).result!.date, DateTime(2026, 11, 28));

      await open(tester);
      final noDate = find.text('No end date');
      await tester.ensureVisible(noDate);
      await tester.tap(noDate);
      await tester.pumpAndSettle();
      final result = opener<DateChoice>(tester).result!;
      expect(result.date, isNull);
    });

    testWidgets('time wheel: done returns the time shown', (tester) async {
      await pumpHost(
        tester,
        Opener<TimeOfDay>(
          (context) => showTimeWheelSheet(
            context,
            title: 'Time',
            doneLabel: 'Done',
            initial: const TimeOfDay(hour: 9, minute: 30),
          ),
        ),
      );
      await open(tester);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();
      expect(
        opener<TimeOfDay>(tester).result,
        const TimeOfDay(hour: 9, minute: 30),
      );
    });

    testWidgets('month and day: February offers the 29th', (tester) async {
      await pumpHost(
        tester,
        Opener<({int month, int day})>(
          (context) => showMonthDaySheet(
            context,
            title: 'Every year on',
            doneLabel: 'Done',
            monthNames: const [
              'January', 'February', 'March', 'April', 'May', 'June', //
              'July', 'August', 'September', 'October', 'November',
              'December',
            ],
            month: 2,
            day: 29,
          ),
        ),
      );
      await open(tester);
      expect(find.text('29'), findsOneWidget);
      expect(find.text('30'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();
      expect(opener<({int month, int day})>(tester).result, (
        month: 2,
        day: 29,
      ));
    });

    for (final dark in [false, true]) {
      testWidgets(
        'sheets fit 200% text on a small phone (${dark ? 'dark' : 'light'})',
        (tester) async {
          await pumpHost(
            tester,
            Opener<Set<int>>(
              (context) => showMultiChoiceSheet(
                context,
                title: 'Which days of the week',
                doneLabel: 'Done',
                options: weekdays,
              ),
            ),
            theme: dark ? SahaayTheme.dark() : null,
            textScale: 2,
            size: const Size(320, 640),
          );
          await open(tester);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
