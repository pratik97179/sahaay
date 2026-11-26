import 'package:flutter/widgets.dart';

import '../../tokens/sahaay_tokens.dart';

/// A group of related content within a screen (`docs/design-system.md`
/// §3.2, §11.1).
///
/// Owns its title, the gap between the title and its content, and the gap
/// to the next section. Sections are separated by space, not borders.
class Section extends StatelessWidget {
  const Section({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  /// Names the group, such as "Reminders".
  final String title;
  final Widget child;

  /// An optional small widget at the end of the title line.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    return Padding(
      padding: EdgeInsets.only(bottom: t.screen.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: t.section.title),
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: t.section.titleGap),
          child,
        ],
      ),
    );
  }
}
