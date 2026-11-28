// The reminder page reached from Today (docs/design-system.md §3), on
// real data.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahaay_design/sahaay_design.dart';

import '../../../core/navigation/navigation.dart';
import '../../prints/prints_providers.dart';
import '../../reminders/domain/calendar.dart';
import '../../reminders/presentation/schedule_text.dart';
import '../../reminders/reminders_destinations.dart';
import '../../reminders/reminders_providers.dart';
import 'day_data.dart';
import 'day_page.dart';
import 'day_widgets.dart';

/// A reminder opened from a day's ruler: its photo grows into the screen.
class DayReminderPage extends ConsumerStatefulWidget {
  const DayReminderPage({
    required this.day,
    required this.reminderId,
    super.key,
  });
  final LocalDate day;
  final String reminderId;
  @override
  ConsumerState<DayReminderPage> createState() => _DayReminderPageState();
}

class _DayReminderPageState extends ConsumerState<DayReminderPage> {
  // Set once going back, so a rebuild while closing doesn't go back twice.
  bool _leaving = false;

  @override
  Widget build(BuildContext context) {
    final now = nowOf(ref);
    final entries = ref.watch(dayEntriesProvider(widget.day)).value ?? [];
    final m = entries
        .where((e) => e.reminder.id == widget.reminderId)
        .firstOrNull;
    if (m == null) {
      // Deleted while open: go back to the day.
      if (!_leaving) {
        _leaving = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) AppNavigator.of(context).back();
        });
      }
      return const SizedBox.shrink();
    }
    final light = DayLight.screen;
    final marks = ref.watch(dayMarksProvider(widget.day));
    final taken = marks[m.reminder.id];
    final takenAt = taken == null
        ? null
        : clockText(context, taken.hour, taken.minute);
    final markable = canMark(m, widget.day, now);
    final schedule = describeSchedule(
      m.reminder.schedule,
      formatDate: (d) => formatDate(context, d),
    ).toLowerCase();
    return Scaffold(
      backgroundColor: light.page,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackLink(
                    widget.day == now.date
                        ? 'today'
                        : '${widget.day.day} '
                              '${monthName(widget.day.month).toLowerCase()}',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _weekdays[widget.day.weekday - 1],
                    style: figtree(18, FontWeight.w600, light.soft),
                  ),
                  Text(
                    '${clockText(context, m.reminder.schedule.time.hour, m.reminder.schedule.time.minute)}.',
                    style: figtree(
                      60,
                      FontWeight.w800,
                      light.ink,
                      height: 1.05,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Hero(
                      tag: 'photo${widget.day}-${m.reminder.id}',
                      child: HoldPhoto(
                        image: m.photo,
                        takenAt: takenAt,
                        canMark: markable,
                        onToggle: () => ref.read(togglePrintProvider)(
                          m.reminder,
                          widget.day,
                        ),
                        light: light,
                        radius: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    m.name,
                    style: figtree(
                      36,
                      FontWeight.w800,
                      light.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    m.paused ? 'Paused, won’t notify' : m.note,
                    style: figtree(21, FontWeight.w500, light.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    schedule,
                    style: figtree(17, FontWeight.w500, light.soft),
                  ),
                  const SizedBox(height: 22),
                  TakenNote(takenAt: takenAt, canMark: markable, light: light),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ref
                            .read(manageReminderProvider)
                            .setPaused(m.reminder.id, paused: !m.paused),
                        child: Text(
                          m.paused ? 'Resume' : 'Pause',
                          style: figtree(19, FontWeight.w700, light.ink),
                        ),
                      ),
                      const SizedBox(width: 36),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            AppNavigator.of(context)
                                .open(ReminderDestination(m.reminder.id)),
                        child: Text(
                          'Edit',
                          style: figtree(19, FontWeight.w700, light.ink),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _weekdays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];
