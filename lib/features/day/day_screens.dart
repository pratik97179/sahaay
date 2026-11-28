// Where the day feature's destinations sit and what they show
// (docs/architecture.md, Navigation).
import '../../core/navigation/screen_route.dart';
import '../reminders/domain/calendar.dart';
import 'day_destinations.dart';
import 'presentation/day_page.dart';
import 'presentation/day_reminder_page.dart';
import 'presentation/history_page.dart';

final List<ScreenRoute> dayScreens = [
  ScreenRoute<TodayDestination>(
    path: '/',
    parent: null,
    decode: (_) => const TodayDestination(),
    build: (_) => const DayPage(),
  ),
  ScreenRoute<HistoryDestination>(
    path: 'history',
    parent: TodayDestination,
    decode: (_) => const HistoryDestination(),
    build: (_) => const HistoryPage(),
  ),
  ScreenRoute<PastDayDestination>(
    path: ':date',
    parent: HistoryDestination,
    decode: (v) => PastDayDestination(LocalDate.parse(v['date']!)),
    encode: (d) => {'date': '${d.day}'},
    build: (d) => DayPage(day: d.day),
  ),
  ScreenRoute<DayReminderDestination>(
    path: 'days/:date/reminders/:id',
    parent: TodayDestination,
    decode: (v) => DayReminderDestination(
      day: LocalDate.parse(v['date']!),
      reminderId: v['id']!,
    ),
    encode: (d) => {'date': '${d.day}', 'id': d.reminderId},
    build: (d) => DayReminderPage(day: d.day, reminderId: d.reminderId),
  ),
];
