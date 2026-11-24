# Sahaay — Product Requirements Document (PRD)

**Version:** 0.2 (v1 scope)  
**Status:** Draft  
**Product:** Sahaay  
**Category:** Medication Reminders

---

## 1. Product Overview

Sahaay is a medication reminder application that helps users remember to take medicines according to instructions they already have.

Users can add medicines, attach a photo for identification, and configure one or more independent reminders for each medicine. When a reminder is due, Sahaay sends a text notification. Tapping the notification opens that reminder's entry screen, where the medicine's photo and details are shown.

Sahaay is a reminder tool. It does not provide medical advice, prescribe medicines, or make decisions about dosage or treatment.

All data is stored locally on the user's device.

## 2. Product Goals

1. Allow users to maintain a list of their medicines.
2. Allow multiple independent reminders for a single medicine.
3. Support flexible recurrence patterns for reminders.
4. Allow users to manage each reminder independently.
5. Make medicine identification easier through photos.
6. Keep the application focused on recording and reminding, not making medical decisions.

## 3. Core Concepts

### 3.1 Medicine

A medicine represents an item the user wants to create reminders for.

A medicine has:
- An optional name.
- A photo captured by the user.
- A medicine form:
  - Oral / edible
  - Injectable
- One or more associated reminders.

The medicine is created once. Its associated reminders reuse the same medicine information and photo.

### 3.2 Reminder

A reminder represents an instruction to notify the user at **one** configured time.

Each reminder:
- Belongs to one medicine.
- Has exactly one time of day.
- Has its own schedule (recurrence, start date, optional end date).
- Can have its own quantity or instruction entered by the user.
- Can be edited, paused, or deleted independently.

Multiple reminders belonging to the same medicine must not interfere with one another.

**Multiple times per day:** a medicine taken more than once a day is modelled as multiple reminders. For example, "twice a day at 9:00 AM and 9:00 PM" is two reminders: one daily at 9:00 AM and one daily at 9:00 PM.

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
| Weekly | Selected weekdays or every N weeks |
| Monthly | Selected date(s) or every N months |
| Yearly | Selected month and date |

The schedule configuration must present only the options relevant to the selected recurrence pattern.

Each reminder must have its own schedule and configured time.

**Start and end dates:**
- Every recurring reminder must have a **start date** (required). Interval-based recurrences (every N days / weeks / months) count from the start date.
- An **end date** is optional. If set, no notifications are generated after it. If not set, the reminder repeats until paused or deleted.

**Month handling:**
- Monthly and yearly recurrences treat a month as an atomic calendar unit. "Every N months" advances by N calendar months, not by a fixed number of days.
- If a selected date does not exist in a given month (e.g. the 31st in April, or 29 February in a non-leap year), the reminder fires on the last day of that month. *(Proposed; confirm.)*

### FR-04: Reminder-Specific Information

The user may enter a quantity or instruction for an individual reminder.

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
- Include the reminder's quantity or instruction, if entered.
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

All medicines, reminders, and photos must be stored locally on the device. v1 has no account, server, or cloud sync.

## 5. Core User Flows

### 5.1 Add Medicine and Create Reminders

1. User initiates the add-medicine flow.
2. User optionally enters a medicine name.
3. User captures a photo.
4. User selects the medicine form.
5. User creates one or more reminders.
6. For each reminder, the user configures its recurrence, time, start date, optional end date, and any optional quantity or instruction.
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
3. The medicine, its photo, and all its associated reminders are deleted.

## 6. Business Rules and Constraints

1. A medicine can have multiple reminders.
2. Every reminder belongs to exactly one medicine.
3. Every reminder has exactly one time; multiple daily times are separate reminders.
4. Every reminder has an independently configurable schedule.
5. Every recurring reminder has a start date; the end date is optional.
6. Reminder-specific quantity or instructions must not be shared implicitly across sibling reminders.
7. Editing, pausing, or deleting one reminder must not affect sibling reminders.
8. Deleting a medicine removes all its reminders and its photo.
9. The medicine photo belongs to the medicine and is reused by its reminders.
10. All data is stored locally on the device.
11. Sahaay must not make medical decisions or infer whether a treatment should continue or stop.
12. The user is responsible for entering and maintaining the reminder information.

## 7. Out of Scope (v1)

- Prescription generation or interpretation.
- Medical recommendations.
- Dosage calculation or validation.
- Drug interaction checking.
- Automatic changes to medication schedules.
- Deciding when a medicine should be discontinued.
- Automatic inference of treatment completion.
- Dose tracking or medication adherence analytics.
- Video media, and media inside notifications.
- Cloud sync, accounts, backup and restore.
- Time zone and travel handling (deferred; see §10).

## 8. Acceptance Criteria

| ID | Expected Behaviour |
|---|---|
| AC-01 | A user can add a medicine with an optional name, a photo, and a medicine form. |
| AC-02 | A user can create multiple reminders for one medicine. |
| AC-03 | Each reminder supports the agreed recurrence patterns. |
| AC-04 | Each reminder keeps its own schedule, start date, optional end date, and optional quantity or instruction. |
| AC-05 | A due reminder produces a text notification for the correct medicine and reminder. |
| AC-06 | Tapping a notification opens that reminder's entry screen with the medicine photo. |
| AC-07 | Editing one reminder does not change other reminders. |
| AC-08 | Pausing one reminder stops only that reminder's notifications. |
| AC-09 | Deleting one reminder leaves the medicine and sibling reminders intact. |
| AC-10 | Deleting a medicine removes all its associated reminders and its photo. |
| AC-11 | No notifications are generated before a reminder's start date or after its end date. |
| AC-12 | A monthly reminder on a date missing from a month fires on that month's last day. |
| AC-13 | All data persists locally across app restarts and device reboots. |
| AC-14 | The application does not calculate or recommend medical instructions. |

## 9. Open Product Decisions

**Notification interaction (snooze):** Whether a notification supports only tapping and dismissing, or also offers a "Snooze" action button (e.g. remind again in 10 minutes). Snooze would delay only that one occurrence and would not change the reminder's schedule. This decision does not introduce dose tracking or a mark-as-taken workflow.

## 10. Deferred to Later Versions

- Time zone and daylight-saving behaviour when the user travels.
- Edit medicine (name, photo, form).
- Home screen and medicine list design details.
- Notification permission and permission-denied flows.
- A "pause until" date.
- Multilingual support and caregiver features (mentioned in the README, not in this PRD).
