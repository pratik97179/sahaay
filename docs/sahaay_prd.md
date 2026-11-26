# Sahaay — Product Requirements Document (PRD)

**Version:** 0.4 (v1 scope)  
**Status:** Draft  
**Product:** Sahaay  
**Category:** Medication Reminders

**Changes in 0.4:** the person can record that they took a dose by making a *print* (§3.3, FR-11). The home screen is *Today*, a time ruler of the day's reminders (FR-12), and *History* shows past prints as a flipbook and a calendar (FR-13). Adherence analytics, scores and "missed" warnings remain out of scope (§7).

---

## 1. Product Overview

Sahaay is a medication reminder application that helps users remember to take medicines according to instructions they already have.

Users can add medicines, attach a photo for identification, and configure one or more independent reminders for each medicine. When a reminder is due, Sahaay sends a text notification. Tapping the notification opens that reminder's entry screen, where the medicine's photo and details are shown.

Users can also record, themselves, that they took a dose, and look back at those records day by day. Sahaay never infers that a dose was taken and never scores or judges it.

Sahaay is a reminder tool. It does not provide medical advice, prescribe medicines, or make decisions about dosage or treatment. It never changes, suggests or validates a dose.

All data is stored locally on the user's device.

## 2. Product Goals

1. Allow users to maintain a list of their medicines.
2. Allow multiple independent reminders for a single medicine.
3. Support flexible recurrence patterns for reminders.
4. Allow users to manage each reminder independently.
5. Make medicine identification easier through photos.
6. Keep the application focused on recording and reminding, not making medical decisions.
7. Let users record, in their own hand, that they took a dose, and look back at those records without judgement.

## 3. Core Concepts

### 3.1 Medicine

A medicine represents an item the user wants to create reminders for.

A medicine has:
- An optional name.
- A photo captured by the user with the device camera (required).
- A medicine form:
  - Oral / edible
  - Injectable
- Zero or more associated reminders. A medicine whose last reminder is deleted is kept and shows that it has no reminders.

The medicine is created once. Its associated reminders reuse the same medicine information and photo.

### 3.2 Reminder

A reminder represents an instruction to notify the user at **one** configured time.

Each reminder:
- Belongs to one medicine.
- Has exactly one time of day.
- Has its own schedule (recurrence, start date, optional end date).
- Can have its own optional quantity and optional instruction, entered by the user as two separate free-text fields.
- Can be edited, paused, or deleted independently.

Multiple reminders belonging to the same medicine must not interfere with one another.

**Multiple times per day:** a medicine taken more than once a day is modelled as multiple reminders. For example, "twice a day at 9:00 AM and 9:00 PM" is two reminders: one daily at 9:00 AM and one daily at 9:00 PM.

### 3.3 Print

A print is the person's own record that they took the dose for one reminder on one day.

A print has:
- The reminder it belongs to.
- The day it is for.
- The time the person made it.

A print exists only because the person made it. Sahaay never creates, infers or removes a print on its own, and a reminder without a print on a day is simply unprinted: it is never called "missed" or "late".

## 4. Functional Requirements

### FR-01: Add Medicine

The user must be able to:
- Add a medicine.
- Optionally provide its name.
- Capture a photo.
- Select its form: oral / edible or injectable.
- Create reminders for that medicine.

The user should be able to create multiple reminders during the medicine creation flow.

### FR-02: Add Multiple Reminders

A medicine can have multiple reminders.

For example, the same medicine may have:
- One reminder every day at 9:00 AM.
- Another reminder every day at 9:00 PM.
- Another reminder every Monday and Thursday at 8:00 PM.
- Another reminder every 15 days at 10:00 AM.

Each reminder must maintain its own configuration.

### FR-03: Configure Reminder Schedule

The application must support the following recurrence patterns:

| Recurrence | Configuration |
|---|---|
| One-time | Specific date and time |
| Daily | Every day or every N days |
| Weekly | Selected weekdays, optionally every N weeks |
| Monthly | Selected date(s), optionally every N months |
| Yearly | Selected month and date |

The schedule configuration must present only the options relevant to the selected recurrence pattern.

Each reminder must have its own schedule and configured time.

**Start and end dates:**
- Every recurring reminder must have a **start date** (required). Interval-based recurrences (every N days / weeks / months) count from the start date.
- An **end date** is optional. If set, no notifications are generated after it. If not set, the reminder repeats until paused or deleted.

**Month handling:**
- Monthly and yearly recurrences treat a month as an atomic calendar unit. "Every N months" advances by N calendar months from the start date's month, not by a fixed number of days.
- A selected day of the month fires on that day in every applicable month. If a month is shorter than the selected day, the reminder fires on that month's last day instead.
- Clamping never carries over: each month is computed from the originally selected day. Example for day 31: 31 Jan → 28 Feb (29 in a leap year) → 31 Mar → 30 Apr → 31 May.
- Selecting day 31 therefore means "the last day of every month".
- Yearly reminders follow the same rule: 29 February fires on 28 February in non-leap years.
- Weekly recurrence may combine selected weekdays with an every-N-weeks interval (e.g. Monday and Thursday every 2 weeks). Monthly recurrence may combine selected dates with an every-N-months interval.

### FR-04: Reminder-Specific Information

The user may enter, for an individual reminder, an optional quantity and an optional instruction. These are two separate free-text fields.

This information can differ between reminders belonging to the same medicine.

For example:
- Morning reminder: 1 tablet.
- Evening reminder: 2 tablets.

Sahaay only records what the user enters. It must not calculate, recommend, validate, or modify this information.

### FR-05: Send Notifications

When a reminder becomes due, the application must send a notification.

The notification must:
- Be text only (no photo or video).
- Identify the associated medicine (its name, or a generic label if no name was given).
- Include the reminder's quantity and instruction, if entered.
- Correspond to the specific reminder that became due.

Tapping the notification must open the dedicated entry screen for that reminder, showing the medicine's photo, form, and the reminder's details.

A medicine's multiple reminders must generate notifications according to their respective schedules.

### FR-06: Edit Reminder

The user must be able to edit an existing reminder.

Editing a reminder must affect only that reminder. Other reminders associated with the same medicine must remain unchanged.

### FR-07: Pause Reminder

The user must be able to temporarily pause an individual reminder.

A paused reminder must not generate notifications until it is resumed.

Pausing one reminder must not affect other reminders belonging to the same medicine.

### FR-08: Delete Reminder

The user must be able to delete an individual reminder.

Deleting a reminder must not delete its associated medicine or any sibling reminders.

### FR-09: Delete Medicine

The user must be able to remove a medicine.

Deleting a medicine must also delete all reminders associated with it and its stored photo.

### FR-10: Local Storage

All medicines, reminders, prints, and photos must be stored locally on the device. v1 has no account, server, or cloud sync.

### FR-11: Print a Reminder

The user must be able to record that they took a reminder's dose by making a print, and to undo it.

- A print is made by deliberately holding the medicine's photo; a quick tap does not make one, so it cannot happen by accident.
- A reminder can be printed once its time has come (from 30 minutes before it), and on any earlier day. Paused reminders, and reminders whose time is still to come, cannot be printed.
- Holding again undoes the print.
- The print records the time it was made, and that time is shown with it.
- Printing never changes the reminder, its schedule, its notifications, or any dose.

### FR-12: Today

The home screen shows today's reminders on a horizontal time ruler.

- The ruler opens on the next reminder still to come.
- Swiping steps to the next or previous reminder; the ruler never stops between reminders.
- The reminder under the ruler's centre shows its medicine photo, time, name, quantity and instruction, and whether it is printed.
- Tapping the photo opens that reminder's entry screen (FR-05).
- Today's ruler starts fresh each day. Earlier days are reached through History (FR-13).

### FR-13: History

The user must be able to look back at earlier days and their prints.

- History shows the current month as a flipbook of the days that have prints, each with its photo, date and number of prints, and as a calendar of the whole month, where days with prints show their photo.
- The user can switch between the two views.
- Opening a day shows that day's ruler with its reminders and prints, starting at its first reminder. Prints can be added or undone there (FR-11).
- History shows only what the person printed. It shows no totals, scores, streaks, percentages or "missed" days.

## 5. Core User Flows

### 5.1 Add Medicine and Create Reminders

1. User initiates the add-medicine flow.
2. User optionally enters a medicine name.
3. User captures a photo.
4. User selects the medicine form.
5. User creates one or more reminders.
6. For each reminder, the user configures its recurrence, time, start date, optional end date, and optional quantity and optional instruction.
7. User saves the medicine and its reminders.

### 5.2 Receive a Reminder

1. A configured reminder becomes due.
2. Sahaay sends a text notification identifying the medicine and reminder.
3. User taps the notification.
4. Sahaay opens that reminder's entry screen, showing the medicine photo and details.

### 5.3 Manage Reminders

1. User opens a medicine.
2. User views its associated reminders.
3. User selects an individual reminder.
4. User edits, pauses, resumes, or deletes that reminder.
5. Changes apply only to the selected reminder.

### 5.4 Remove a Medicine

1. User selects a medicine for removal.
2. User confirms the removal.
3. The medicine, its photo, all its associated reminders, and their prints are deleted.

### 5.5 Print a Reminder

1. A reminder's time comes, or the user opens it from Today or History.
2. User holds the medicine's photo.
3. Sahaay records a print with the time it was made, and shows it.
4. User may hold again to undo it.

### 5.6 Look Back

1. User opens History from Today.
2. User browses the month as a flipbook or a calendar.
3. User opens a day and sees that day's reminders and prints.

## 6. Business Rules and Constraints

1. A medicine can have multiple reminders.
2. Every reminder belongs to exactly one medicine.
3. Every reminder has exactly one time; multiple daily times are separate reminders.
4. Every reminder has an independently configurable schedule.
5. Every recurring reminder has a start date; the end date is optional.
6. Reminder-specific quantity and instruction must not be shared implicitly across sibling reminders.
7. Editing, pausing, or deleting one reminder must not affect sibling reminders.
8. Deleting a medicine removes all its reminders, their prints, and its photo. Deleting a reminder removes its prints.
9. The medicine photo belongs to the medicine and is reused by its reminders.
10. All data is stored locally on the device.
11. Sahaay must not make medical decisions or infer whether a treatment should continue or stop.
12. The user is responsible for entering and maintaining the reminder information.
13. Prints are made and undone only by the user. Sahaay never infers that a dose was taken.
14. Prints never change a reminder, its schedule, its notifications, or a dose.

## 7. Out of Scope (v1)

- Prescription generation or interpretation.
- Medical recommendations.
- Dosage calculation or validation.
- Drug interaction checking.
- Automatic changes to medication schedules.
- Deciding when a medicine should be discontinued.
- Automatic inference of treatment completion.
- Inferred dose tracking: deciding on the user's behalf that a dose was or wasn't taken.
- Adherence analytics, scores, streaks, percentages, or "missed"/"late" warnings.
- Video media, and media inside notifications.
- Cloud sync, accounts, backup and restore.
- Time zone and travel handling (deferred; see §10).
- Snooze.
- Picking a medicine photo from the gallery.

## 8. Acceptance Criteria

| ID | Expected Behaviour |
|---|---|
| AC-01 | A user can add a medicine with an optional name, a photo, and a medicine form. |
| AC-02 | A user can create multiple reminders for one medicine. |
| AC-03 | Each reminder supports the agreed recurrence patterns. |
| AC-04 | Each reminder keeps its own schedule, start date, optional end date, optional quantity, and optional instruction. |
| AC-05 | A due reminder produces a text notification for the correct medicine and reminder. |
| AC-06 | Tapping a notification opens that reminder's entry screen with the medicine photo. |
| AC-07 | Editing one reminder does not change other reminders. |
| AC-08 | Pausing one reminder stops only that reminder's notifications. |
| AC-09 | Deleting one reminder leaves the medicine and sibling reminders intact. |
| AC-10 | Deleting a medicine removes all its associated reminders and its photo. |
| AC-11 | No notifications are generated before a reminder's start date or after its end date. |
| AC-12 | A monthly or yearly reminder whose selected day is missing from a month fires on that month's last day, and the next month uses the originally selected day again. |
| AC-13 | All data persists locally across app restarts and device reboots. |
| AC-14 | The application does not calculate or recommend medical instructions. |
| AC-15 | Holding a due reminder's photo makes a print with the time it was made; holding again undoes it. A quick tap makes no print. |
| AC-16 | A reminder still to come, or a paused reminder, cannot be printed; a reminder on an earlier day can. |
| AC-17 | Sahaay never creates or removes a print without the user's action, and never labels an unprinted reminder "missed" or "late". |
| AC-18 | Today opens on the next reminder still to come, and swiping steps between reminders only. |
| AC-19 | History shows the month's printed days as a flipbook and a calendar, opens any day's ruler, and shows no totals or scores. |
| AC-20 | Deleting a reminder or medicine removes its prints. |

## 9. Open Product Decisions

None currently.

**Resolved:** Snooze is out of scope for v1. Notifications support tapping (opens the reminder) and dismissing only.

## 10. Deferred to Later Versions

- Time zone and daylight-saving behaviour when the user travels.
- Edit medicine (name, photo, form).
- Medicine list design details (the home screen is Today, FR-12).
- Notification permission-denied flows. v1 requests notification permission when the first reminder is saved; on Android it also requests exact-alarm permission.
- A "pause until" date.
- Multilingual support and caregiver features.
