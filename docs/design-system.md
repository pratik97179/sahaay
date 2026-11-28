# Sahaay — Design

How Sahaay looks, moves and behaves, screen by screen.

## 1. Principles

- **Meaning before appearance.** Each thing on screen is drawn for what it is. Controls are drawn, not worded.
- **Accessible by default.** Text scales, touch targets are at least 48 pt, contrast holds, and Reduce Motion is respected.
- **Calm.** One warm paper colour, one typeface, lowercase and gentle. Health is never shown by colour: nothing is red, "missed" or "late".

## 2. Nothing overflows, on any device


**The interface must never overflow or clip, on any device, in any orientation, at any text size.** It keeps as few hard-coded sizes, spaces and positions as possible.

- **Sizes come from two places only:** the user's text size (`MediaQuery.textScalerOf`), or the space actually available (`LayoutBuilder`, `Expanded`, `Flexible`, `Wrap`, `AspectRatio`, `FractionallySizedBox`). A raw number needs a reason.
- **Flex, don't fix.** Rows use `Expanded` and `Flexible`; collections use `Wrap` or a column count computed from the room available; screens and sheets scroll when content is taller than the space.
- **Text wraps; it is never shrunk to fit.** No `FittedBox` around readable text. Single-line text inside a fixed-height platform bar is limited to the scale the bar can hold, and ends with an ellipsis rather than clipping.
- **Icons grow with their text.** An icon beside text is 1.25 × that text's size at the user's text size; a placeholder icon is a share of the photo it stands in for.
- **Measure, don't guess.** When content must leave room for something else, such as the floating "Add medicine" button, it measures that thing's real size.
- **Touch targets grow, never shrink.** Controls are at least 48 pt and grow with text. The one exception is the 7-column month calendar on very narrow phones, where weekdays must line up; there, each day fills its column and its number is limited to what the column holds.
- **Checked by hand** across small, standard, landscape and tablet sizes at text sizes from 100% to 400%.


## 3. Screens


**Philosophy:** the app is built around the **time of day**. Today is a ruler of the day, and History is organised by days.

**Design language**

- **One colour on every screen: a steady warm off-white, like paper, with warm ink.** It never changes with the time of day. Light mode only.
- **Name and icon.** The app is called **sahaay**, lowercase, on both platforms. The icon is Today's ruler: a bold ink needle in the middle of tick marks that are strong near it and fade to nothing at the edges, on warm paper. Android has it as an adaptive icon with a themed (monochrome) layer.
- **Launch.** The launch screen is warm paper with the icon's needle and ticks in a 240-point box at the centre, the same on iOS, Android 12+ and older Android. When Today has reminders, the needle moves into the ruler's needle and every tick moves sideways and grows or shrinks into one of the ruler's nearest ticks while the paper clears (about 0.9 s). Today's own ruler fades in faintly early on, as if it was always there, so the marks visibly settle into its places; it comes up fully as they land. When opened from a notification, or with Reduce Motion, the launch screen just fades.
- **Typeface: Figtree**, bold for titles such as "november.", with a gentle lowercase voice where it suits ("your prints, day by day."). **QE David Reid** only for what the person writes by hand, such as the sticky note.
- **Icons: Sahaay's own, drawn.** About ten are needed (back, add, edit, pause, delete, camera, history, calendar and a few more). No Material or other stock icon set.
- **Steady layout.** A screen's main content stays still during transitions. A control that appears or disappears (such as **done** on the last step of adding a medicine) keeps its space reserved and fades in place; nothing is pushed up, down or sideways by it.
- **No default buttons.** Each action gets the small control that suits it: information shown on the object itself (the time written on a print), the smallest control that does the job (a small icon switch), physical actions where natural (hold to print, swipe the card, hold to switch views). A full-size button only when nothing else would be clear.

**Today (home)**

- A horizontal **time ruler** with hour labels, quarter-hour ticks, faded ends and a fixed centre needle.
- **Stepping:** swiping left goes to the next reminder, right to the previous one. The ruler follows the finger, then springs to the reminder; it never stops between reminders and resists at the first and last. Arrow keys also step.
- While it moves, the time ticks through the hours and the name and instruction fade out; once it settles they slide back in.
- The **medicine photo** sits above the needle in a **rounded, continuous-corner frame**: never a circle, never a full-screen background. It does not move sideways while the ruler is dragged. Changing reminder: the current photo shrinks into its bottom centre and the next grows out of it.
- The other reminders show on the ruler as small marks: a tiny print (printed), a ring (due, not printed), a small dot (still to come). Nothing is drawn at the needle.
- A **"now"** mark on today's ruler. A date line and a greeting at the top, and at the top right two drawn buttons with a word under each: **medicines** (a small bottle) and **history** (a small stack of prints). They sit level with the first line of the header, the same place on every screen that has header buttons, and wrap onto two rows with large text.
- Tapping the photo opens the reminder screen like any other screen, and the photo grows into its place there. Its header is "‹ today" ("‹ 9 november" on an earlier day); back is the same as everywhere.
- Today's ruler starts fresh each day; earlier days are reached through History.
- **No count of the day:** Today shows no total, counter, progress ring or bar of printed reminders. The ruler already marks each reminder's state.

**Prints (taken)**

- **Hold the photo** (about 0.9 s) to print it: a white paper border develops around the photo, it tilts slightly as if set down, and the time is written on the strip ("taken · 7:42 am"). Letting go early rolls back. Holding again undoes it. A quick tap opens the reminder.
- Only reminders whose time has come (from 30 minutes before) and that aren't paused can be printed, and any reminder on an earlier day.
- Prints are made only by the person. Nothing is ever "missed" or red; an unprinted reminder is neutral.

**History**

- Opens from Today like any other screen. Header: "‹ today", "november.", "your prints, day by day." on the warm paper page.
- **Flipbook:** the month's printed days as white print cards (photo inset, "Nov 16", "3 prints"), with two cards fanned behind. **Only the top card is swiped**, either way: it follows the finger out to that side and tucks in at the bottom of the stack while the next card comes up. The stack cycles; a new swipe always moves the card that is visibly on top. Deeper cards fade in as they rise; nothing jumps or pops. Tapping the top card opens that day.
- **Calendar:** M–S, soft rounded cells without numbers; printed days show their photo filling the cell. Tapping a day opens that day's ruler, starting at its first reminder. A "‹ Nov ⌄ ›" pill below.
- **Switching:** hold the stack and the cards press in a little, then every print flies out to its day in the calendar, one after another, straightening as it goes. Hold a day in the calendar and everything presses in, then the prints gather back into the stack with that day on top.
- A small **view switch** below the book: two square segments (a drawn stack and a drawn grid) on a soft track. Its thumb follows the transition itself, whether the view was switched there or by holding. The switch takes 480 ms; the thumb uses the prints' fast-out curve (Cubic 0.23, 1, 0.32, 1) both ways, so it moves at once and settles softly.

**Your medicines**

- Reached from Today's **medicines** button. Header: "‹ today", "your medicines.", "tap one to see its reminders." ("add the first one with its photo." when there are none).
- **add** is a drawn button at the top right, level with the first header line like Today's buttons: a capsule with a round tablet carrying a plus, the word "add" under it.
- Each medicine is a **print on a shelf**: cream paper with rounded corners (18; the photo inside 12), set at a slight alternating tilt, two to a row on a phone and more on wider screens.
- On each print: the **photo**; the **name** with a small drawn **form mark** (a capsule for oral, a syringe for injectable); a **day strip**, a thin midnight-to-midnight line marked at 6 am, noon and 6 pm, with a dot at each reminder's time (a hollow ring when paused) and a faint tick at now; and one plain line saying **what's next** ("next · today 9:00 am", "next · Thu 7:30 am", "paused", "no reminders yet").
- Tapping a print opens the medicine.

**Adding a medicine**

- **One step at a time**, swiped or stepped through: take its photo → what is it called? → how is it taken? → when? (its reminders) → it's saved.
- An **icon indicator** at the bottom centre: each step is a small dot, and the current one is its drawn icon (camera, pencil, capsule, clock, tick), bold and solid in ink. Changing step, the old icon turns and shrinks into its dot while the new dot turns and grows into its icon. A step whose entry is filled in (a photo taken, a name typed, a form chosen, at least one complete reminder) shows a small upright ink tick in place of its dot while it is not the current step.
- **No save button.** Arriving at the last step saves the medicine. If the photo or the form is missing, it goes back to that step and says what's needed. Once saved, the steps close; the last step shows the medicine as a print, "it's saved.", and "see its reminders ›".
- **The "when?" step** holds the whole reminder on one screen, within the height given, without scrolling:
  - **Times of day** as pills; the one being set is inked and has a small cross to remove it. A drawn **clock with a plus** (no word) adds another time of day. Each time is saved as its own reminder, sharing the schedule, amount and note.
  - A **ruler like Today's** sets the time: drag it under the fixed needle, in 5-minute steps; the other times show as dots on it. Nothing is added until the ruler is first moved.
  - **How often** as a row of words (once, daily, weekly, monthly, yearly), then what that needs. Days of the week and dates of the month sit as cells on one **soft rounded track**: a chosen day fills in ink, and days chosen side by side join into a single run (Mon–Fri reads as one bar). The week fills the width; the month's 31 dates slide sideways with a faded edge. **Daily** reads "every ⊖ 2 ⊕ days", centred, with drawn round steppers. **Yearly** is two sideways dials side by side, the date and the month, each turning over a small ink notch at the bottom, with faded ends, like a camera dial. Every option takes the same height as the day track and sits centred, and each word in the row keeps its bold width, so switching between once, daily, weekly, monthly and yearly moves nothing else on the screen.
  - **Amount and note side by side**, each its own height: the amount only as tall as its dials need, the note a little taller. The amount is a small print with two dials, a number and what it counts ("1 tablet"); it starts empty and never suggests an amount. Under "each time" it shows the medicine's form, its drawn mark and word ("oral" or "injectable"), read-only. The unit dial follows the form: oral offers tablet, capsule, drops, spoon and ml; injectable offers units and ml; before a form is chosen, all of them. A unit already recorded stays on the dial even if the form doesn't list it, so nothing entered is changed. The note is a pale yellow **sticky note** with evenly rounded corners (12), taped and tilted as if pinned, with a soft shadow; what is written on it is in **QE David Reid**, a handwriting face (bundled in `sahaay_design` as `Typefaces.handwriting` with the `handwritten()` style; Latin only); empty, it shows a few drawn scribble lines. Tapping it **lifts it off the page**: the note flies from its place to the middle, growing and straightening, while the page behind blurs and dims. The lifted note carries its own small heading at the top, "note to self", in the rounded Nunito face, soft ink, with no rule or underline; nothing is written on the dimmed page. The note in flight is drawn exactly as it lands (same size, writing or hint, and tick), so nothing changes once it arrives. The keyboard comes only once the note has landed, and the note keeps one size throughout: a little taller than wide (up to 360 wide), using the room above the keyboard without filling it. An ink tick in the note's corner, or a tap outside, flies it back with what was written.
- **Controls are drawn, not worded.** An action is shown by a drawn mark that looks tappable (a stamp, a pill, a stepper), with its meaning given to screen readers; a plain line of text is never the only sign that something can be tapped.

**The medicine page**

- Header like the shelf: "‹ your medicines", the name large, and its form mark with "oral" or "injectable" under it.
- **delete** is a drawn bin at the top right, level with the first header line. Holding it for about a second deletes the medicine, its photo, its reminders and their prints: a ring fills around the bin and its lid lifts while held, and letting go early rolls it back. A quick tap only changes the word under it to "hold". The hold is the confirmation, so there is no dialog.
- The photo, large.
- **reminders**, with the drawn clock with a plus to add one, the day strip of their times, then each reminder as a small paper print: the time, how often, the amount, and the person's note pinned on as a little tilted sticky note in handwriting. A paused reminder is faded and says "· paused". Tapping a print opens that reminder. With none: "no reminders yet."
- The medicine's name, photo and form are not editable.

**The reminder screen**

- Opened from a reminder print on the medicine page, from Today's reminder page and from notifications.
- Header: "‹ " and the medicine's name, "reminder" large, and one line under it. At the top right, drawn **pause** (two bars; it turns to a triangle with "resume" when paused) and the hold-to-delete bin, which deletes only this reminder.
- The medicine's photo and name, then the reminder set with the same controls as Add medicine's "when?" step (one time of day only).
- **Locked until edit:** a saved reminder opens read-only; nothing below the header responds. A drawn pencil with "edit", at the right end of the photo-and-name row, unlocks it; it then shows a tick with "done", which locks it again. While unlocked, every change saves on its own a moment after it is made, and a change still waiting is saved when the screen closes. Paused, the screen is faded and the line reads "paused. it won't notify until resumed."

**Medicine photos**

- A photo that is not a print glows in its own colours: a blurred, brighter copy of the photo sits behind and a little below it as a soft halo, with a thin light rim and a faint sheen across the top, so it reads like glass rather than a flat picture. It applies wherever the photo appears on its own (Today, the reminder page, the medicine page, the Add medicine photo). The halo fades out as a photo develops into a paper print, so prints keep their plain paper look.

**Motion**

- Motion is built from chains, stagger and swaps, at quick timings.
- **One screen change, everywhere.** Every screen opens the same way: the new screen grows from slightly small (92%) to full size about the screen's centre while it fades in. Going back, the leaving screen shrinks and fades out, the exact reverse. Only that one screen moves; the screen beneath stays still. The two screens never show through each other: a still veil of page paper washes the screen beneath out in the first half of the change, and the new screen fades in over clean paper; going back, the leaving screen fades out first and the veil clears last. 420 ms both ways, easing out forward and the same curve reversed going back. Swiping in from the left edge drives it with the finger. With Reduce Motion it is a plain fade. No screen has its own entrance. A photo that appears on both screens flies between them on top of the change.
- **Back is said the same way on every screen:** "‹ " and where it goes ("‹ today", "‹ your medicines", a medicine's name), at the top left, in Figtree bold, soft ink. Tapping it, the system back and the edge swipe all do the same thing.
- **Overlays** (the lifted sticky note) are not screens: they come up over the current screen and animate themselves.
