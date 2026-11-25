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

Use the following roles.

### 4.1 Typography roles

| Role | Definition | Example |
|---|---|---|
| `type.pageHeading` | Identifies the current screen | Medicine Details |
| `type.sectionHeading` | Identifies an independent content group | Reminders |
| `type.itemHeading` | Identifies an individual entity | Paracetamol |
| `type.primaryValue` | Emphasizes an important value within an item | 9:00 AM |
| `type.body` | Normal readable content | User-provided instructions |
| `type.bodyEmphasis` | Important content requiring greater emphasis | A key instruction |
| `type.supporting` | Explains or qualifies another element | Every Monday and Thursday |
| `type.fieldLabel` | Identifies an attribute or input | Start Date |
| `type.fieldValue` | Displays an entered or read-only field value | 25 November 2026 |
| `type.metadata` | Displays secondary contextual information | Daily |
| `type.actionLabel` | Labels an interactive operation | Save |
| `type.statusLabel` | Identifies an application or item state | Paused |

### 4.2 Typography contracts

Each role represents a complete text style.

Its implementation defines:

- Font family
- Font size
- Font weight
- Line height
- Letter spacing
- Text scaling behaviour

The relationships between the roles must remain consistent.

The hierarchy is:

1. Page heading
2. Section heading
3. Item heading
4. Primary value or emphasized body content
5. Normal body content
6. Supporting content
7. Metadata

This is a hierarchy of visual emphasis, not a rule that every page must use all seven levels.

### 4.3 Typography rules

- A page has one primary page heading.
- Section headings must be subordinate to the page heading.
- Item headings must be subordinate to their section heading.
- Primary values may receive stronger emphasis than item headings when the value is the main information being communicated.
- Labels must remain distinguishable from their values.
- Supporting content and metadata must not compete with primary content.
- Important information must not depend on font weight or size alone.
- Text styles must support accessibility scaling.

Do not create new typography roles for individual screens.

Introduce a new role only when an actual content category cannot be represented by the existing hierarchy.

---

## 5. Colour language

Colours are defined according to the role they fulfil.

Do not select a colour because it looks appropriate in isolation.

### 5.1 Content colours

| Role | Definition |
|---|---|
| `color.content.primary` | Primary readable content |
| `color.content.secondary` | Supporting readable content |
| `color.content.quiet` | Low-emphasis contextual information |
| `color.content.disabled` | Content that cannot currently be interacted with |
| `color.content.inverse` | Content displayed against an inverse surface |

### 5.2 Surface colours

| Role | Definition |
|---|---|
| `color.surface.page` | Main application background |
| `color.surface.content` | Default content background |
| `color.surface.container` | Background of grouped content |
| `color.surface.raised` | Background for visually elevated content |
| `color.surface.input` | Editable input background |
| `color.surface.selected` | Background for selected content |
| `color.surface.disabled` | Background for disabled components |
| `color.surface.overlay` | Background for transient overlays |

### 5.3 Action colours

| Role | Definition |
|---|---|
| `color.action.primary` | Main interactive action |
| `color.action.secondary` | Supporting interactive action |
| `color.action.destructive` | Destructive operation |
| `color.action.disabled` | Disabled action |

Each action role must define both its background and foreground treatment.

### 5.4 Boundary colours

| Role | Definition |
|---|---|
| `color.boundary.subtle` | Low-emphasis visual separation |
| `color.boundary.default` | Standard component boundary |
| `color.boundary.emphasized` | Strong visual boundary |
| `color.boundary.focus` | Visible keyboard or accessibility focus |

### 5.5 State colours

| Role | Definition |
|---|---|
| `color.state.success` | Successful operation |
| `color.state.warning` | Attention required |
| `color.state.danger` | Error or destructive condition |
| `color.state.information` | Informational feedback |

State colours must include appropriate foreground and background mappings.

Do not communicate important states using colour alone.

### 5.6 Colour rules

- Colour roles must retain their meaning across the entire application.
- Light and dark appearances must map to the same semantic roles.
- Components must not select arbitrary palette shades.
- Text and icon foregrounds must remain accessible against their backgrounds.
- Colour must reinforce hierarchy, not replace it.

---

## 6. Layout and spacing

Spacing communicates relationships between elements.

Instead of exposing arbitrary spacing values to feature developers, define spacing according to the relationship between the elements.

### 6.1 Spacing relationships

| Role | Definition |
|---|---|
| `space.pageInset` | Distance between the viewport boundary and the page's main content |
| `space.sectionSeparation` | Distance between two independent sections |
| `space.sectionHeadingContent` | Distance between a section heading and its content |
| `space.itemSeparation` | Distance between sibling items |
| `space.itemInset` | Internal spacing between an item's boundary and its content |
| `space.fieldSeparation` | Distance between adjacent fields |
| `space.fieldLabelControl` | Distance between a field label and its input |
| `space.inlineSeparation` | Distance between related inline elements |
| `space.contentInset` | Internal spacing within a generic content container |

### 6.2 Spacing ownership

| Element | Owner |
|---|---|
| Screen margins | Page layout |
| Separation between sections | Section layout |
| Heading-to-content spacing | Section |
| Internal card padding | Card component |
| Separation between list entries | List layout |
| Label-to-input spacing | Field component |
| Input-to-helper-text spacing | Field component |
| Icon-to-label spacing | Interactive component |

Feature code should compose layouts rather than repeatedly specify padding and margins.

### 6.3 Layout rules

- Related elements must appear visually grouped.
- Independent content groups must have clear separation.
- Internal component spacing must remain consistent.
- Avoid unnecessary nested padding.
- Avoid using arbitrary empty containers to create visual gaps.
- Layout must adapt to available screen space.

The actual spacing scale is centrally configured and must not be exposed as the primary feature-development API.

---

## 7. Shapes and geometry

Shapes communicate component identity and interaction.

Developers should select the appropriate component rather than configure its corner radius.

Define centrally maintained shape roles:

| Role | Intended usage |
|---|---|
| `shape.card` | Standard content card |
| `shape.panel` | Grouped content container |
| `shape.control` | Buttons and interactive controls |
| `shape.input` | Editable fields |
| `shape.chip` | Compact labels and selections |
| `shape.dialog` | Dialog containers |
| `shape.sheet` | Bottom sheets |
| `shape.media` | Images and media containers |
| `shape.pill` | Fully rounded elements |

The component determines which shape it uses.

Avoid arbitrary shape overrides inside features.

A new shape should be introduced only when a meaningful visual distinction exists.

---

## 8. Elevation and depth

Depth establishes visual relationships between content planes.

Use the following roles:

| Role | Intended usage |
|---|---|
| `depth.base` | Normal page content |
| `depth.container` | Content grouped above the page background |
| `depth.raised` | Elevated content |
| `depth.floating` | Floating interactive elements |
| `depth.overlay` | Dialogs and modal surfaces |

Do not use shadows as decoration.

Use surface contrast and boundaries where they communicate hierarchy more effectively.

---

## 9. Motion language

Motion communicates transitions and changes in application state.

Define reusable motion roles:

| Role | Intended usage |
|---|---|
| `motion.interaction` | Immediate feedback from user interaction |
| `motion.expand` | Expanding content |
| `motion.collapse` | Collapsing content |
| `motion.appear` | Newly appearing content |
| `motion.dismiss` | Content being removed |
| `motion.transition` | Navigation or layout transitions |

Each role centrally defines its timing and animation curve.

Rules:

- Motion must have a purpose.
- Avoid unnecessary decorative animation.
- Frequently updating content should not trigger excessive animation.
- Respect reduced-motion preferences.
- Functionality must never depend on an animation completing.

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

Reusable components provide the main interface to the design system.

A component must encapsulate its normal typography, spacing, shape, colours, and interaction states.

### 11.1 Page components

- `PageLayout`
- `PageHeader`
- `PageActions`

`PageLayout` owns overall screen layout and insets.

`PageHeader` owns page heading presentation.

### 11.2 Content components

- `ContentSection`
- `MedicineCard`
- `ReminderCard`
- `ContentList`
- `EmptyState`

`ContentSection` represents the content hierarchy defined in this document.

It owns its heading-to-content relationship and separation from neighboring sections.

`MedicineCard` and `ReminderCard` own their respective entity presentation.

### 11.3 Form components

- `FormField`
- `TextInput`
- `DateInput`
- `TimeInput`
- `SelectionControl`
- `FieldGroup`

Form components own their labels, controls, helper text, and internal spacing.

### 11.4 Action components

- `PrimaryButton`
- `SecondaryButton`
- `DestructiveButton`
- `IconButton`
- `InlineAction`

Each component defines its interaction states and visual treatment.

### 11.5 Feedback components

- `Dialog`
- `BottomSheet`
- `Snackbar`
- `LoadingIndicator`
- `ErrorState`
- `StatusIndicator`

Components must have predictable behavior and accessibility support.

### 11.6 Component rules

- Avoid wrappers that merely rename existing framework components.
- Build reusable components when they enforce consistency or encapsulate meaningful behavior.
- Keep variants intentional and limited.
- Components must consume the central design system.
- Feature code should not override the component's visual decisions without a documented reason.

---

## 12. Responsive design

Responsive behavior must depend on available layout space, not assumptions about device models.

Define layout environments:

- Compact: constrained available content width.
- Regular: comfortable content width.
- Expanded: sufficient space for more complex arrangements.

The system must preserve hierarchy across environments.

Rules:

- Respect system insets.
- Avoid unnecessary fixed dimensions.
- Allow text to wrap.
- Maintain usable touch targets.
- Support accessibility text scaling.
- Do not stretch content indefinitely on wide screens.

---

## 13. Theme architecture

Themes determine how design-system roles resolve.

Support:

- Light appearance
- Dark appearance
- System appearance preference

The semantic API must remain unchanged across appearances.

Theme configuration owns:

- Typography definitions
- Colour mappings
- Shape definitions
- Component styling
- Elevation
- Motion configuration

Feature code must not contain theme-specific raw visual values or manually branch on appearance.

---

## 14. Implementation constraints

1. Define UI structure using the Page → Section → Item → Field hierarchy.
2. Use typography roles according to content meaning.
3. Do not create arbitrary typography styles inside feature widgets.
4. Use semantic colour roles instead of raw palette values.
5. Let layout and reusable components own spacing.
6. Let components own their standard geometry and interaction appearance.
7. Centralize theme configuration.
8. Avoid unnecessary semantic tokens and component variants.
9. Do not create new roles just to accommodate a single arbitrary design choice.
10. Maintain accessibility across every component and theme.

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
