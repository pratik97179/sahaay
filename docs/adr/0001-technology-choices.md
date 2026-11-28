# ADR 0001 — v1 technology choices

**Status:** Accepted

## Context

Sahaay is a Flutter app (Flutter 3.47.9, Dart 3.13.7). `docs/architecture.md` asks for explicit dependencies, no service locator, testable boundaries and minimal packages.

## Decisions

| Need | Choice | Rationale |
|---|---|---|
| State and dependency composition | `flutter_riverpod` 3.x | Explicit, overridable providers give a single composition root and easy fakes in tests, without a global service locator. |
| Navigation | `go_router` 18.x | First-party package; path routes (`/reminders/:id`) give notification taps a stable deep-link target. |
| Local database | `drift` 2.x (SQLite) via `drift_flutter` | Typed queries, migrations, foreign-key cascades, transactions, and in-memory databases for tests. Photos are stored by key, not absolute path, because iOS container paths change. |
| Photo capture and storage | `image_picker` (camera only), `path_provider` | First-party packages. |
| Local notifications | `flutter_local_notifications` 23.x + `timezone` + `flutter_timezone` | The established local-notification plugin for Android and iOS scheduling; `flutter_timezone` gives the device's zone so repeats keep their local time. Needs Android core-library desugaring and compileSdk 37+. |
| Design system | The `sahaay_design` package (`packages/sahaay_design/`) | Holds the shared design pieces; `docs/design-system.md` describes the design. |

## Platforms

Android and iOS only. The web target is not supported because local notifications and camera capture are required.

## Consequences

- Domain code (`lib/features/*/domain`) depends on none of these packages.
