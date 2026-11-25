# Sahaay — Testing Strategy

## 1. Purpose

This document defines the testing strategy for Sahaay.

The objective is to catch regressions at the layer where they originate, verify product requirements independently, and maintain confidence as the application evolves.

Testing must not be treated as a final phase. It is part of implementation.

The strategy covers:

- Domain logic
- Application workflows
- Persistence
- Platform integrations
- Presentation
- End-to-end behavior

The PRD (`docs/sahaay_prd.md`) remains the source of truth for expected product behavior.

## 2. Testing principles

### 2.1 Test behavior, not implementation details

Tests should verify externally observable behavior and business invariants.

Avoid tests that pass only because internal methods or implementation details happen to remain unchanged.

### 2.2 Keep business logic independently testable

Domain behavior must be testable without:

- Flutter widget rendering.
- A real database.
- Real notification delivery.
- Platform-specific APIs.
- Network access.

### 2.3 Deterministic execution

Tests must not depend on the actual current time, random identifiers, notification delivery timing, or uncontrolled external state.

Use explicit inputs and controllable dependencies.

### 2.4 Test at the appropriate boundary

Use unit tests for isolated logic, integration tests for collaborating components, widget tests for UI behavior, and end-to-end tests for complete user workflows.

Do not use expensive end-to-end tests to verify every individual business rule.

### 2.5 Test failures and boundaries

Testing only successful flows is insufficient.

Cover invalid states, boundary dates, storage failures, unavailable permissions where applicable, and lifecycle-related behavior.

---

## 3. Test architecture

Tests should follow the production architecture.

Organize them around the code they verify rather than creating one large global test collection.

The exact directory structure should follow the repository's established conventions.

### 3.1 Domain tests

Verify:

- Entity behavior.
- Value object invariants.
- Recurrence calculations.
- Date and time calculations.
- Reminder state transitions.
- Medicine/reminder ownership rules.
- Independence of sibling reminders.

Domain tests must not require Flutter or infrastructure dependencies.

### 3.2 Application tests

Verify:

- Use-case behavior.
- Workflow coordination.
- Correct interaction with repository contracts.
- Error propagation.
- Transaction boundaries where applicable.
- Correct handling of independent reminder operations.

Use controllable implementations of dependencies.

### 3.3 Infrastructure tests

Verify:

- Database operations.
- Entity-to-persistence mapping.
- Repository implementations.
- Database migrations.
- Photo storage and deletion.
- Notification scheduling adapter behavior.
- Platform integration boundaries.

Test infrastructure against real local implementations where appropriate, using isolated test data and temporary storage.

### 3.4 Presentation tests

Verify:

- Correct rendering of product information.
- User interactions.
- Validation feedback.
- Loading, empty, and error states.
- Navigation behavior.
- Theme behavior.
- Accessibility-relevant behavior.

Avoid testing framework internals or duplicating domain tests through widgets.

### 3.5 Integration tests

Verify interactions between multiple application layers.

Examples:

- Creating a medicine and persisting its reminders.
- Updating a reminder and rescheduling its notifications.
- Pausing a reminder and cancelling its scheduled notifications.
- Deleting a medicine and cleaning up its associated data.
- Opening a reminder through a notification payload.

### 3.6 End-to-end tests

Verify critical complete user journeys using the application as a user would.

Prioritize:

- Medicine creation.
- Multiple reminder creation.
- Reminder management.
- Notification interaction.
- Medicine deletion.

Keep end-to-end tests focused on important product workflows.

---

## 4. Time and recurrence testing

Reminder scheduling is a critical part of Sahaay and requires particularly strong test coverage.

### 4.1 Control the current time

Never make recurrence tests depend directly on the machine's current clock.

Provide a controllable time source at the appropriate application boundary.

Tests must be able to specify the exact current date and time.

### 4.2 Recurrence test coverage

Test every recurrence pattern defined in the PRD.

| Recurrence | Required scenarios |
|---|---|
| One-time | Exact configured date and time; before and after the occurrence |
| Daily | Every day; every N days |
| Weekly | Selected weekdays; every N weeks |
| Monthly | Selected dates; every N months |
| Yearly | Selected month and date |

### 4.3 Calendar boundaries

Cover:

- Month transitions.
- Year transitions.
- Leap years.
- February date boundaries.
- Months with different numbers of days.
- Start dates at recurrence boundaries.
- End dates at recurrence boundaries.
- Interval calculations across calendar months.
- One-time schedules.
- Invalid recurrence configurations.

Do not substitute fixed-duration arithmetic for calendar-based calculations where the product requires calendar semantics.

### 4.4 Missing-date behavior

PRD v0.3 (FR-03, AC-12): if a month doesn't have the selected day, the reminder fires on that month's last day. The next month starts again from the originally selected day.

Cover:

- Monthly day 31 across a full year (for example 31 Jan → 28/29 Feb → 31 Mar → 30 Apr), showing that clamping never carries over.
- Monthly day 29 or 30 in February.
- Yearly 29 February in leap and non-leap years.
- Clamping combined with every-N-months intervals and with end dates.

### 4.5 Independence tests

Verify that multiple reminders belonging to one medicine maintain independent:

- Times.
- Recurrence configurations.
- Start dates.
- End dates.
- Instructions.
- Quantities.
- Pause states.

Changing one reminder must not change another.

---

## 5. Persistence testing

All product data is local to the device.

Persistence tests must verify the behavior of the actual selected storage implementation.

### Required scenarios

- Create and retrieve a medicine.
- Create multiple reminders for one medicine.
- Retrieve reminders belonging to a medicine.
- Update an individual reminder.
- Pause and resume an individual reminder.
- Delete an individual reminder.
- Delete a medicine and all its reminders.
- Verify data after reopening the database.
- Verify photo persistence and retrieval.
- Verify photo cleanup after medicine deletion.
- Verify data integrity when an operation fails.
- Verify schema migrations when the schema changes.

### Data integrity

Tests must verify:

- A reminder cannot become associated with the wrong medicine.
- Sibling reminders remain unchanged after individual operations.
- Deleting a medicine does not leave associated reminder records.
- Deleting a medicine does not leave its stored photo orphaned.
- Failed operations do not create inconsistent database and file-storage states.

Test transactional behavior wherever multiple operations must succeed or fail together.

---

## 6. Notification testing

Notification behavior must be tested independently of actual operating-system notification delivery.

### 6.1 Notification scheduling

Verify:

- Correct notification identity.
- Correct reminder-to-notification association.
- Correct occurrence date and time.
- Correct medicine identification.
- Correct quantity and instruction inclusion.
- Correct behavior for unnamed medicines.
- Correct handling of start and end dates.
- No scheduling for paused or deleted reminders.

### 6.2 Rescheduling

Verify that:

- Editing a reminder replaces its previous scheduled notifications.
- Pausing a reminder cancels its scheduled notifications.
- Resuming a reminder schedules future notifications again.
- Deleting a reminder cancels only its notifications.
- Deleting a medicine cancels notifications for all its reminders.
- Sibling reminders remain unaffected.

### 6.3 Notification interaction

Verify:

- Notification payload identifies the correct reminder.
- Notification payload identifies the associated medicine.
- Opening a notification resolves to the correct reminder entry.
- Missing or stale references are handled safely.

### 6.4 Platform integration

Test the platform adapter independently where practical.

Do not depend on real notification delivery for ordinary automated tests.

Platform-specific behavior must be verified through appropriate integration or manual testing on the actual supported environments.

---

## 7. Photo storage testing

Photos belong to medicines, not individual reminders.

Verify:

- Captured photo references are persisted.
- Photos can be retrieved after application restart.
- Multiple reminders reuse the same medicine photo.
- Replacing or removing a photo, if supported, maintains storage consistency.
- Deleting a medicine removes its associated photo.
- Storage failures are handled without leaving inconsistent references.

Do not use real personal photos in automated tests.

Use controlled test assets.

---

## 8. Presentation testing

Widget tests should verify user-visible behavior rather than internal rendering implementation.

### Important scenarios

- Empty medicine collection.
- Medicine list containing multiple medicines.
- Medicine details.
- Multiple reminders displayed for one medicine.
- Medicine creation form.
- Reminder creation form.
- Recurrence-specific form options.
- Reminder editing.
- Pause and resume actions.
- Reminder deletion.
- Medicine deletion confirmation.
- Loading and failure states.
- Long medicine names and instructions.
- Accessibility text scaling.
- Light and dark appearance.

### Interaction requirements

Verify that UI actions trigger the correct application operations.

Do not duplicate recurrence calculation tests inside widget tests.

The UI should consume the results of tested domain and application behavior.

---

## 9. Test data and fixtures

Test data must be explicit and predictable.

Use shared builders or fixtures for recurring test concepts such as:

- Medicines.
- Reminders.
- Recurrence configurations.
- Notification payloads.

Guidelines:

- Avoid large, implicit fixture setups.
- Keep test data relevant to the scenario.
- Avoid sharing mutable objects between unrelated tests.
- Use deterministic identifiers where identity matters.
- Use explicit date and time values.
- Reset persistent test data between isolated test cases.
- Avoid production data and personal information.

Do not create a complex test-data framework unless the test suite demonstrates a genuine need.

---

## 10. Dependency substitution

Use dependency substitution at architectural boundaries.

Examples:

- Controllable time source.
- In-memory repository implementations.
- Test notification scheduler.
- Temporary local photo storage.
- Controlled identifier generation where necessary.

Prefer small, purpose-built fakes or stubs over deeply nested mock configurations.

Do not introduce interfaces solely to make testing possible. The production architecture should already contain meaningful boundaries around infrastructure and external effects.

---

## 11. Test execution and verification

The exact test commands must be identified during repository audit.

At minimum, implementation increments should run the applicable checks:

- Static analysis.
- Relevant unit tests.
- Relevant integration tests.
- Relevant widget tests.
- Build verification when platform or dependency configuration changes.

Before committing:

1. Run the checks related to the changed code.
2. Verify that existing tests have not regressed.
3. Inspect failures rather than ignoring or suppressing them.
4. Review test coverage for the changed behavior.
5. Inspect the final diff.

Do not:

- Skip failing tests without documenting the reason.
- Weaken assertions merely to make tests pass.
- Introduce arbitrary delays to address asynchronous test failures.
- Depend on external services for tests that should be isolated.
- Claim test success without executing the relevant command.

---

## 12. Coverage expectations

Coverage percentages are not the primary measure of test quality.

Prioritize meaningful behavior coverage.

The following areas require particularly strong tests:

1. Recurrence calculations.
2. Date and time boundaries.
3. Reminder independence.
4. Persistence and deletion integrity.
5. Notification scheduling and cancellation.
6. Notification-to-reminder navigation.

A high percentage of covered lines does not compensate for missing critical scenarios.

---

## 13. Acceptance criteria traceability

Tests should be traceable to the PRD's acceptance criteria.

| PRD criteria | Primary verification |
|---|---|
| AC-01 | Medicine creation and persistence |
| AC-02 | Multiple reminder creation |
| AC-03 | Recurrence calculation and configuration |
| AC-04 | Independent reminder configuration and persistence |
| AC-05 | Notification content and delivery integration |
| AC-06 | Notification interaction and navigation |
| AC-07 | Reminder update isolation |
| AC-08 | Reminder pause and notification cancellation |
| AC-09 | Reminder deletion isolation |
| AC-10 | Medicine deletion and associated cleanup |
| AC-11 | Start and end date scheduling boundaries |
| AC-12 | Monthly and yearly month-end clamping without carry-over |
| AC-13 | Local persistence across restarts and device reboot |
| AC-14 | Absence of automated medical calculations or recommendations |

The exact test cases and their locations should evolve with implementation.

---

## 14. Out-of-scope testing

Do not introduce test infrastructure for product capabilities excluded from v1.

Examples:

- Cloud synchronization.
- Authentication.
- Backup and restore.
- Medical recommendations.
- Dosage calculation.
- Drug interaction analysis.
- Adherence analytics.
- Caregiver workflows.

Testing should remain proportional to the actual application.

---

## 15. Definition of done

A change is considered adequately tested when:

- Its relevant behavior is covered.
- Important boundary conditions are covered.
- Failure paths are considered.
- Dependencies are controlled where determinism is required.
- Existing relevant tests pass.
- Static analysis passes.
- No critical regression is known.
- The implementation and its tests are reviewed together.

A feature is not complete merely because its happy path works.
