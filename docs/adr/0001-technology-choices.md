# ADR 0001 — v1 technology choices

**Status:** Accepted (2026-11-25)

## Context

The repository started as the Flutter counter template (Flutter 3.47.9, Dart 3.13.7) with no routing, state management or persistence. `docs/architecture.md` asks for explicit dependencies, no service locator, testable boundaries and minimal packages.

## Decisions

| Need | Choice | Rationale |
|---|---|---|
| State and dependency composition | `flutter_riverpod` 3.x | Explicit, overridable providers give a single composition root and easy fakes in tests, without a global service locator. |
| Navigation | `go_router` 18.x | First-party package; path routes (`/reminders/:id`) give notification taps a stable deep-link target. |
| Local database | `drift` 2.x (SQLite) via `drift_flutter` | Typed queries, migrations, foreign-key cascades, transactions, and in-memory databases for tests. Photos are stored by key, not absolute path, because iOS container paths change. |
| Photo capture and storage | `image_picker` (camera only), `path_provider` | First-party packages. *(Added with the medicine screens.)* |
| Local notifications | `flutter_local_notifications` + `timezone` | The established local-notification plugin for Android and iOS scheduling. *(Added with the notification increment.)* |
| Design system | The `sahaay_design` package (`packages/sahaay_design/`) | Superseded: the design system's choices and their reasons are recorded in `docs/design-system.md` (§13.1 and §17), its single source of truth. |

## Platforms

Android and iOS only. The web target is not supported because local notifications and camera capture are required.

## Consequences

- Each package is added in the increment that first needs it, after checking compatibility with the current SDK.
- Domain code (`lib/features/*/domain`) depends on none of these packages.
