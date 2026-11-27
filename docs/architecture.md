# Sahaay — Architecture

## Purpose

This document defines architectural constraints for Sahaay.

Before changing or extending the architecture, inspect the existing repository and follow sound established patterns unless there is a concrete reason to change them.

## Architectural goals

- Keep the application local-first, reliable, and testable.
- Separate product behavior from Flutter widgets, platform APIs, and persistence details.
- Keep feature-specific logic owned by its feature.
- Isolate cross-cutting capabilities behind narrow contracts.
- Avoid unnecessary layers, abstractions, and dependencies.

## Logical layers

Use these logical boundaries where they provide value. Do not create empty folders or boilerplate solely to match this list.

### Presentation

Owns screens, widgets, navigation integration, and presentation state.

- Renders application state and forwards user actions.
- Must not own persistence, recurrence calculations, or notification scheduling rules.
- Must not depend directly on concrete infrastructure implementations.

### Application

Owns use cases and workflows that coordinate domain behavior and infrastructure contracts.

- Coordinates operations such as creating a medicine with reminders or updating a reminder.
- Defines application-level orchestration and error handling.
- Must not contain widget-specific behavior.

### Domain

Owns product concepts, invariants, and deterministic business rules.

- Models medicines, reminders, and recurrence schedules.
- Enforces rules such as reminder ownership and independent reminder configuration.
- Contains no Flutter, platform, database, or notification-plugin dependencies.
- Keeps recurrence and date calculations deterministic and independently testable.

### Infrastructure

Implements persistence, notification delivery, photo storage, and platform-specific integrations.

- Implements contracts owned by the appropriate inner layer.
- Keeps plugin and platform details behind narrow adapters.
- Does not decide product behavior or bypass domain invariants.

## Feature boundaries

Organize code around product capabilities rather than placing all files of the same technical type in one global directory.

Potential feature ownership includes:

- Medicines: medicine details, photo reference, and medicine lifecycle.
- Reminders: reminder configuration, independent management, and recurrence behavior.
- Prints: the person's own record that a reminder's dose was taken on a day, and the Today and History views that read them.
- Notifications: platform delivery and notification interaction integration.

Treat these as starting boundaries, not mandatory packages. Adjust them to the repository and actual use cases.

A feature must not reach into another feature's internal implementation. When coordination is needed, use an application workflow or an explicit contract.

## Cross-cutting capabilities

Cross-cutting code may include persistence coordination, notification scheduling coordination, logging, and shared error handling.

- Keep each capability focused and give it a clear owner.
- Do not use a global service locator as a substitute for explicit dependencies.
- Avoid a shared “common” module that becomes a home for unrelated logic.
- Share code only when the behavior and ownership are genuinely shared.

## Contracts and dependencies

- Define contracts at boundaries where they enable isolation, substitution, or meaningful testing.
- Do not create an interface for every class.
- Keep dependency direction inward: presentation → application → domain.
- Infrastructure may depend on inner-layer contracts and implement them; inner layers must not depend on infrastructure.
- Compose concrete implementations at the application's composition boundary.
- Make dependencies explicit and avoid hidden global state.

## Persistence and local data

- All product data remains on-device.
- Keep persistence mapping separate from domain behavior.
- Preserve medicine/reminder ownership and independent reminder configuration.
- Deleting a medicine must remove its associated reminders, their prints, and its photo. Deleting a reminder removes its prints.
- A print is stored only from the person's own action; nothing in the app creates or removes one on its own.
- Handle photo files and database records consistently; avoid leaving orphaned files or references.
- Persist enough schedule information to deterministically reconstruct future notifications.
- Do not add cloud sync, accounts, or backup/restore without a product-scope change.

## Reminder scheduling and notifications

- Treat recurrence calculation as deterministic domain behavior.
- Keep platform notification APIs behind an infrastructure boundary.
- Keep notification scheduling coordination separate from recurrence calculation and presentation.
- Ensure edits, pauses, resumes, and deletions affect only the selected reminder, except when deleting a medicine and its associated data.
- Prevent notifications before a reminder's start date or after its end date.
- Make notification identifiers and rescheduling behavior stable and testable.
- Do not infer that a notification was seen or that a medicine was taken. A dose counts as taken only when the person makes a print.
- Prints never change a reminder's schedule or its notifications.

When a selected monthly or yearly date doesn't exist in a month, the reminder fires on that month's last day. The clamping doesn't carry over to later months. This is domain behavior: implement and test it there.

## Testing

- Unit-test domain rules and recurrence calculations without Flutter or platform dependencies.
- Test application workflows using controllable contract implementations.
- Test persistence mapping and repository behavior independently.
- Test notification scheduling through a controllable adapter rather than relying on real notification delivery.
- Cover date boundaries, recurrence edge cases, and independent reminder operations.
- Add widget or integration tests where they verify meaningful user flows or platform integration.

## Technology decisions

Do not select or introduce a state-management library, database, routing package, dependency-injection framework, or notification plugin based only on this document.

First inspect the current project, identify its constraints, and verify current stable Flutter/Dart guidance. Record consequential technology choices and their rationale in a separate architecture decision record when needed.
