# ADR 0002 — Design system as a separate package

**Status:** Accepted (2026-11-26)

## Context

The first design system (`lib/design_system/`) mapped semantic roles onto a Material colour scheme generated from one seed colour. All of its values were placeholders. Its role names (`surfaceContainer`, `primaryValue`, `itemInset`) used framework and designer vocabulary, and nothing stopped feature code from using raw colours or sizes.

The v1 visual direction is now agreed and recorded in `docs/design-system.md`: warm paper surfaces, a sage accent used only for actions, danger as the only state colour, two typefaces, a spacious rhythm, soft continuous corners, a frosted top bar, and soft, purposeful motion. The design system is to be rebuilt from scratch rather than migrated, with tokens named for what they are for.

## Decisions

| Need | Choice | Rationale |
|---|---|---|
| Where the design system lives | A separate local package, `packages/sahaay_design/`, depended on by path | The compiler enforces the boundary: the package cannot import the app, and the app cannot reach its private `src/`. It can be built fresh without touching the existing code. |
| Layering | `foundations → tokens → theme → components`, with a single public barrel | Raw values stay private; features use components, component tokens and the shared `motion` group. |
| Token naming | Grouped by component (`card.background`, `timeCard.time`), each pointing to a shared value | Names say what a value is for, in plain words. The shared layer underneath keeps matching components from drifting apart. |
| Access | `context.sahaay`, backed by `ThemeExtension`s | Follows the theme, switches with light and dark, and rebuilds dependants. No separate runtime service is needed; `Theme` already provides one. |
| Domain | The package takes plain values (strings, images, callbacks), never `Medicine` or `Reminder` | Keeps the dependency direction one-way. Feature-specific items live in their feature. |
| Typefaces | Barlow Condensed (identifying voice) and Nunito (reading voice), both SIL Open Font License, bundled as font files in the package | Sahaay is local-only, so fonts must not be downloaded at runtime; `google_fonts` is not used. Bundling adds a few hundred KB. |
| Continuous corners | Flutter's built-in `RoundedSuperellipseBorder` | No package needed. |
| Component catalogue | Widgetbook as a separate app in `widgetbook/`, with use cases generated from annotations | Widgetbook never ships with the app. Generated use cases keep the catalogue in step with the components. |

## Options considered

- **A folder inside `lib/`.** Simpler, but the boundary would rest on convention and a test only.
- **A runtime design-system service** (Riverpod or an `InheritedWidget` beside `Theme`). Rejected: it duplicates `Theme`, and Material widgets would not read it.
- **Purpose-named shared tokens as the public API** (`colors.page`, `text.body`). Readable, but the component-grouped API was preferred.
- **Widgetbook inside the app package.** Rejected: it would make `widgetbook` a dependency of the shipped app.

## Consequences

- The repository gains a second pubspec (`packages/sahaay_design/`) and later a third (`widgetbook/`), each analysed and tested on its own.
- `widgetbook`, `widgetbook_annotation` and `widgetbook_generator` are added only when the catalogue is built, after checking compatibility with the current SDK.
- A test blocks raw colours, text styles and imports of the package's `src/` from feature code.
- Screens move to the new package one reviewed slice at a time; `lib/design_system/` is deleted once nothing uses it.
- The design-system row in ADR 0001 is superseded by this record.
