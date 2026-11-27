# Sahaay — Design Language

> **Makeover in progress.** The visual design built so far (§2.5 and §4–§12: warm paper, condensed headings, sage accent, card-based components) is being replaced. The agreed new direction, the decisions made so far and the open questions are in **§18**. Until the new design language is settled, §3, §13 (architecture) and §12.1 (nothing overflows) still apply; the visual values in §4–§11 describe the current package and will be rewritten.

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

### 2.5 Visual direction (v1, being replaced, see §18)

Sahaay is calm, quiet and spacious. Many users are older, unwell, tired or anxious, and often open the app at the moment a reminder fires. The interface must never hurry or startle them.

- **Warm paper.** Soft warm surfaces in light and dark appearances; no cold or tinted near-black.
- **Two voices.** A bold, large, condensed face for the few things that identify (page, section and item headings, and times); a softer, rounded reading face for everything else.
- **One gentle accent.** A muted sage, used only for actions.
- **Nothing looks urgent unless it is.** Only errors and destructive actions use a state colour.
- **More space than feels necessary.** Sections are separated by space and soft tints, not borders.
- **No medical judgement.** No scores, streaks, "missed", "late" or health colours anywhere. A dose shows as taken only when the person made a print themselves (§18); an unprinted reminder is neutral.

The concrete values are recorded in §4–§9, component behaviour in §11.7, token names in §11.8, the code structure in §13.1, progress in §14.2, and the reasons behind the structure in §17.

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
- **One gentle accent: sage.** A low-saturation green, mid-dark in light (`#4A6A5A`) and soft and pale in dark (`#A9C4B4`). Used only for actions, selection and focus — never for status, doses or decoration.
- **One state colour: danger.** A muted brick (`#944639` light, `#E3A597` dark), used only for errors and destructive actions. There are no success, warning or information colours in v1: paused, saved and informational states use text colours with an icon and words. Add a state colour only when a real case needs it (§15).

### 5.2 Shared colours

These are the design system's internal colours. Components use them; feature code reaches them only through component tokens (§11.8).

| Colour | Meaning | Light | Dark |
|---|---|---|---|
| `page` | The screen background | `#F6F2EA` | `#1F1C19` |
| `card` | A card or grouped area on the page; also the field background | `#ECE6DA` | `#2B2723` |
| `cardPressed` | A card or row while it is being pressed | `#E5DED1` | `#332E29` |
| `raised` | The one stronger surface on a screen, such as the take panel; in dark, also the surface of floating things | `#E3DBCC` | `#36312C` |
| `text` | Main readable text | `#2B2622` | `#F0EAE2` |
| `textSoft` | Notes, details and labels | `#5F574F` | `#B8AFA5` |
| `textDisabled` | Text that cannot currently be used | `#9A9087` | `#6F675F` |
| `action` | Primary actions, selection and the focus ring | `#4A6A5A` | `#A9C4B4` |
| `actionPressed` | A primary action while it is being pressed | `#3F5C4E` | `#BCD3C6` |
| `onAction` | Text and icons on `action` | `#FFFFFF` | `#1F2A24` |
| `danger` | Errors and destructive actions (text, icons, outlines, the confirm button) | `#944639` | `#E3A597` |
| `dangerPressed` | A filled danger button while it is being pressed | `#7F3B30` | `#ECB8AC` |
| `onDanger` | Text on a filled `danger` button | `#FFFFFF` (6.6:1) | `#2A1A16` (8.0:1) |
| `scrim` | The dimmed layer behind sheets and dialogs | black 40% | black 60% |
| `shadow` | The soft shadow under floating things | `#3A2E22` at 12% | none |

Values are provisional and tuned in the catalogue. A test checks every text pair a component draws, on the surface it draws on, at WCAG AA in both appearances; a change that breaks contrast fails the build.

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
| `betweenRows` | Between rows inside one group: a thin strip of page colour instead of a line | 2 |

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

Text fields are the one exception to continuous corners: Flutter's input borders can only draw ordinary rounded corners, so fields use the same 16 radius with standard corners. At this size the difference is barely visible.

Avoid shape overrides inside features. Add a shape only when a meaningful visual distinction exists.

---

## 8. Elevation and depth

Depth shows which things sit above others. Shadows are never decoration.

| Depth | Used for | Treatment |
|---|---|---|
| `flat` | Cards and panels | A warm surface step only; no shadow |
| `frost` | The top bar | The content behind is blurred and covered by the page colour at 72% opacity. Solid page colour when high contrast is on. |
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
- With reduced motion on (`MediaQuery.disableAnimationsOf`), `context.sahaay` resolves the tokens itself: press, expand and collapse take no time; appear and disappear become 120 ms fades; `sheet.spring` is absent, so sheets cross-fade; and `motion.reduced` is true so components can choose a cross-fade over movement.
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

- `ItemCard` — a card on the page; pressable when given `onTap`. Named so it never clashes with Material's `Card`. Its tokens are the `card` group.
- `PhotoTile` — a medicine in the grid: a square photo, then its name and a detail such as the form. Laid out by `PhotoTileGrid`.
- `TimeCard` — a reminder in a list: its time, schedule, note and an optional state tag.
- `TakePanel` — the raised panel at the top of a reminder screen: a 4:3 photo, the name, then the quantity and instruction.

Behaviour shared by items:

- **Press feedback.** A pressable card deepens its tint (`card.pressedBackground`) over `motion.press`; there is no ripple and no scale. A photo tile has no card surface, so it dims slightly (to 72% opacity) while pressed.
- **One button per item.** A pressable card or tile is a single button for screen readers; a photo tile reads as its name and detail ("Test 2, Injectable").
- **Photos never break the layout.** A photo that can't be loaded is replaced by a quiet placeholder at the same size.
- **Internal gaps** between a photo and its text, or a time and its tag, use the shared spacing values (§6.1), not other components' tokens.

### 11.3 Fields

- `TextInputField` — a labelled text input. Named so it never clashes with Material's `TextField`.
- `PickerField` — a labelled field that looks like a text input and opens a picker sheet. Screen readers hear its label and current value ("Time, 9:00 AM").
- Picker sheets, each opened by a function that returns the choice, or `null` when dismissed:

| Function | Shows | Returns |
|---|---|---|
| `showTimeWheelSheet` | A time wheel; follows the device's 12- or 24-hour setting | `TimeOfDay` |
| `showChoiceSheet` | Rows with a check on the chosen one; tapping a row chooses and closes | the chosen value |
| `showMultiChoiceSheet` | Rows that check and uncheck (weekdays); Done is disabled while nothing is chosen | a set of values |
| `showDayOfMonthSheet` | A grid of 31 days with as many columns as fit (up to seven), with a footnote | a set of days |
| `showCalendarSheet` | Sahaay's own month calendar: month navigation, weekday labels and seven flexible columns; the chosen date written out in full; optional "no date" choice. Month and weekday names are passed in | `DateChoice` (a date, or none) |
| `showMonthDaySheet` | Month and day wheels; February offers the 29th | month and day |
| `showSahaaySheet` | Any content in the sheet frame | whatever the sheet pops |

Behaviour shared by fields and sheets:

- **Errors** appear under the control with an icon and words, grow in over `motion.appear`, are announced to screen readers, and give the control a brick outline.
- **All words** — titles, labels, button text, footnotes, month names, the formatted date — are passed in by the feature, so the design system holds no product copy and stays ready for other languages.
- **Sheets** rise along the no-bounce spring (a 350 ms curve sampled from `sheet.spring`), close faster (250 ms, ease-in), and can be dragged down and flung away, tracking the finger. With reduced motion they appear and disappear at once. Content scrolls when it is taller than the screen, so 200% text never clips.
- **Wheel rows** grow with the user's text size, and a wheel shows as many rows as fit in 40% of the screen height (three to five), so it stays usable in landscape and at large text.
- **Day cells** are round, sage when chosen, outlined for today, and quiet when they can't be chosen. They are sized to hold their number at the user's text size and are never smaller than 48 pt, except as described in §12.1 for the month calendar on very narrow phones.

### 11.4 Actions

- `PrimaryButton` — the single filled sage pill for a form's main action; full width, at least 56 pt tall.
- `ActionGroup` — rows on one soft card. Rows are separated by `betweenRows` (a 2 pt strip of page colour), not lines; each group is followed by `row.groupGap` (32).
- `ActionRow` — a full-width row (at least 56 pt) with an icon, a label and, when it opens another screen, a chevron.
- `SwitchRow` — a row with a switch; tapping anywhere on the row toggles it. While off, it shows its note in words (for example "Paused — won't notify until you turn it back on"), which grows in over `motion.appear` and is also read to screen readers.
- `DangerRow` — a destructive row in brick, alone in its own `ActionGroup` at the bottom. The caller confirms before acting.

Rows deepen their tint while pressed, like cards, and read as one button (or one toggle) to screen readers.

### 11.5 Feedback

- `Tag` — a neutral pill with an icon and a word, such as "Paused". Never coloured by state; it wraps if the word is long.
- `showConfirmDialog` / `ConfirmDialog` — confirms a destructive action and resolves to `true` only when confirmed. The title, the message, then a full-width filled brick button (`dialog.confirmBackground`, `onDanger` text, deeper brick while pressed) with a quiet Cancel text button below it. Buttons are stacked, so long labels and large text always fit; the dialog scrolls if it must. With reduced motion it appears at once.
- `showSahaaySnackbar` — a quiet floating message, such as "Reminder saved". Long messages wrap; it leaves on its own.
- `EmptyState` — an icon, a calm message and an optional next step, such as "No medicines yet." with "Add medicine".
- `ErrorState` — the same shape with a brick icon, announced to screen readers; the words carry the meaning, and an optional action offers a way on.

The icon of an empty or error state is 2.5 × its message's size (`stateIconToText`), so it grows with the user's text size.

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
- The number of columns follows the room available: a tile never gets narrower than `photoTile.minWidth` (160) scaled by the user's text size. A 390 pt phone shows two columns at 100% text and one at 200%; a tablet shows four or more. Rows are separated by twice the tile gap so each name stays with its photo.
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
| Days of the month | A grid with as many columns as fit; 31 is explained as "last day of the month". |
| Dates | A month calendar with the full chosen date shown. |
| Yearly | A month-and-day wheel. |
| End date | Offers "No end date"; nothing before the start date can be chosen. |

### 11.8 Component tokens

Tokens are grouped by the component they belong to, and read as `context.sahaay.<component>.<part>`. Each one points to a shared value from §4–§9, so two components that should match cannot drift apart.

| Component | Tokens |
|---|---|
| `screen` | `background`, `edge`, `title`, `subtitle`, `subtitleGap`, `sectionGap`, `titleMaxScale` |
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
| `sheet` | `background`, `shape`, `handle`, `handleSize`, `scrim`, `shadow`, `spring` |
| `dialog` | `background`, `shape`, `title`, `message`, `scrim`, `shadow`, `confirmBackground`, `confirmPressedBackground`, `confirmLabel` |
| `snackbar` | `background`, `message` |
| `emptyState` | `icon`, `message` |
| `errorState` | `icon`, `message` |
| `focus` | `ring`, `width` |
| `motion` | `press`, `appear`, `disappear`, `expand`, `collapse`, `reduced` (§9) |

Values that are not obvious from §4–§9:

- `topBar.title` uses the item title style (condensed 24); `topBar.frost` is absent with high contrast.
- `takePanel.name` uses the section title style (condensed 28); `takePanel.instruction` uses strong body text.
- `row.groupGap` is 32, twice the gap between items.
- `button.minHeight` and `row.minHeight` are 56; `photoTile.minWidth` is 160 at 100% text size.
- `screen.titleMaxScale` is 1.6.
- `emptyState` and `errorState` share one token shape: an icon colour and a message style.

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
- Allow text to wrap.
- Maintain touch targets of at least 48 pt.
- Support accessibility text scaling.
- Do not stretch content indefinitely on wide screens.

### 12.1 Nothing overflows, on any device

**The interface must never overflow or clip, on any device, in any orientation, at any text size.** It keeps as few hard-coded sizes, spaces and positions as possible.

- **Sizes come from three places only:** design tokens, the user's text size (`MediaQuery.textScalerOf`), or the space actually available (`LayoutBuilder`, `Expanded`, `Flexible`, `Wrap`, `AspectRatio`, `FractionallySizedBox`). A raw number in a component needs a named foundation value and a reason.
- **Flex, don't fix.** Rows use `Expanded` and `Flexible`; collections use `Wrap` or a column count computed from the room available; screens and sheets scroll when content is taller than the space.
- **Text wraps; it is never shrunk to fit.** No `FittedBox` around readable text. Single-line text inside a fixed-height platform bar is limited to the scale the bar can hold, and ends with an ellipsis rather than clipping.
- **Icons grow with their text.** An icon beside text is 1.25 × that text's size at the user's text size (`ScaledIcon`); a placeholder icon is a share of the photo it stands in for.
- **Measure, don't guess.** When content must leave room for something else, such as the floating "Add medicine" button, it measures that thing's real size.
- **Touch targets grow, never shrink.** Controls are at least 48 pt and grow with text. The one exception is the 7-column month calendar on very narrow phones, where weekdays must line up; there, each day fills its column and its number is limited to what the column holds.
- **Checked where it matters.** Each component's tests include 200% text on a 320 pt-wide phone in light and dark. Before a component slice is finished, it is checked by hand across small, standard, landscape and tablet sizes at text sizes from 100% to 400%.

Relative sizing values live in one place (`foundations/sizing.dart`):

| Value | Meaning | Value |
|---|---|---|
| `minTouchTarget` | Smallest comfortable touch target | 48 |
| `iconToText` | Icon size relative to its text | 1.25 × |
| `stateIconToText` | Empty and error state icon size relative to the message | 2.5 × |
| `placeholderShare` | Placeholder icon's share of its photo | 30% |
| `maxWheelRows` / `minWheelRows` | Rows a picker wheel shows | 5 / 3 |
| `wheelScreenShare` | Most of the screen height a wheel takes | 40% |

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
  fonts/              Barlow Condensed and Nunito, each with its OFL licence
  test/
  .gitignore          build output stays out of version control
```

The package joins the app through a pub workspace: the root `pubspec.yaml` lists it under `workspace:` and the package declares `resolution: workspace`, so one `flutter pub get` and one lockfile cover all three. The Widgetbook catalogue (`widgetbook/`, §14.1) is the third member.

Rules:

- **Public API.** Only `sahaay_design.dart` is imported from outside. Foundations and shared values stay private; feature code uses components, component tokens and the shared `motion` group.
- **Access.** Tokens are read through `context.sahaay`. They are carried in `ThemeExtension`s, so they follow the theme, switch with light and dark, and rebuild dependants.
- **Accessibility inside the tokens.** Reduced motion, high contrast (the solid top bar) and text scaling are resolved by the design system, not by features.
- **No domain types.** The package never imports the app. Feature-specific items (for example, a medicine tile built from a `Medicine`) live in their feature and are composed from design-system components.
- **Enforcement.** A test fails if code under `lib/features/` imports `sahaay_design/src/`, or uses `Color(`, `Colors.`, `fontSize:` or `TextStyle(`. An exception needs a comment explaining why.
- **Fonts.** Nunito ships as a variable font, so its text styles set the `wght` variation as well as `fontWeight`; Flutter does not move a variable font's weight axis from `fontWeight` alone. Barlow Condensed ships as static Bold and ExtraBold files. `registerSahaayDesignLicenses()` adds both OFL licences to the app's licence page and is called once at start-up.
- **Theme.** `SahaayTheme.light()` and `.dark()` build `ThemeData` from the tokens with their own colour scheme (no seed colour, no Material surface tint) and Nunito as the default family. Ripples are off (`NoSplash`); press feedback is a tint change owned by components. Page transitions stay the platform default.
- **Migration.** Screens move to the new package one reviewed slice at a time. The old `lib/design_system/` is deleted once nothing uses it.
- **Keeping this document true.** Any change to a value, token or behaviour updates this document in the same commit.

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

Components are catalogued in Widgetbook. It is a separate app in `widgetbook/`, a member of the same pub workspace, which depends on `sahaay_design` by path and on `widgetbook` only. It never ships with Sahaay; it is a development tool that runs in Chrome (`cd widgetbook && flutter run -d chrome`) and is not hosted anywhere. Feature items (for example, a medicine tile) join it when the screens move to the package (§14.2, step 7).

The catalogue is written by hand in `widgetbook/lib/catalogue/`, one file per folder. A component change that adds or removes a use case updates the catalogue in the same commit. It shows components only through the public API; foundations are shown through component tokens.

Each component lists its meaningful use cases: default, selected, disabled, error, empty, loading and pressed, where they apply. Keep variants few and intentional. Knobs are used only where they help: editable copy, a long-text switch for checking wrapping, enabled, and a tile count. Picker sheets and the dialog are shown the way a screen opens them, from a field or a row.

Addons:

- device: small (iPhone SE), standard (iPhone 13) and large (iPhone 13 Pro Max)
- theme: light and dark
- text scale: 100% to 200%
- reduced motion: Sahaay's own addon, because Widgetbook has none; it sets `disableAnimations` so `context.sahaay` resolves reduced motion (§9)

Structure: Foundations (text, colour), Layout, Items, Fields (including the picker sheets), Actions, Feedback.

A smoke test (`widgetbook/test/catalogue_test.dart`) builds every use case in light and dark. It is not a device or text-size matrix.

### 14.2 Build progress

| Slice | Contents | State |
|---|---|---|
| 1 | This document: direction, token names, architecture | done |
| 2 | Package scaffold, fonts, foundations, contrast test | done |
| 3 | Tokens, `context.sahaay`, accessibility resolution | done |
| 4 | `SahaayTheme` | done |
| 5a | Layout: `Screen`, `Section` | done |
| 5b | Items: `ItemCard`, `PhotoTile`, `PhotoTileGrid`, `TimeCard`, `TakePanel` | done |
| 5c | Fields: `TextInputField`, `PickerField`, and the picker sheets | done |
| 5d | Actions: `PrimaryButton`, `ActionGroup`, `ActionRow`, `SwitchRow`, `DangerRow` | done |
| 5x | No fixed sizes (§12.1): measured floating action, fitted bar title, icons that scale with text, adaptive day grid, Sahaay's own month calendar, wheels sized to the screen | done |
| 5e | Feedback: `Tag`, `ConfirmDialog`, `Snackbar`, `EmptyState`, `ErrorState` | done |
| 6 | Widgetbook catalogue (`widgetbook/`, web, written by hand) | done |
| 7a | App shell: the app uses the new theme (`AppTheme`, carrying the old theme's values until every screen has moved) and registers the font licences at start-up | done |
| M | **Makeover** (§18): prototypes, then design philosophy, then design language, then the existing `sahaay_design` package updated to it | in progress |
| M1 | The prototype's Today, reminder page and History, ported exactly into `lib/features/day/` on real data, with Today as the home screen. Prints are saved (`prints` table, database version 2 with an upgrade test; deleting a reminder or medicine removes them). Additions the prototype didn't need: an empty day ("nothing for today.", "add a medicine"), "no prints yet this month." in History, a scroll fallback so nothing overflows on small screens or large text, and a status bar that follows the page. Every day screen uses the 1 pm colour while the time-of-day colour is on hold. `sahaay_design` gains Figtree and `DayLight`. Not yet: History in warm off-white and dark mode, drawn icons, Widgetbook entries | in progress |
| M2 | Your medicines (§18.3): the shelf of rounded prints with the day strip and what's next, the drawn **add** button, and Today's **medicines** button. Replaces the old medicines list (`medicines_page.dart`, `medicine_card.dart` removed). Not yet: the medicine page in the new style | in progress |
| M3 | Add medicine (§18.3): one step at a time (photo, name, how it's taken, when, saved) with the drawn icon indicator; saving on arriving at the last step; the "when?" step holding the whole reminder on one screen (time pills, ruler, how often, amount dials, the sticky note). Replaces `add_medicine_page.dart` and the separate draft-reminder screen (`draft_reminder_page.dart` and its route removed). Handwriting font QE David Reid added to `sahaay_design` (its licence for release still to be confirmed). Not yet: the start date and an end date on this step, which stay with the reminder screen | in progress |
| M4 | Shared makeover pieces moved into `sahaay_design` (`src/day/day_marks.dart`): `Paper` colours, `MedPhoto`, `DayStrip`, `FormMark`, `clockText`, and `DayLight.screen` (the 1 pm colour) with `DayLight.withInk`. Features no longer import each other's drawing code; day-only pieces stay in `day_widgets.dart`, and the add button lives in the medicines feature | done |
| M5 | The medicine page (§18.3): header with form mark, hold-to-delete bin, the photo, the day strip and a paper print per reminder with its note. Medicine photos glow in their own colours (`MedPhoto`). Replaces the old Material page | in progress |
| M6 | The reminder screen (§18.3): locked until edit, the "when?" controls, drawn pause and hold-to-delete (`HoldToDelete` moved into `sahaay_design`). The old reminder page and edit page are replaced; Today's "Edit" opens it. Not yet: start and end dates, updated tests | in progress |
| 7b | Medicines home | paused until the makeover |
| 7c | Medicine screen and its reminders section | paused |
| 7d | Reminder screen | paused |
| 7e | Add medicine | paused |
| 7f | Reminder editor | paused |
| 7g | `lib/design_system/` and its tests removed; feature enforcement test | paused |

While the makeover runs, the app's current screens are not updated as the design system changes; they move to the new design system once it is settled.

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

---

## 17. Decisions and rationale

This section records why the design system is built the way it is. It replaces a separate decision record, so this document stays the single source of truth for the design system.

**Context.** The first design system (`lib/design_system/`) mapped roles onto a Material colour scheme generated from one seed colour, with placeholder values and framework vocabulary in its names (`surfaceContainer`, `primaryValue`, `itemInset`). Nothing stopped feature code from using raw colours or sizes. The v1 visual direction (§2.5) called for a rebuild rather than a migration, with tokens named for what they are for.

| Need | Decision | Why |
|---|---|---|
| Where the design system lives | A separate package, `packages/sahaay_design/`, in a pub workspace | The compiler enforces the boundary: the package cannot import the app, and the app cannot reach its private `src/`. It is built fresh without touching existing code. |
| Layering | Foundations → tokens → theme → components, one public barrel | Raw values stay private; features use components and component tokens. |
| Token naming | Grouped by component (`card.background`, `timeCard.time`), each pointing to a shared value | Names say what a value is for. The shared layer keeps matching components from drifting apart. |
| Access | `context.sahaay`, carried in a `ThemeExtension` | Follows the theme, switches with light and dark, rebuilds dependants. `Theme` already is the service, so no separate runtime service is needed. |
| Domain | Components take strings, images and callbacks, never `Medicine` or `Reminder` | Keeps dependencies one-way; feature-specific items live in their feature. |
| Typefaces | Barlow Condensed and Nunito (SIL Open Font License), bundled in the package | Sahaay is local-only, so fonts must not download at runtime; `google_fonts` is not used. Adds about 500 KB. |
| Continuous corners | Flutter's built-in `RoundedSuperellipseBorder` | No package needed. |
| Catalogue | Widgetbook as a separate web app in the workspace, written by hand | Never ships with the app. `widgetbook_generator` 3.24.0 needs `build` 4 and `analyzer` below 14, while the app's `build_runner` (used by Drift) is on `build` 5 and `analyzer` 14; using the generator would mean downgrading the app's code generation. Web needs no signing and is never hosted. |

**Options considered and not taken.**

- A folder inside `lib/`: simpler, but the boundary would rest on convention and a test only.
- A runtime design-system service beside `Theme`: duplicates `Theme`, and Material widgets would not read it.
- Purpose-named shared tokens as the public API (`colors.page`, `text.body`): readable, but component-grouped names were preferred.
- Widgetbook inside the app package: it would ship as an app dependency.
- Generated use cases (`widgetbook_generator`): blocked by the `build` 4 / `build` 5 conflict above. Worth revisiting when the generator supports `build` 5.
- Widgetbook outside the workspace with its own lockfile: avoids the conflict but splits dependency resolution.
- Running the catalogue on macOS or iPhone: needs signing and, on a phone, leaves little room for the addon panels.

**Consequences.**

- The repository has three workspace members (the app, `packages/sahaay_design/`, `widgetbook/`), each analysed and tested on its own.
- Only `widgetbook` (3.25.0) is added, to the catalogue alone; the app's dependencies are unchanged.
- The catalogue is kept in step by hand, in the same commit as the component change.
- A test blocks raw colours, text styles and imports of the package's `src/` from feature code.

---

## 18. Makeover (in progress)

### 18.1 Why

A critique of the built design (impeccable's method, 25 of 36) found it generic: beige cards on a beige page, stock Material icons and controls, and screens stacked as lists of cards. It read as a template, not as Sahaay. The makeover replaces the look and the way people move through the app; the package architecture (§13.1), token naming by component, the no-overflow rule (§12.1) and accessibility (§2.4) stay.

### 18.2 How we work

1. Explore with prototypes and iterate until a decision is made. Since 2026-11-26 this happens in the real app on the iOS simulator. The first Today and History prototype (a standalone Flutter web app) was ported into the app and then deleted (2026-11-27); this section records what it decided.
2. Settle a **design philosophy**, then a **design language**.
3. Update the existing `sahaay_design` package to it. It stays one package; nothing new is created alongside it.
4. Then move the app's screens to it (§14.2, steps 7b–7g). Until then the app's current screens are left as they are.

Every agreed decision is recorded here and in every other document it affects.

References used: Stoic (journal app: monochrome, its own pictograms, a lowercase voice), Wonderous (chained and staggered motion), the iOS Messages photo stack (swipe and spread-to-grid motion), and the product owner's flipbook and calendar mockup.

### 18.3 Agreed so far

**Philosophy:** the app is built around the **time of day**. Today is a ruler of the day, History is organised by days, and on the ruler screen the colour follows the hour.

**Design language**

- **Time-of-day colour only on the ruler screen** (Today, and any past day's ruler). The whole screen's colour shifts smoothly with the time of the reminder under the needle: peach in the morning, light in the afternoon, lilac in the evening, deep blue at night. It is never a health or status colour.
  - **On hold (2026-11-26).** Seen on a phone, the shifting colour didn't explain itself: it follows the reminder under the needle rather than the real time (stepping to a morning reminder at night turns the screen peach), and people read it as a status (the near-grey afternoon looked "disabled" on a paused reminder). Until a clearer approach is chosen, every day screen (Today, earlier days, the reminder screen and History) uses the 1 pm colour. Options raised: follow the real time, carry the colour on the ruler only, or a recognisable sky.
- **Every other screen** (History, the medicine list, adding a medicine, and so on) is a steady **warm off-white**, like paper. History moves from the prototype's blue-grey to this.
- **Dark mode follows the phone.** The other screens turn a soft warm dark grey with light text; the ruler screen keeps its time-of-day colours.
- **Typeface: Figtree** (SIL Open Font License), bold for titles such as "november.", with a gentle lowercase voice where it suits ("your prints, day by day."). **QE David Reid** (copyright David Reid; usage rights to be confirmed before release) only for what the person writes by hand, such as the sticky note.
- **Icons: Sahaay's own, drawn.** About ten are needed (back, add, edit, pause, delete, camera, history, calendar and a few more). No Material or other stock icon set.
- **Steady layout (agreed 2026-11-27).** A screen's main content stays still during transitions. A control that appears or disappears (such as **done** on the last step of adding a medicine) keeps its space reserved and fades in place; nothing is pushed up, down or sideways by it.
- **No default buttons.** Each action gets the small control that suits it: information shown on the object itself (the time written on a print), the smallest control that does the job (the icon switch instead of two text pills), physical actions where natural (hold to print, swipe the card, hold to switch views). A full-size button only when nothing else would be clear. Controls are designed per screen, in prototypes.

**Today (home)**

- A horizontal **time ruler** with hour labels, quarter-hour ticks, faded ends and a fixed centre needle.
- **Stepping:** swiping left goes to the next reminder, right to the previous one. The ruler follows the finger, then springs to the reminder; it never stops between reminders and resists at the first and last. Arrow keys also step.
- While it moves, the time ticks through the hours and the name and instruction fade out; once it settles they slide back in.
- The **medicine photo** sits above the needle in a **rounded, continuous-corner frame**: never a circle, never a full-screen background. It does not move sideways while the ruler is dragged. Changing reminder: the current photo shrinks into its bottom centre and the next grows out of it.
- The other reminders show on the ruler as small marks: a tiny print (printed), a ring (due, not printed), a small dot (still to come). Nothing is drawn at the needle.
- A **"now"** mark on today's ruler. A date line and a greeting at the top, and at the top right two drawn buttons with a word under each: **medicines** (a small bottle) and **history** (a small stack of prints). They sit level with the first line of the header, the same place on every screen that has header buttons, and wrap onto two rows with large text.
- Tapping the photo opens the reminder screen: the photo grows into it, and dragging down returns.
- Today's ruler starts fresh each day; earlier days are reached through History.

**Prints (taken)**

- **Hold the photo** (about 0.9 s) to print it: a white paper border develops around the photo, it tilts slightly as if set down, and the time is written on the strip ("taken · 7:42 am"). Letting go early rolls back. Holding again undoes it. A quick tap opens the reminder.
- Only reminders whose time has come (from 30 minutes before) and that aren't paused can be printed, and any reminder on an earlier day.
- Prints are made only by the person. Nothing is ever "missed" or red; an unprinted reminder is neutral. (PRD 0.4, §3.3, FR-11.)

**History**

- Opens from Today by fading in and growing from the centre. Header: "‹ today", "november.", "your prints, day by day." on a pale blue-grey page (for now the 1 pm colour, as above).
- **Flipbook:** the month's printed days as white print cards (photo inset, "Nov 16", "3 prints"), with two cards fanned behind. **Only the top card is swiped**, either way: it follows the finger out to that side and tucks in at the bottom of the stack while the next card comes up. The stack cycles; a new swipe always moves the card that is visibly on top. Deeper cards fade in as they rise; nothing jumps or pops. Tapping the top card opens that day.
- **Calendar:** M–S, soft rounded cells without numbers; printed days show their photo filling the cell. Tapping a day opens that day's ruler, starting at its first reminder. A "‹ Nov ⌄ ›" pill below.
- **Switching:** hold the stack and the cards press in a little, then every print flies out to its day in the calendar, one after another, straightening as it goes. Hold a day in the calendar and everything presses in, then the prints gather back into the stack with that day on top.
- A small **view switch** below the book: two square segments (a drawn stack and a drawn grid) on a soft track. Its thumb follows the transition itself, whether the view was switched there or by holding.

**Your medicines** (agreed 2026-11-26)

- Reached from Today's **medicines** button. Header: "‹ today", "your medicines.", "tap one to see its reminders." ("add the first one with its photo." when there are none).
- **add** is a drawn button at the top right, level with the first header line like Today's buttons: a capsule with a round tablet carrying a plus, the word "add" under it. Not a plain plus in a box, and not a list card.
- Each medicine is a **print on a shelf**: cream paper with rounded corners (18; the photo inside 12), set at a slight alternating tilt, two to a row on a phone and more on wider screens.
- On each print: the **photo**; the **name** with a small drawn **form mark** (a capsule for oral, a syringe for injectable); a **day strip**, a thin midnight-to-midnight line marked at 6 am, noon and 6 pm, with a dot at each reminder's time (a hollow ring when paused) and a faint tick at now; and one plain line saying **what's next** ("next · today 9:00 am", "next · Thu 7:30 am", "paused", "no reminders yet").
- Tapping a print opens the medicine.

**Adding a medicine** (agreed 2026-11-27)

- **One step at a time**, swiped or stepped through: take its photo → what is it called? → how is it taken? → when? (its reminders) → it's saved.
- An **icon indicator** at the bottom centre: each step is a small dot, and the current one is its drawn icon (camera, pencil, capsule, clock, tick), bold and solid in ink. Changing step, the old icon turns and shrinks into its dot while the new dot turns and grows into its icon.
- **No save button.** Arriving at the last step saves the medicine. If the photo or the form is missing, it goes back to that step and says what's needed. Once saved, the steps close; the last step shows the medicine as a print, "it's saved.", and "see its reminders ›".
- **The "when?" step** (agreed 2026-11-27) holds the whole reminder on one screen, within the height given, without scrolling:
  - **Times of day** as pills; the one being set is inked and has a small cross to remove it. A drawn **clock with a plus** (no word) adds another time of day. Each time is saved as its own reminder, sharing the schedule, amount and note.
  - A **ruler like Today's** sets the time: drag it under the fixed needle, in 5-minute steps; the other times show as dots on it. Nothing is added until the ruler is first moved.
  - **How often** as a row of words (once, daily, weekly, monthly, yearly), then what that needs. Days of the week and dates of the month sit as cells on one **soft rounded track**: a chosen day fills in ink, and days chosen side by side join into a single run (Mon–Fri reads as one bar). The week fills the width; the month's 31 dates slide sideways with a faded edge. **Daily** reads "every ⊖ 2 ⊕ days", centred, with drawn round steppers. **Yearly** is two sideways dials side by side, the date and the month, each turning over a small ink notch at the bottom, with faded ends, like a camera dial. Every option takes the same height as the day track and sits centred, and each word in the row keeps its bold width, so switching between once, daily, weekly, monthly and yearly moves nothing else on the screen. (Rejected: a plain "every 27 november" line and a two-week tile preview; stacked tracks; "every 2nd / 3rd" cells; upright dials, which made the screen jump.) (Rejected: hollow and filled circles, as dated; tall ticks like the time ruler's, as they read as another time dial.)
  - **Amount and note side by side**, the same height. The amount is a small print with two dials, a number and what it counts: tablet, capsule, units, drops or spoon ("1 tablet"); it starts empty and never suggests an amount. The note is a pale yellow **sticky note** with evenly rounded corners (12), taped and tilted as if pinned, with a soft shadow; what is written on it is in **QE David Reid**, a handwriting face (bundled in `sahaay_design` as `Typefaces.handwriting` with the `handwritten()` style; Latin only); empty, it shows a few drawn scribble lines. Tapping it **lifts it off the page**: the note flies from its place to the middle, growing and straightening, while the page behind blurs and dims. The lifted note carries its own small heading at the top, "note to self", in the rounded Nunito face, soft ink, with no rule or underline; nothing is written on the dimmed page. The note in flight is drawn exactly as it lands (same size, writing or hint, and tick), so nothing changes once it arrives. The keyboard comes only once the note has landed, and the note keeps one size throughout: a little taller than wide (up to 360 wide), using the room above the keyboard without filling it. An ink tick in the note's corner, or a tap outside, flies it back with what was written. (Rejected: a note that popped open over a flat dim and shrank when the keyboard came; one strongly rounded corner; the question floating over the dimmed page (in white, on a paper card, in yellow with an oversized handwritten word, in apricot italic); a hint and tick that appeared only after landing; writing that widened on landing; Kalam for the writing; "anything to remember?" over a ruled line.)
  - No end date on this step; it can be set later on the reminder.
- **Controls are drawn, not worded.** An action is shown by a drawn mark that looks tappable (a stamp, a pill, a stepper), with its meaning given to screen readers; a plain line of text is never the only sign that something can be tapped. Rejected along the way: "+ another time" as plain text (unclear, and didn't look tappable), the A/B/C layouts' "until" row, and the separate "add a reminder" screen.

**The medicine page** (agreed 2026-11-27)

- Header like the shelf: "‹ your medicines", the name large, and its form mark with "oral" or "injectable" under it.
- **delete** is a drawn bin at the top right, level with the first header line. Holding it for about a second deletes the medicine, its photo, its reminders and their prints: a ring fills around the bin and its lid lifts while held, and letting go early rolls it back. A quick tap only changes the word under it to "hold". The hold is the confirmation (PRD §5.4), so there is no dialog.
- The photo, large.
- **reminders**, with the drawn clock with a plus to add one, the day strip of their times, then each reminder as a small paper print: the time, how often, the amount, and the person's note pinned on as a little tilted sticky note in handwriting. A paused reminder is faded and says "· paused". Tapping a print opens that reminder. With none: "no reminders yet."
- Editing the medicine's name, photo or form stays out of v1 (PRD §10).

**The reminder screen** (agreed 2026-11-27)

- Opened from a reminder print on the medicine page, from Today's reminder page and from notifications.
- Header: "‹ " and the medicine's name, "reminder" large, and one line under it. At the top right, drawn **pause** (two bars; it turns to a triangle with "resume" when paused) and the hold-to-delete bin, which deletes only this reminder.
- The medicine's photo and name, then the reminder set with the same controls as Add medicine's "when?" step (one time of day only).
- **Locked until edit:** a saved reminder opens read-only; nothing below the header responds. A drawn pencil with "edit", at the right end of the photo-and-name row, unlocks it; it then shows a tick with "done", which locks it again. While unlocked, every change saves on its own a moment after it is made, and a change still waiting is saved when the screen closes. Paused, the screen is faded and the line reads "paused. it won't notify until resumed."
- Not yet: the start and end dates.

**Medicine photos** (agreed 2026-11-27)

- A photo that is not a print glows in its own colours: a blurred, brighter copy of the photo sits behind and a little below it as a soft halo, with a thin light rim and a faint sheen across the top, so it reads like glass rather than a flat picture. It applies wherever the photo appears on its own (Today, the reminder page, the medicine page, the Add medicine photo). The halo fades out as a photo develops into a paper print, so prints keep their plain paper look. (Rejected: the plain grey drop shadow, as dull.)

**Motion**

- `flutter_animate`, used only inside `sahaay_design` behind Sahaay's own helpers (enter, stagger, pop), with Sahaay's motion tokens and Reduce Motion handled inside. Agreed, but on hold until the motion work resumes.
- Wonderous's structure (chains, stagger, swap) is borrowed; its slower showcase timings are not.

### 18.4 Rejected along the way, and why

- **Medicine list as one medicine at a time, or as a tight contact sheet:** the shelf of prints was chosen. **An "add a medicine" card as the first print, then a dashed one:** moved to a header button for consistency with Today. **A plain plus, or a plus in a box, for add; a tablet with a score line:** a box reads as a stock button, and a line through a tablet reads as a minus or a "no" sign.

- **Recolouring the built design** (Daylight with rounded cards and pills): still read as a Google template. The structure had to change, not the paint.
- **A full-bleed photo as the screen background:** the previous, framed version was better.
- **The photo in a circle:** replaced by a rounded frame.
- **A 24-hour dial you spin:** not obvious what to do with it. Replaced by the stepping horizontal ruler.
- **A tick badge in the photo's corner, or a pill with text, for "taken":** stock patterns. Replaced by the print.
- **"Ink" (ink filling the photo) and "Flip" (the photo turning over) for taken:** the print was preferred.
- **History as a winding string of days:** first too cramped, then needed scrolling. Replaced by the flipbook and calendar.
- **Buttons to page through the flipbook, and swiping anywhere on screen:** only the top card itself is swiped.
- **Swiping right to bring back the previous card:** a real stack doesn't do that; either way sends the top card to the bottom.
- **A full-width text switch, then an upright switch beside the book:** too big, then awkward. Replaced by the small icon switch under the book.
- **Mobbin research:** the Mobbin MCP refuses on the current plan, so references came from Stoic's App Store screenshots, the Wonderous source, screen recordings and the product owner's mockup.

### 18.5 Next steps

**Decided (2026-11-26): replace the screens in place**, on `feat/design-system-package`. Each old screen is swapped for its new one directly, with no switch between old and new UI; until every screen is done the app is part old, part new. (Building beside the old UI behind a switch was considered and not chosen.)

1. Tidy the small pieces of logic that sit in UI files (add-medicine validation, a reminder-date rule, the add-medicine reminders hook that also builds widgets, wording helpers).
2. Add the missing logic, one slice each: reminders on a given day across all medicines; prints (table, repository, the "can be printed" rule, a database upgrade with a migration test); the month summary for History.
3. Update `sahaay_design` to the new language: Figtree, the colours, the drawn icons, and the new components (ruler, print, stack, calendar, switch), each in Widgetbook with tests.
4. Replace the screens one slice each: Today, the reminder screen, History, then the rest once designed. Each slice removes the old screen it replaces.
5. When the last old screen is gone, delete `lib/design_system/`.

**Next to prototype:** the start and end dates on the reminder screen, then Add reminder from the medicine page (still the old editor).

### 18.6 Open

- The other screens in the new style: the medicine list, adding a medicine, the reminder screen in detail, editing a reminder.
- The exact colours of each hour and of the warm off-white and dark grey, and their contrast checks.
- History's month switching (the arrows on the "Nov" pill), and History across months.
- Accessibility of the ruler and History: large text, VoiceOver (a plain list behind them), Reduce Motion.

