import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stage.dart';

/// The shared language, shown through the public component tokens only.
final List<WidgetbookNode> foundations = [
  WidgetbookComponent(
    name: 'Text',
    useCases: [
      staged('Text roles', (context) {
        final t = context.sahaay;
        return _Specimens([
          ('Screen title', t.screen.title),
          ('Section title', t.section.title),
          ('Item name', t.photoTile.name),
          ('Time', t.timeCard.time),
          ('Field value', t.field.value),
          ('Row label', t.row.label),
          ('Button', t.button.label),
          ('Field label', t.field.label),
          ('Note', t.timeCard.note),
          ('Detail', t.photoTile.detail),
          ('Tag', t.tag.label),
        ]);
      }),
    ],
  ),
  WidgetbookComponent(
    name: 'Colour',
    useCases: [
      staged('Surfaces and accents', (context) {
        final t = context.sahaay;
        return _Swatches([
          ('Page', t.screen.background),
          ('Card', t.card.background),
          ('Card, pressed', t.card.pressedBackground),
          ('Sheet', t.sheet.background),
          ('Action', t.button.background),
          ('Action, pressed', t.button.pressedBackground),
          ('Danger', t.dialog.confirmBackground),
          ('Text', t.field.value.color!),
          ('Soft text', t.field.label.color!),
        ]);
      }),
    ],
  ),
];

class _Specimens extends StatelessWidget {
  const _Specimens(this.styles);

  final List<(String, TextStyle)> styles;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style) in styles) ...[
          Text(name, style: style),
          SizedBox(height: t.card.gap),
        ],
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches(this.colours);

  final List<(String, Color)> colours;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final style = t.field.value;
    // The swatch is sized from the text beside it, so it grows with it.
    final side = MediaQuery.textScalerOf(context).scale(style.fontSize! * 2.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (name, colour) in colours) ...[
          Row(
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: colour,
                  shape: t.field.shape.copyWith(
                    side: BorderSide(color: t.field.label.color!),
                  ),
                ),
                child: SizedBox.square(dimension: side),
              ),
              SizedBox(width: t.field.labelGap),
              Expanded(child: Text(name, style: style)),
            ],
          ),
          SizedBox(height: t.field.labelGap),
        ],
      ],
    );
  }
}
