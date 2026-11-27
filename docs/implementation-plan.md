# Sahaay — Implementation Plan

## 1. Purpose

This document defines the staged implementation strategy for Sahaay v1.

The objective is to deliver a reliable application through coherent, independently verifiable increments rather than implementing the entire application in one large pass.

Product behavior and scope are defined by this plan (§11 lists what is out of scope), the architecture (`docs/architecture.md`), the design language (`docs/design-system.md`) and the decisions in `docs/adr/`.

This plan defines the order in which the application should be built.

## 2. Implementation principles

1. Inspect the existing repository before making implementation decisions.
2. Establish the foundation before building dependent features.
3. Implement business rules independently of presentation and platform APIs.
4. Complete meaningful vertical slices rather than creating extensive unfinished scaffolding.
5. Verify each increment before committing it.
6. Keep every commit focused, coherent, and suitable for pushing.
7. Do not introduce features or behavior outside the scope in §11.
8. Resolve blocking product decisions before implementing their dependent behavior.
9. Revisit this plan when repository findings or product decisions materially change the implementation sequence.

## 3. Phase 0 — Repository audit

### Objective

Understand the existing project before changing its structure or introducing dependencies.

### Activities

- Inspect the repository structure.
- Inspect `pubspec.yaml`, Flutter and Dart constraints.
- Inspect existing application entry points and initialization.
- Identify existing routing, state management, dependency management, and persistence approaches.
- Inspect platform-specific configuration, especially iOS.
- Inspect existing notification and photo-handling implementations, if any.
- Identify existing tests, analysis rules, and CI configuration.
- Review the current Git branch, working tree, and existing changes.
- Identify obsolete, duplicated, or unnecessary dependencies.
- Verify relevant decisions against current stable Flutter and Dart documentation.

### Deliverables

A concise repository assessment covering:

- Existing architecture.
- Existing technology choices.
- Structural problems, if any.
- Missing infrastructure.
- Recommended changes and their rationale.
- Risks and constraints.

### Completion criteria

- The existing project is understood.
- Existing user changes are preserved.
- Technology decisions are based on repository findings rather than assumptions.
- A concrete implementation sequence is agreed before major structural changes.

Do not rewrite the project merely to establish a preferred architecture.

---

## 4. Phase 1 — Application foundation

### Objective

Establish the application structure and shared infrastructure required by subsequent features.

### Scope

- Application initialization.
- Environment and configuration management, where necessary.
- Dependency composition.
- Navigation foundation.
- Global error handling.
- Logging strategy.
- Design-system foundations.
- Theme configuration.
- Shared layout and reusable UI primitives.
- Testing infrastructure.

### Design-system requirements

Implement the semantic design language defined in `docs/design-system.md`.

Start with:

- Typography roles.
- Colour roles.
- Layout and spacing foundations.
- Shape definitions.
- Theme configuration.
- Page layout.
- Page header.
- Content section.
- Common controls.

Do not attempt to build every possible reusable component upfront.

Introduce components when required by actual product screens.

### Completion criteria

- Application starts successfully.
- Theme configuration is centralized.
- Light and dark appearance work.
- Shared UI foundations are available.
- Navigation is functional.
- Analysis and baseline tests pass.
- Feature code can consume shared foundations without depending on concrete infrastructure implementations.

---

## 5. Phase 2 — Domain model and scheduling engine

### Objective

Implement the core product concepts and deterministic recurrence calculations independently of UI and platform notification APIs.

### Domain concepts

Implement the domain model:

#### Medicine

- Unique identity.
- Optional name.
- User-captured photo reference.
- Medicine form.
- Associated reminders.

#### Reminder

- Unique identity.
- Owning medicine identity.
- Exactly one time of day.
- Recurrence configuration.
- Required start date for recurring reminders.
- Optional end date.
- Optional user-provided quantity.
- Optional user-provided instruction.
- Independent pause state.

#### Recurrence

Support these recurrence patterns:

- One-time: specific date and time.
- Daily: every day or every N days.
- Weekly: selected weekdays or every N weeks.
- Monthly: selected dates or every N months.
- Yearly: selected month and date.

### Scheduling requirements

- Keep recurrence calculations independent of Flutter widgets.
- Use calendar-based calculations for monthly and yearly intervals.
- Distinguish calendar intervals from fixed-duration intervals.
- Respect start and end dates.
- Do not produce occurrences outside the reminder's active period.
- Preserve independent schedules for sibling reminders.
- Make calculations deterministic and testable with a controllable notion of current time.
- Avoid relying directly on system time throughout domain logic.

### Testing requirements

Cover:

- Every supported recurrence type.
- Interval-based recurrence.
- Weekday selection.
- Multiple selected dates.
- Start-date boundaries.
- End-date boundaries.
- Leap-year conditions.
- Months with different lengths.
- Independent reminder configurations.
- One-time reminders.
- Date and time boundary conditions.

### Month-end behavior

Resolved. If a month doesn't have the selected day, the reminder fires on that month's last day. Each month starts again from the originally selected day, so clamping never carries over. A yearly reminder on 29 February fires on 28 February in non-leap years.

### Completion criteria

- Domain models express the product's concepts and invariants.
- Recurrence calculations work independently of the UI and notification platform.
- Core scheduling tests pass.
- Tests cover month-end clamping for monthly and yearly reminders, including leap years.

---

## 6. Phase 3 — Local persistence and photo management

### Objective

Establish reliable local storage for medicines, reminders, and medicine photos.

### Scope

- Local database setup.
- Persistence models and mapping.
- Repository contracts and implementations.
- Medicine persistence.
- Reminder persistence.
- Medicine-photo storage.
- Database initialization and migration strategy.
- Deletion and cleanup behavior.

### Required behavior

- Medicine and reminder data persists across application restarts.
- Medicine and reminder relationships remain consistent.
- Reminder-specific configuration is persisted independently.
- Updating one reminder does not modify sibling reminders.
- Removing a medicine removes its associated reminders.
- Removing a medicine also removes its stored photo.
- Failed operations do not leave the database and photo storage in an inconsistent state.

### Engineering requirements

- Keep persistence concerns outside the domain layer.
- Avoid exposing database-specific models to presentation code.
- Handle database errors explicitly.
- Make data migrations predictable.
- Avoid unnecessary persistence abstractions.

### Testing requirements

- Create and retrieve medicines.
- Create multiple reminders for one medicine.
- Update individual reminders.
- Pause and resume individual reminders.
- Delete individual reminders.
- Delete a medicine and its associated reminders.
- Verify photo cleanup.
- Verify persistence across application restarts.
- Verify transactional consistency where required.

### Completion criteria

- Local persistence is functional.
- Repository behavior is independently tested.
- Medicine and reminder ownership rules are preserved.
- Photo lifecycle is handled consistently.

---

## 7. Phase 4 — Medicine management

### Objective

Implement the user's ability to create, view, and remove medicines.

### Scope

- Medicine collection screen.
- Add-medicine flow.
- Medicine details screen.
- Photo capture.
- Medicine form selection.
- Optional medicine name.
- Medicine removal and confirmation.

### Required behavior

- A user can create a medicine.
- A user can optionally provide its name.
- A user can capture its photo.
- A user can select oral/edible or injectable form.
- A medicine can have multiple reminders.
- A medicine can be removed with all associated data.

The medicine creation flow must support creating one or more reminders.

### UI requirements

- Follow the design language.
- Reuse shared components.
- Keep feature presentation separate from business logic.
- Handle loading, empty, and error states.
- Avoid introducing functionality deferred in §11.

Detailed home-screen and medicine-list design lives in `docs/design-system.md`. Implement the minimum functional collection experience without prematurely expanding its visual or functional scope.

### Completion criteria

- Medicine creation works end to end.
- Captured photos are persisted correctly.
- Medicine information is displayed correctly.
- Medicine removal cleans up associated data.
- Relevant acceptance criteria pass.

---

## 8. Phase 5 — Reminder management and scheduling UI

### Objective

Implement reminder creation and independent reminder management.

### Scope

- Reminder creation.
- Recurrence selection.
- Time selection.
- Start-date configuration.
- Optional end-date configuration.
- Optional quantity and instruction.
- Multiple reminders during medicine creation.
- Reminder details.
- Reminder editing.
- Reminder pausing and resuming.
- Reminder deletion.

### Required behavior

- Every reminder belongs to exactly one medicine.
- Each reminder has exactly one time.
- Each reminder has its own recurrence configuration.
- Reminder-specific information must remain independent.
- Editing, pausing, resuming, or deleting one reminder must not affect sibling reminders.
- Paused reminders must not generate notifications.
- Recurrence options must depend on the selected recurrence type.

### Completion criteria

- Users can create multiple independent reminders.
- All recurrence configuration options are represented.
- Reminder changes persist correctly.
- Individual reminder operations do not affect sibling reminders.
- Relevant acceptance criteria pass.

---

## 9. Phase 6 — Notification scheduling and delivery

### Objective

Integrate the deterministic scheduling model with local notification delivery.

### Scope

- Notification platform integration.
- Reminder-to-notification mapping.
- Notification scheduling.
- Notification identifiers.
- Rescheduling after reminder changes.
- Cancellation after deletion or pause.
- Notification content construction.
- Notification tap handling.
- Reconciliation after application/device lifecycle events where supported.

### Notification content

Notifications must:

- Be text only.
- Identify the associated medicine.
- Use a generic label when the medicine has no name.
- Include reminder-specific quantity or instruction when available.
- Correspond to the correct reminder.

### Scheduling requirements

- Schedule notifications according to recurrence calculations.
- Respect reminder start and end dates.
- Do not schedule notifications for paused reminders.
- Updating a reminder must replace its previous scheduled notifications correctly.
- Deleting a reminder must cancel its notifications.
- Deleting a medicine must cancel notifications for every associated reminder.
- Multiple reminders must remain independent.
- Persist enough information to reconstruct notification schedules.
- Handle application restarts and device reboot requirements supported by the platform.

### Notification navigation

Tapping a notification must open the dedicated entry screen for the corresponding reminder.

The screen must display:

- Medicine photo.
- Medicine form.
- Medicine information.
- Reminder-specific details.

The notification must identify the specific reminder, not merely its medicine.

### Product decisions

- Snooze is out of scope for v1. A notification can only be tapped (to open the reminder) or dismissed.
- Request notification permission when the user saves their first reminder. On Android, request exact-alarm permission at the same time.
- Permission-denied flows are deferred. Handle a denial without crashing or losing data, and build no further UX for it.

### Completion criteria

- Notifications are scheduled and cancelled correctly.
- Reminder-specific notification content is correct.
- Notification taps resolve to the correct reminder.
- Lifecycle and rescheduling behavior is verified.
- Notification behavior does not depend on the user keeping the application open.
- Relevant acceptance criteria pass.

---

## 10. Phase 7 — Integration and product hardening

### Objective

Validate complete application workflows and address integration failures.

### End-to-end scenarios

1. Create a medicine with multiple reminders.
2. Restart the application and verify persisted data.
3. Verify reminders remain independently configurable.
4. Edit one reminder and verify sibling reminders remain unchanged.
5. Pause one reminder and verify other reminders remain active.
6. Resume a paused reminder.
7. Delete one reminder and verify the medicine and sibling reminders remain intact.
8. Delete a medicine and verify all associated reminders and photos are removed.
9. Receive a notification and open the corresponding reminder.
10. Verify schedule boundaries and notification cancellation.

### Quality requirements

- Review error handling across features.
- Verify empty, loading, and failure states.
- Inspect database and photo lifecycle consistency.
- Verify recurrence calculations at calendar boundaries.
- Verify notification identifiers and lifecycle handling.
- Verify accessibility and text scaling.
- Verify light and dark appearance.
- Inspect performance and unnecessary rebuilds.
- Remove dead code, temporary scaffolding, and unused dependencies.
- Ensure application analysis and tests pass.

### Completion criteria

- Core workflows work end to end.
- Acceptance criteria are verified.
- No known critical data-integrity issues remain.
- No out-of-scope functionality has been introduced.
- Project checks pass.

---

## 10a. Phase 8 — Prints, Today and History

### Objective

Let the person record that they took a dose, see today's reminders on a time ruler, and look back at earlier days.

### Scope

- A `Print` record (reminder, day, time made), stored locally and deleted with its reminder or medicine.
- Making and undoing a print by holding the photo; only for due, unpaused reminders and earlier days.
- Today: the stepping time ruler.
- History: the flipbook and calendar of printed days, opening any day's ruler.

### Requirements

- Prints are created and removed only by the person's action. Nothing infers or scores them. Today shows how many of its reminders are printed; nothing else totals them.
- Prints never change reminders, schedules, notifications, or doses.
- The screens are built with the redesigned design system (`docs/design-system.md` §18); they wait for it.

### Completion criteria

- Making and undoing a print, Today's stepping, and History's views behave as described above.
- Domain tests cover which reminders can be printed on a day; persistence tests cover cascading deletes.

---

## 11. Product scope restrictions

The following must not be implemented as part of v1 unless this plan is explicitly revised:

- Accounts and authentication.
- Cloud sync.
- Backup and restore.
- Prescription generation or interpretation.
- Medical recommendations.
- Dosage calculation or validation.
- Drug interaction checking.
- Automatic medication schedule changes.
- Treatment completion inference.
- Inferred dose tracking (a dose counts as taken only when the person makes a print).
- Medication adherence analytics, scores, streaks, percentages, or "missed" warnings. (Today's count of printed reminders is allowed: it shows only the person's own prints.)
- Travel and time-zone handling.
- Caregiver functionality.
- Multilingual functionality.
- Snooze.

Do not interpret a technical convenience as authorization to expand product scope.

---

## 12. Incremental Git workflow

Implementation must proceed through meaningful, independently verifiable Git increments.

### Commit quality

A commit should represent a coherent unit of engineering work.

It should be:

- Focused.
- Functionally understandable.
- Verified.
- Reviewable.
- Suitable for pushing.

Avoid both extremes:

- Too minimal: commits containing trivial individual edits, arbitrary formatting changes, or incomplete implementation fragments.
- Too drastic: commits containing an entire large feature, unrelated modifications, or extensive unverified changes.

Group related changes when they form one meaningful implementation increment.

### Commit message format

Use:

`[tag]: short description`

Examples:

- `[chore]: establish application initialization and dependency composition`
- `[feat]: implement medicine and reminder domain models`
- `[feat]: add deterministic recurrence calculations`
- `[test]: cover monthly and yearly recurrence boundaries`
- `[feat]: implement local medicine persistence`
- `[fix]: preserve sibling reminders when updating a schedule`
- `[rework]: isolate notification scheduling behind infrastructure contracts`

Use an appropriate tag such as:

- `feat`
- `fix`
- `rework`
- `test`
- `docs`
- `chore`

Keep the commit description to one or two lines.

### Commit process

Before committing:

1. Verify the relevant implementation.
2. Run the applicable tests and analysis.
3. Review the complete staged diff.
4. Check that unrelated user changes are excluded.
5. Stage only files belonging to the increment.
6. Create the commit with the agreed message format.
7. Give me the commit command to run in your converstaion panel only.

After committing:

- Report the commit hash.
- Summarize the implementation.
- Report checks performed.
- Give push command and wait for implementing next meaningful commit

Do not amend, rebase, reset, force-push, or push without explicit instruction.

Do not create artificial commits just to increase commit count.

---

## 13. Definition of done

The application is ready for v1 completion when:

- Required functionality is implemented.
- All agreed product decisions have been resolved.
- Medicine and reminder data persist locally.
- Recurrence calculations are deterministic and tested.
- Notifications behave correctly within the supported platform constraints.
- Independent reminder operations preserve data integrity.
- Notification interactions open the correct reminder.
- The design system is consistently applied.
- Accessibility and responsive behavior have been verified.
- Relevant automated tests and static analysis pass.
- The Git history consists of meaningful, verified increments.
- No unresolved critical defects remain.

A phase is not complete merely because its UI has been implemented. Its underlying behavior, persistence, integration, and relevant tests must also be complete.
