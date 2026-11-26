import 'package:flutter/material.dart';

import '../../foundations/spacing.dart';
import '../../tokens/sahaay_tokens.dart';
import 'item_card.dart';

/// One reminder in a list (`docs/design-system.md` §11.2, §11.7): the time
/// leads in the identifying voice, then the schedule, then the quantity and
/// instruction.
///
/// A state such as "Paused" goes in [tag], at full contrast — the card is
/// never dimmed.
class TimeCard extends StatelessWidget {
  const TimeCard({
    required this.time,
    this.schedule,
    this.note,
    this.tag,
    this.onTap,
    super.key,
  });

  /// The time, already formatted for the user's locale and clock setting.
  final String time;

  /// How often it repeats, such as "Every Monday and Thursday".
  final String? schedule;

  /// The quantity and instruction, such as "1 tablet · after food".
  final String? note;

  /// A state tag shown beside the time.
  final Widget? tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay.timeCard;
    final schedule = this.schedule;
    final note = this.note;
    return CardSurface(
      background: t.background,
      pressedBackground: t.pressedBackground,
      shape: t.shape,
      padding: t.padding,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Spacing.besideIcon,
            runSpacing: Spacing.underLabel,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(time, style: t.time),
              ?tag,
            ],
          ),
          if (schedule != null) Text(schedule, style: t.schedule),
          if (note != null) Text(note, style: t.note),
        ],
      ),
    );
  }
}
