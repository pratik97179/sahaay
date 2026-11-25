# Sahaay v1 — Technical Notes (proposal)

Input for the v1 PRD (0.2). Not final; meant to be revised as screens and features are refined.

## 1. Data model

```
Medicine
  id            String (UUID)
  name          String?            // optional
  form          enum { oral, injectable }
  photoPath     String             // file in app documents dir
  createdAt     DateTime
  updatedAt     DateTime

Reminder
  id            String (UUID)
  medicineId    String  -> Medicine.id (ON DELETE CASCADE)
  timeOfDay     int (minutes since midnight)   // one time per reminder
  recurrence    enum { once, daily, weekly, monthly, yearly }
  interval      int  (>= 1)                     // every N days/weeks/months
  weekdays      Set<int>?   (1=Mon..7=Sun)      // weekly only
  monthDays     Set<int>?   (1..31)             // monthly only
  yearMonth     int?        (1..12)             // yearly only
  yearDay       int?        (1..31)             // yearly only
  startDate     Date                             // required (= the date for "once")
  endDate       Date?                            // optional
  instruction   String?                          // free text, never interpreted
  isPaused      bool
  createdAt / updatedAt
```

Notes:
- Two-times-a-day = two `Reminder` rows (PRD §3.2).
- Months are atomic: "every N months" = add N calendar months to the anchor month; a missing day (31 in April, 29 Feb) clamps to the month's last day.
- Times are stored as local wall-clock time (date + minutes). Time zone handling is deferred.

## 2. Scheduling approach

Both OSes limit pending scheduled notifications (iOS: 64 per app; Android has soft limits plus exact-alarm rules). Long recurrences can't all be pre-scheduled.

Proposal: **rolling window**.
1. A pure Dart function `nextOccurrences(reminder, from, count)` computes upcoming fire times. Unit-test it heavily (month clamping, every-N weeks, end dates, leap years).
2. Schedule the next K occurrences across all active reminders (e.g. up to ~50 total, nearest first), each as a one-shot notification with payload `reminderId`.
3. Re-run "reschedule all" on: app launch/resume, any medicine/reminder change, device reboot, and when a notification fires/opens.
4. Pause/delete/edit = cancel that reminder's pending notifications, then reschedule.

Notification IDs: derive a stable int per (reminderId, occurrence) or keep a small local table mapping notification ID → reminderId.

## 3. Suggested packages

| Need | Package |
|---|---|
| Local notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone` |
| Local database | `drift` (SQLite, typed queries, migrations, cascade deletes). Alternative: `sqflite` for less tooling |
| Photo capture | `image_picker` (camera source only for v1) |
| File storage | `path_provider` (copy photo into app documents dir) |
| Permissions (notifications, exact alarms) | `permission_handler` |
| State management | `flutter_riverpod` (or keep it simple with `provider`) |
| Navigation + deep link from notification | `go_router` (route `/reminder/:id`) |
| IDs | `uuid` |

Android specifics: `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS` (Android 13+). Expect some OEMs to kill alarms under battery optimisation; consider a later prompt to exempt the app.

## 4. Screens (minimum for v1)

1. Medicine list (home)
2. Add medicine (name, photo, form, reminder list)
3. Reminder editor (recurrence-dependent fields, time, start/end date, instruction)
4. Medicine detail (photo, reminders with pause/edit/delete, delete medicine)
5. Reminder entry screen (notification tap target: photo, form, time, instruction)

## 5. Snooze (open decision)

If chosen: an Android/iOS notification action "Snooze 10 min" schedules a one-off notification for the same reminder; the reminder's schedule is not changed and nothing is recorded as taken/missed. Cost: notification action handling (including when the app is killed) and a background isolate entry point on Android. Recommendation: skip for v1, add later if users ask.

---
> **Status:** superseded where it conflicts with `docs/architecture.md`, the PRD (v0.3) or the decision records in `docs/adr/`. Kept for history.
