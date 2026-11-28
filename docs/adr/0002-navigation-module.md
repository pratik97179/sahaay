# ADR 0002 — Navigation as one module

**Status:** Accepted

## Context

Screens moved in three ways: go_router routes, which took the theme's lift; `Navigator.push` with a hand-made `PageRouteBuilder` (Today's reminder page faded and slid, History and an earlier day grew from the centre); and `context.go` / `pushReplacement`. Curves, timings and directions differed from screen to screen. Two screens were not routes at all, so they had no location. Every feature imported `app/routes.dart`, a dependency from features up to the app, and every new screen meant editing the shared `app/router.dart` and `app/routes.dart`, so two people adding screens would conflict.

## Decision

- `lib/core/navigation/` owns navigation. Widgets use only the `AppNavigator` contract (`open`, `replace`, `reset`, `back`, `overlay`), found with `AppNavigator.of(context)` through an inherited `NavigationScope`. go_router stays (ADR 0001), behind `GoRouterNavigator`.
- A screen is a typed `Destination` declared by its feature in `<feature>_destinations.dart`, and registered as a `ScreenRoute` in `<feature>_screens.dart` with its parent type. The screen table builds the go_router tree and every location from those lists and validates them at launch.
- The app composes one list per feature in `app/app_screens.dart`.
- Every screen uses the theme's screen change; no screen has its own route or transition. Back is one `BackLink` widget.
- `tool/check_navigation.sh` enforces the boundary alongside analyze.

## Alternatives rejected

- **One navigator method per screen** (`openMedicine(id)` …): the contract grows with every screen, so it becomes the file everyone edits.
- **go_router_builder typed routes:** the whole route tree is declared in one annotation, again a shared file, and calls still take a `BuildContext` per route class.
- **A navigator provider overridden in `main` and in tests:** a missing override fails only at runtime, and the router's start screen would have to move out of the app widget.

## Consequences

- Adding a screen touches only its own feature. The app's list changes only when a feature is added.
- Every screen has a location, so any of them can be opened from a notification.
- Wrong paths, parents and values fail at launch, and navigation outside the module fails the check.
- Today's reminder page lost its drag-down dismiss and History its grow-in: they now open and close like every other screen.
