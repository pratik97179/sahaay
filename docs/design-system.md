# Sahaay — Design Language

## 1. Purpose

Sahaay has its own design language.

The objective is to make UI development intuitive and consistent without requiring developers to remember concrete visual values.

Developers should not need to decide the font size, weight, spacing, corner radius, or colour of every element.

They should understand what the element represents and use the corresponding design-system role or component.

The design system defines:

- Content hierarchy
- Typography
- Colour semantics
- Layout and spacing
- Shapes and geometry
- Elevation
- Motion
- Iconography
- Interaction states
- Reusable components

All concrete visual values are implementation details maintained centrally.

## 2. Design principles

### 2.1 Meaning before appearance

A visual decision must communicate something.

Examples:

- A page heading identifies the current destination.
- A section heading identifies a group of related content.
- An item heading identifies an entity.
- Supporting text provides additional context.
- Metadata communicates secondary information.
- An action communicates an available operation.

These distinctions determine typography, emphasis, spacing, and component behaviour.

### 2.2 Components own their appearance

A developer using a MedicineCard should not have to configure its typography, padding, shape, and colours.

The component owns these decisions.

A developer should only provide the information and behaviour relevant to that component.

### 2.3 Consistent visual relationships

Two elements serving the same purpose should look and behave consistently.

A section heading should not have different styling on different screens without a deliberate design decision.

### 2.4 Accessibility by default

Accessibility is a property of the design system, not something each feature must independently implement.

Account for text scaling, colour contrast, touch targets, focus visibility, and reduced motion.

### 2.5 Visual direction (v1)

Sahaay is calm, quiet and spacious. Many users are older, unwell, tired or anxious, and often open the app at the moment a reminder fires. The interface must never hurry or startle them.

- **Warm paper.** Soft warm surfaces in light and dark appearances; no cold or tinted near-black.
- **Two voices.** A bold, large, condensed face for the few things that identify (page, section and item headings, and times); a softer, rounded reading face for everything else.
- **One gentle accent.** A muted sage, used only for actions.
- **Nothing looks urgent unless it is.** Only errors and destructive actions use a state colour.
- **More space than feels necessary.** Sections are separated by space and soft tints, not borders.
- **No medical judgement.** No adherence, "missed", "late" or health colours anywhere.

The concrete values are recorded in §4–§9, component behaviour in §11.7, token names in §11.8, and the code structure in §13.1.

---

## 3. Content hierarchy

The content hierarchy is the foundation of the entire design language.

Every screen must follow this model.

### 3.1 Page

A Page represents one complete navigable destination.

Examples:

- Medicines
- Add Medicine
- Medicine Details
- Edit Reminder

A page has one primary heading that identifies its purpose.

It owns:

- Overall screen layout
- Screen-level insets
- Primary heading
- Arrangement of sections
- Screen-level actions

A page must not contain arbitrary collections of unrelated elements without a defined content structure.

### 3.2 Section

A Section is a logically independent group of related information or interactions within a page.

A section must have a clear purpose that can be expressed through a heading.

Examples on the Medicine Details page:

- Medicine Information
- Reminders

Examples on the Add Medicine page:

- Medicine Details
- Reminder Schedule

A section owns:

- Its heading
- Its content
- Its internal layout
- Its spacing from neighboring sections

A section may contain multiple items, fields, or components.

A card is not automatically a section.

A section does not necessarily require a card or bordered container.

### 3.3 Item

An Item is an individual entity or entry presented within a section.

Examples:

- An individual medicine in a medicine list.
- An individual reminder in the Reminders section.
- An individual entry in any other collection.

An item owns the presentation of its entity-specific information.

An item may contain:

- A primary identifier
- Supporting information
- Metadata
- Actions

### 3.4 Field

A Field represents an individual attribute of an entity.

Examples:

- Medicine name
- Medicine form
- Start date
- End date
- Quantity
- Instruction

A field may be editable or read-only.

An editable field generally contains:

- Field label
- Input control
- Optional supporting information
- Optional validation feedback

The label must remain visually distinguishable from the entered value.

### 3.5 Supporting content

Supporting content provides additional context about another element.

Examples:

- A description below a medicine name.
- A recurrence explanation.
- Helper text below an input.
- A secondary description accompanying a reminder.

Supporting content must remain subordinate to the element it describes.

### 3.6 Metadata

Metadata communicates secondary contextual information that does not represent the primary content.

Examples:

- Schedule recurrence
- Last modified information
- Secondary timestamps
- Non-primary status information

Metadata must remain visually subordinate and must not compete with important content.

### 3.7 Actions

Actions represent operations available to the user.

Examples:

- Add medicine
- Edit reminder
- Pause reminder
- Resume reminder
- Delete medicine

Actions have an explicit interaction hierarchy:

- Primary action: the main operation expected in the current context.
- Secondary action: an alternative or supporting operation.
- Destructive action: an operation that removes or irreversibly changes data.
- Inline action: an operation associated with a particular item.

---

## 4. Typography

Typography follows the content hierarchy.

Do not select typography based on arbitrary widget names or manually configured numeric values.

Sahaay has two voices:

- **Barlow Condensed** — the identifying voice. Bold, large and condensed. Used only for screen, section and item titles, and for times.
- **Nunito** — the reading voice. Softer, rounded and wider. Used for everything else.

Both are bundled as font files inside the design-system package. They are not downloaded at runtime.

### 4.1 Shared text styles

These are the design system's internal text styles. Components use them; feature code reaches them only through component tokens (§11.8). Sizes are in logical points at 100% text size, and will be fine-tuned in the component catalogue.

| Style | Meaning | Face and weight | Size | Example |
|---|---|---|---|---|
| `screenTitle` | Names the current screen | Barlow Condensed ExtraBold | 48 | Medicines |
| `sectionTitle` | Names a group of related content | Barlow Condensed Bold | 28 | Reminders |
| `itemTitle` | Names one thing in a collection | Barlow Condensed Bold | 24 | Paracetamol |
| `time` | A time that matters | Barlow Condensed Bold | 34 | 9:00 AM |
| `body` | Normal reading text and entered values | Nunito Medium | 18 | After food |
| `bodyStrong` | Reading text that must stand out | Nunito Bold | 18 | 2 tablets |
| `note` | Explains or qualifies something | Nunito Regular | 16 | Every Monday and Thursday |
| `label` | Names a field | Nunito SemiBold | 16 | Start date |
| `detail` | Secondary information | Nunito Regular | 15 | Injectable |
| `button` | Names an action | Nunito Bold | 17 | Save reminder |
| `tag` | Names a state | Nunito Bold | 15 | Paused |

### 4.2 Typography contracts

Each style represents a complete text style.

Its implementation defines:

- Font family
- Font size
- Font weight
- Line height
- Letter spacing
- Text scaling behaviour

The relationships between the styles must remain consistent.

The hierarchy is:

1. Screen title
2. Section title
3. Item title
4. Time or strong body text
5. Body text
6. Notes
7. Details

This is a hierarchy of visual emphasis, not a rule that every screen must use all seven levels.

### 4.3 Typography rules

- A screen has one screen title.
- Section titles must be subordinate to the screen title.
- Item titles must be subordinate to their section title.
- A time may receive stronger emphasis than an item title when it is the main information being communicated.
- Labels must remain distinguishable from their values.
- Notes and details must not compete with primary content.
- Important information must not depend on font weight or size alone.
- Line height is about 1.1 for condensed styles and about 1.5 for Nunito styles.
- Titles use a warm off-black; notes and details a softer warm grey. Never pure black.
- Condensed text is never set in all capitals.
- Every style follows the user's text size setting. Reading styles scale fully to at least 200%. `screenTitle` scales more gently (capped near 1.6×) and wraps; text never clips.
- No text is smaller than 15.

Do not create new text styles for individual screens. Introduce one only when a real content category cannot be represented by the existing hierarchy.

---

## 5. Colour language

Colours are defined by what they are for.

Do not select a colour because it looks appropriate in isolation.

### 5.1 Direction

- **Warm paper.** Light: a soft warm off-white page, with cards one clear warm step deeper. Dark: a warm charcoal (not near-black), with cards one clear lighter warm step. Surfaces are defined on their own, not derived from a seed colour.
- **One gentle accent: sage.** A low-saturation green, mid-dark in light (about `#4F6F5F`) and soft and pale in dark (about `#A9C4B4`). Used only for actions, selection and focus — never for status, doses or decoration.
- **One state colour: danger.** A muted brick (about `#9A4A3C` light, `#E3A597` dark), used only for errors and destructive actions. There are no success, warning or information colours in v1: paused, saved and informational states use text colours with an icon and words. Add a state colour only when a real case needs it (§15).

### 5.2 Shared colours

These are the design system's internal colours. Components use them; feature code reaches them only through component tokens (§11.8).

| Colour | Meaning |
|---|---|
| `page` | The screen background |
| `card` | A card or grouped area on the page |
| `cardPressed` | A card while it is being pressed |
| `raised` | The one stronger surface on a screen, such as the take panel |
| `field` | The background of an editable field |
| `text` | Main readable text |
| `textSoft` | Notes, details and labels |
| `textDisabled` | Text that cannot currently be used |
| `action` | The background of a primary action, and selection |
| `actionPressed` | A primary action while it is being pressed |
| `onAction` | Text and icons on `action` |
| `danger` | Errors and destructive actions (text, icons, outlines) |
| `focus` | The visible focus ring |
| `scrim` | The dimmed layer behind sheets and dialogs |
| `shadow` | The soft shadow under floating things (light appearance only) |

### 5.3 Colour rules

- Colours keep their meaning across the entire application.
- Light and dark appearances resolve the same names.
- Components must not select arbitrary palette shades.
- All text and icon pairs meet WCAG AA (4.5:1 for text), checked in both appearances.
- Colour must reinforce hierarchy, not replace it. Do not communicate a state with colour alone.
- No colour is ever used to judge a dose or a treatment.

---

## 6. Layout and spacing

Spacing communicates relationships between elements.

Instead of exposing arbitrary spacing values to feature developers, spacing is defined by the relationship between the elements.

### 6.1 Shared spacing

A spacious rhythm on a 4-point grid. These are internal; components own them (§6.2).

| Spacing | Meaning | Value |
|---|---|---|
| `screenEdge` | Between the screen edge and its content | 24 |
| `betweenSections` | Between two independent sections | 64 |
| `underSectionTitle` | Between a section title and its content | 20 |
| `betweenItems` | Between sibling items | 16 |
| `insideCard` | Between a card's edge and its content | 24 |
| `betweenFields` | Between adjacent fields | 28 |
| `underLabel` | Between a field label and its control | 8 |
| `besideIcon` | Between an icon and its text, or related inline elements | 12 |

Spacing does not grow with text size in v1; revisit if testing at 200% shows crowding.

### 6.2 Spacing ownership

| Element | Owner |
|---|---|
| Screen margins | Screen |
| Separation between sections | Section |
| Title-to-content spacing | Section |
| Internal card padding | Card component |
| Separation between list entries | List or grid |
| Label-to-control spacing | Field component |
| Control-to-error spacing | Field component |
| Icon-to-label spacing | Interactive component |

Feature code composes layouts rather than specifying padding and margins.

### 6.3 Layout rules

- Related elements must appear visually grouped.
- Independent content groups are separated by space and soft surface tints, not borders.
- Internal component spacing must remain consistent.
- Avoid unnecessary nested padding.
- Avoid using arbitrary empty containers to create visual gaps.
- Layout must adapt to available screen space.

---

## 7. Shapes and geometry

Shapes communicate component identity and interaction. Developers select the appropriate component rather than configure its corner radius.

Soft and round, with continuous (superellipse) corners everywhere:

| Shape | Used for | Radius |
|---|---|---|
| `card` | Cards and grouped areas | 24 |
| `panel` | The take panel | 24 |
| `field` | Editable fields | 16 |
| `photo` | Medicine photos | 20 |
| `dialog` | Dialogs | 32 |
| `sheet` | Bottom sheets | 32 (top corners) |
| `button`, `chip`, `tag` | Buttons, compact choices, state tags | fully rounded |

Avoid shape overrides inside features. Add a shape only when a meaningful visual distinction exists.

---

## 8. Elevation and depth

Depth shows which things sit above others. Shadows are never decoration.

| Depth | Used for | Treatment |
|---|---|---|
| `flat` | Cards and panels | A warm surface step only; no shadow |
| `frost` | The top bar | A translucent, frosted material over scrolling content. Solid page colour when high contrast is on. |
| `floating` | Dialogs, sheets, the add action | One soft, wide, low-opacity warm shadow. In dark appearance, a lighter surface instead. |

---

## 9. Motion language

Motion communicates transitions and changes in application state. Things people do many times a day stay still or nearly still.

Motion is the one shared token group that feature code may use directly (`context.sahaay.motion`):

| Token | Used for | Duration | Curve |
|---|---|---|---|
| `motion.press` | Press feedback (a tint change) | 100 ms | ease-out |
| `motion.appear` | Content appearing (an error, a tag) | 200 ms | strong ease-out, `Cubic(0.23, 1, 0.32, 1)` |
| `motion.disappear` | Content leaving | 150 ms | ease-in |
| `motion.expand` | Content opening | 250 ms | ease-out; grows from its own edge |
| `motion.collapse` | Content closing | 250 ms | ease-out |
| `sheet.spring` | Sheets and dialogs | spring | critically damped (no bounce); tracks the finger; interruptible |

Page transitions use the platform default.

Rules:

- Every motion has a purpose: feedback, orientation or continuity. Never decoration.
- Press feedback is a tint change, not a ripple or a scale.
- Nothing animates from scale 0, and nothing moves linearly.
- Exits are faster than entrances.
- With reduced motion on (`MediaQuery.disableAnimationsOf`), every movement becomes a short cross-fade or an instant change. The tokens resolve this themselves.
- Functionality never depends on an animation completing.

---

## 10. Iconography

Maintain one consistent icon language.

Define icon usage by context:

- Navigation icons
- Action icons
- Status icons
- Informational icons
- Inline icons

Rules:

- Maintain consistent visual weight.
- Align icons with their associated content.
- Provide accessible descriptions for icon-only actions.
- Avoid using icons as ambiguous substitutes for text.
- Do not mix unrelated icon families.

---

## 11. Component system

Reusable components are the main interface to the design system. A component encapsulates its typography, spacing, shape, colours and interaction states.

Components take plain values — strings, images and callbacks — and never the app's domain types (`Medicine`, `Reminder`). Features pass their data in.

### 11.1 Layout

- `Screen` — the screen background, side insets, screen title and optional subtitle, and the frosted top bar that repeats the title once it scrolls away.
- `Section` — a section title, its content, and the gap to the next section.

### 11.2 Items

- `Card` — a pressable card on the page.
- `PhotoTile` — a medicine in the grid: a square photo, then its name and form.
- `TimeCard` — a reminder in a list: its time, schedule, note and an optional state tag.
- `TakePanel` — the raised panel at the top of a reminder screen: photo, name, quantity and instruction.

### 11.3 Fields

- `TextField` — a labelled text input.
- `PickerField` — a labelled field that opens a picker sheet.
- Picker sheets: time wheel, choice rows, weekday rows, day-of-month grid, month calendar, month-and-day wheel.

### 11.4 Actions

- `PrimaryButton` — the single filled sage pill for a form's main action.
- `ActionRow` — a full-width row with an icon and a label.
- `SwitchRow` — a row with a switch and an optional state note.
- `DangerRow` — a destructive row, alone in its own group.

### 11.5 Feedback

- `Tag` — a neutral state label with an icon and a word.
- `ConfirmDialog` — confirms a destructive action.
- `Snackbar` — a quiet confirmation such as "Reminder saved".
- `EmptyState` and `ErrorState`.

### 11.6 Component rules

- Avoid wrappers that merely rename existing framework components.
- Build reusable components when they enforce consistency or encapsulate meaningful behaviour.
- Keep variants intentional and limited.
- Components consume only the design system's own tokens.
- Feature code does not override a component's visual decisions without a documented reason.

### 11.7 Behaviour decisions (v1)

**Actions**

- Each form has one primary action: a filled sage pill.
- Other actions on a detail screen are full-width rows (56 pt or taller) with an icon and a label, such as "Edit reminder ›".
- Pause and resume is a "Notify me" switch row. When it is off, the row says "Paused — won't notify until you turn it back on".
- The destructive action sits alone in its own group at the bottom, as a brick-coloured row, and always asks for confirmation.

**Medicine grid**

- Square photo tiles, with the condensed name and the form below each.
- The number of columns follows the room available: a tile never gets narrower than a minimum width that grows with text size (about 160 pt × text scale). Phones show one or two columns; wider screens show more.
- Names wrap and are never cut off. An unnamed medicine shows the generic label.

**Reminder card**

- The time leads. Below it: the schedule, then the quantity and instruction.
- A paused reminder shows a neutral "Paused" tag with an icon and the word. It is never dimmed.

**Reminder screen** (also the notification entry screen)

1. The take panel: photo, name, quantity and instruction.
2. After a section gap, the schedule.
3. Then the action rows.

No "missed", "late" or snooze. An empty quantity or instruction is simply left out.

**Pickers** — every picker opens from a field in a bottom sheet:

| Field | Picker |
|---|---|
| Time | A wheel; follows the device's 12- or 24-hour setting. |
| Repeat type | Choice rows. |
| Weekdays | Full-name check rows. |
| Days of the month | A 7-column grid; 31 is explained as "last day of the month". |
| Dates | A month calendar with the full chosen date shown. |
| Yearly | A month-and-day wheel. |
| End date | Offers "No end date"; nothing before the start date can be chosen. |

### 11.8 Component tokens

Tokens are grouped by the component they belong to, and read as `context.sahaay.<component>.<part>`. Each one points to a shared value from §4–§9, so two components that should match cannot drift apart.

| Component | Tokens |
|---|---|
| `screen` | `background`, `edge`, `title`, `subtitle`, `sectionGap` |
| `topBar` | `frost`, `solidBackground`, `title`, `icon` |
| `section` | `title`, `titleGap` |
| `card` | `background`, `pressedBackground`, `shape`, `padding`, `gap` |
| `photoTile` | `photoShape`, `name`, `detail`, `minWidth`, `gap` |
| `timeCard` | `time`, `schedule`, `note`, `background`, `pressedBackground`, `shape`, `padding` |
| `takePanel` | `background`, `shape`, `padding`, `photoShape`, `name`, `instruction` |
| `field` | `label`, `labelGap`, `background`, `value`, `placeholder`, `icon`, `shape`, `gap`, `errorText`, `errorOutline` |
| `button` | `background`, `pressedBackground`, `label`, `shape`, `minHeight`, `disabledBackground`, `disabledLabel` |
| `row` | `background`, `pressedBackground`, `label`, `icon`, `chevron`, `minHeight`, `groupGap` |
| `switchRow` | `trackOn`, `trackOff`, `thumb`, `stateNote` |
| `dangerRow` | `label`, `icon` |
| `tag` | `background`, `label`, `icon`, `shape` |
| `sheet` | `background`, `shape`, `handle`, `scrim`, `shadow`, `spring` |
| `dialog` | `background`, `shape`, `title`, `message`, `scrim`, `shadow` |
| `snackbar` | `background`, `message` |
| `emptyState` | `icon`, `message` |
| `errorState` | `icon`, `message` |
| `focus` | `ring` |
| `motion` | `press`, `appear`, `disappear`, `expand`, `collapse` (§9) |

Example (illustration):

```dart
final t = context.sahaay;
Text(time, style: t.timeCard.time);
```

Names describe what something is for, in plain words. Never name a token after how it looks (`blueAccent`, `headingBold`) or after a framework's internal vocabulary (`surfaceContainerHigh`).

---

## 12. Responsive design

Responsive behaviour depends on available layout space, not assumptions about device models.

Define layout environments:

- Compact: constrained available content width.
- Regular: comfortable content width.
- Expanded: sufficient space for more complex arrangements.

The system must preserve hierarchy across environments.

Rules:

- Respect system insets.
- Avoid unnecessary fixed dimensions.
- Allow text to wrap.
- Maintain touch targets of at least 48 pt.
- Support accessibility text scaling.
- Do not stretch content indefinitely on wide screens.

---

## 13. Theme architecture

Themes determine how tokens resolve.

Support:

- Light appearance
- Dark appearance
- System appearance preference

The token names remain unchanged across appearances. Feature code must not contain raw visual values or branch on appearance.

### 13.1 Code architecture

The design system is its own Dart package, `packages/sahaay_design/`, with its own `pubspec.yaml`. The app and the Widgetbook catalogue depend on it by path. It is built fresh and does not depend on the app or on the earlier `lib/design_system/`.

Layers, each depending only on the ones above it:

```text
packages/sahaay_design/
  lib/
    src/foundations/  raw values: palette, font families, radii, durations (private)
    src/tokens/       shared values (§4–§9) and component tokens (§11.8), light and dark
    src/theme/        ThemeData and Material component themes built from the tokens
    src/components/   layout/, items/, fields/, actions/, feedback/
    sahaay_design.dart  public API: the theme, `context.sahaay`, and the components
  fonts/              Barlow Condensed and Nunito
```

Rules:

- **Public API.** Only `sahaay_design.dart` is imported from outside. Foundations and shared values stay private; feature code uses components, component tokens and the shared `motion` group.
- **Access.** Tokens are read through `context.sahaay`. They are carried in `ThemeExtension`s, so they follow the theme, switch with light and dark, and rebuild dependants.
- **Accessibility inside the tokens.** Reduced motion, high contrast (the solid top bar) and text scaling are resolved by the design system, not by features.
- **No domain types.** The package never imports the app. Feature-specific items (for example, a medicine tile built from a `Medicine`) live in their feature and are composed from design-system components.
- **Enforcement.** A test fails if code under `lib/features/` imports `sahaay_design/src/`, or uses `Color(`, `Colors.`, `fontSize:` or `TextStyle(`. An exception needs a comment explaining why.
- **Migration.** Screens move to the new package one reviewed slice at a time. The old `lib/design_system/` is deleted once nothing uses it.

---

## 14. Implementation constraints

1. Define UI structure using the Page → Section → Item → Field hierarchy (§3). The `Screen` component implements a Page.
2. Use components and component tokens according to content meaning.
3. Do not create text styles inside feature widgets.
4. Do not use raw colours or palette values in features.
5. Let screens, sections and components own spacing.
6. Let components own their geometry and interaction appearance.
7. Keep theme configuration inside the design-system package.
8. Avoid unnecessary tokens and component variants.
9. Do not create new tokens just to accommodate a single arbitrary design choice.
10. Maintain accessibility across every component and theme.

### 14.1 Component catalogue (Widgetbook)

Components are catalogued in Widgetbook. It is a separate app in `widgetbook/`, which depends on `sahaay_design` (and on `sahaay` for feature items) by path, so Widgetbook never ships with the app. Use cases are generated from annotations.

Each component lists its meaningful use cases: default, selected, disabled, error, empty, loading and pressed, where they apply. Keep variants few and intentional.

The catalogue is checked under these addons:

- light and dark theme
- text scale at 100%, 130% and 200%
- small, standard and large devices
- reduced motion

Proposed structure (provisional):

- Foundations
- Layout
- Items
- Fields
- Actions
- Feedback

---

## 15. Design-system evolution

The design system is an evolving product foundation.

When introducing a new role or component:

- Define the problem it solves.
- Define its semantic meaning.
- Explain where it belongs in the content hierarchy.
- Define its visual relationship to existing roles.
- Determine whether an existing component or role already solves the problem.

Do not introduce new terminology without a concrete definition.

A developer should be able to understand the purpose of a role from its name and documentation without inspecting its underlying visual values.

## 16. Guiding principle

Feature developers should primarily work with:

- Pages
- Sections
- Items
- Fields
- Reusable components
- Semantic content roles

They should not repeatedly make independent decisions about:

- Font sizes
- Font weights
- Colours
- Padding
- Margins
- Corner radii
- Shadows
- Animation durations

Those decisions belong to the design system.
