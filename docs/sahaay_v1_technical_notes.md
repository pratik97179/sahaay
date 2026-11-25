# Sahaay v1 — Technical Notes (proposal)

Originally written as input for PRD 0.2 and updated for PRD 0.3. Where these notes disagree with the PRD, `docs/architecture.md` or `docs/adr/`, those documents win.

## 1. Data model

```
Medicine
  id            String (UUID)
  name          String?            // optional
  form          enum { oral, injectable }
  photoKey      String             // file name in app documents dir, not an absolute path (ADR 0001)
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
  quantity      String?                          // free text, never interpreted
  instruction   String?                          // free text, never interpreted
  isPaused      bool
  createdAt / updatedAt
```

Notes:
- Two-times-a-day = two `Reminder` rows (PRD §3.2).
- Months are atomic: "every N months" = add N calendar months to the start date's month; a missing day (31 in April, 29 Feb) clamps to the month's last day, and each month is computed from the originally selected day (no carry-over).
- Times are stored as local wall-clock time (date + minutes). Time zone handling is deferred.

## 2. Scheduling approach

Both OSes limit pending scheduled notifications (iOS: 64 per app; Android has soft limits plus exact-alarm rules). Long recurrences can't all be pre-scheduled.

Proposal: **rolling window**.
1. A pure Dart function `nextOccurrences(reminder, from, count)` computes upcoming fire times. Unit-test it heavily (month clamping, every-N weeks, end dates, leap years).
2. Schedule the next K occurrences across all active reminders (e.g. up to ~50 total, nearest first), each as a one-shot notification with payload `reminderId`.
3. Re-run "reschedule all" on: app launch/resume, any medicine/reminder change, device reboot, and when a notification fires/opens.
4. Pause/delete/edit = cancel that reminder's pending notifications, then reschedule.

Notification IDs: derive a stable int per (reminderId, occurrence) or keep a small local table mapping notification ID → reminderId.

## 3. Packages

The accepted choices are in `docs/adr/0001-technology-choices.md`: `flutter_riverpod`, `go_router` (route `/reminders/:id`), `drift`/`drift_flutter`, `image_picker` (camera only), `path_provider`, `flutter_local_notifications` + `timezone`, and `uuid` for IDs. Every package is added in the increment that first needs it. `flutter_timezone` and `permission_handler` aren't adopted. Add one only if `flutter_local_notifications` can't do the job on its own, and record the reason in an ADR.

Android specifics: `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS` (Android 13+). Expect some OEMs to kill alarms under battery optimisation; consider a later prompt to exempt the app.

## 4. Screens (minimum for v1)

1. Medicine list (home)
2. Add medicine (name, photo, form, reminder list)
3. Reminder editor (recurrence-dependent fields, time, start/end date, quantity, instruction)
4. Medicine detail (photo, reminders with pause/edit/delete, delete medicine)
5. Reminder entry screen (notification tap target: photo, form, time, quantity, instruction)

## 5. Snooze (decided: not in v1)

PRD 0.3 puts snooze out of scope for v1. If it comes back later, the design would be a notification action ("Snooze 10 min") that schedules one extra notification for the same reminder. The reminder's schedule stays the same, and nothing is recorded as taken or missed. The cost: handling the notification action even when the app has been killed, plus a background isolate entry point on Android.
