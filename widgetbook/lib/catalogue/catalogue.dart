import 'package:widgetbook/widgetbook.dart';

import 'actions.dart';
import 'feedback.dart';
import 'fields.dart';
import 'foundations.dart';
import 'items.dart';
import 'layout.dart';

/// The catalogue tree, in the order of `docs/design-system.md` §14.1.
/// Written by hand: add a use case here whenever a component is added or
/// changes.
final List<WidgetbookNode> catalogue = [
  WidgetbookFolder(name: 'Foundations', children: foundations),
  WidgetbookFolder(name: 'Layout', children: layout),
  WidgetbookFolder(name: 'Items', children: items),
  WidgetbookFolder(name: 'Fields', children: fields),
  WidgetbookFolder(name: 'Actions', children: actions),
  WidgetbookFolder(name: 'Feedback', children: feedback),
];
