import 'package:flutter/material.dart';

import '../foundations/motion.dart';
import '../foundations/palette.dart';
import '../foundations/spacing.dart';
import 'components.dart';
import 'shared.dart';

/// Every component token group for one appearance
/// (`docs/design-system.md` §11.8), carried in the theme.
///
/// Read it with `context.sahaay`, which also applies the user's reduced
/// motion and high contrast settings.
@immutable
final class SahaayTokens extends ThemeExtension<SahaayTokens> {
  const SahaayTokens({
    required this.brightness,
    required this.screen,
    required this.topBar,
    required this.section,
    required this.card,
    required this.photoTile,
    required this.timeCard,
    required this.takePanel,
    required this.field,
    required this.button,
    required this.row,
    required this.switchRow,
    required this.dangerRow,
    required this.tag,
    required this.sheet,
    required this.dialog,
    required this.snackbar,
    required this.emptyState,
    required this.errorState,
    required this.focus,
    required this.motion,
  });

  factory SahaayTokens._from(Shared s) {
    final p = s.palette;
    final cardPadding = const EdgeInsets.all(Spacing.insideCard);
    return SahaayTokens(
      brightness: p.brightness,
      screen: ScreenTokens(
        background: p.page,
        edge: Spacing.screenEdge,
        title: s.screenTitle,
        subtitle: s.note,
        subtitleGap: Spacing.underLabel,
        sectionGap: Spacing.betweenSections,
        titleMaxScale: 1.6,
      ),
      topBar: TopBarTokens(
        frost: Frost(blur: 24, tint: p.page.withValues(alpha: 0.72)),
        solidBackground: p.page,
        title: s.itemTitle,
        icon: p.text,
      ),
      section: SectionTokens(
        title: s.sectionTitle,
        titleGap: Spacing.underSectionTitle,
      ),
      card: CardTokens(
        background: p.card,
        pressedBackground: p.cardPressed,
        shape: s.card,
        padding: cardPadding,
        gap: Spacing.betweenItems,
      ),
      photoTile: PhotoTileTokens(
        photoShape: s.photo,
        name: s.itemTitle,
        detail: s.detail,
        minWidth: 160,
        gap: Spacing.betweenItems,
      ),
      timeCard: TimeCardTokens(
        time: s.time,
        schedule: s.note,
        note: s.detail,
        background: p.card,
        pressedBackground: p.cardPressed,
        shape: s.card,
        padding: cardPadding,
      ),
      takePanel: TakePanelTokens(
        background: p.raised,
        shape: s.panel,
        padding: cardPadding,
        photoShape: s.photo,
        name: s.sectionTitle,
        instruction: s.bodyStrong,
      ),
      field: FieldTokens(
        label: s.label,
        labelGap: Spacing.underLabel,
        background: p.card,
        value: s.body,
        placeholder: s.body.copyWith(color: p.textSoft),
        icon: p.textSoft,
        shape: s.field,
        gap: Spacing.betweenFields,
        errorText: s.note.copyWith(color: p.danger),
        errorOutline: p.danger,
      ),
      button: ButtonTokens(
        background: p.action,
        pressedBackground: p.actionPressed,
        label: s.button.copyWith(color: p.onAction),
        shape: Shared.pill,
        minHeight: 56,
        disabledBackground: p.card,
        disabledLabel: s.button.copyWith(color: p.textDisabled),
      ),
      row: RowTokens(
        background: p.card,
        pressedBackground: p.cardPressed,
        label: s.body,
        icon: p.text,
        chevron: p.textSoft,
        minHeight: 56,
        groupGap: Spacing.betweenItems * 2,
      ),
      switchRow: SwitchRowTokens(
        trackOn: p.action,
        trackOff: p.textDisabled,
        thumb: p.page,
        stateNote: s.note,
      ),
      dangerRow: DangerRowTokens(
        label: s.body.copyWith(color: p.danger),
        icon: p.danger,
      ),
      tag: TagTokens(
        background: p.raised,
        label: s.tag,
        icon: p.textSoft,
        shape: Shared.pill,
      ),
      sheet: SheetTokens(
        background: s.floatingSurface,
        shape: s.sheet,
        handle: p.textDisabled,
        handleSize: const Size(40, 4),
        scrim: p.scrim,
        shadow: s.floatingShadow,
        spring: Motion.sheetSpring,
      ),
      dialog: DialogTokens(
        background: s.floatingSurface,
        shape: s.dialog,
        title: s.sectionTitle,
        message: s.body,
        scrim: p.scrim,
        shadow: s.floatingShadow,
      ),
      snackbar: SnackbarTokens(
        background: p.text,
        message: s.body.copyWith(color: p.page),
      ),
      emptyState: StateMessageTokens(icon: p.textSoft, message: s.note),
      errorState: StateMessageTokens(icon: p.danger, message: s.note),
      focus: FocusTokens(ring: p.action, width: 3),
      motion: const MotionTokens(
        press: MotionSpec(Motion.press, Motion.easeOut),
        appear: MotionSpec(Motion.appear, Motion.easeOutStrong),
        disappear: MotionSpec(Motion.disappear, Motion.easeIn),
        expand: MotionSpec(Motion.expand, Motion.easeOut),
        collapse: MotionSpec(Motion.expand, Motion.easeOut),
      ),
    );
  }

  /// Warm paper.
  static final SahaayTokens light = SahaayTokens._from(Shared(Palette.light));

  /// Warm charcoal.
  static final SahaayTokens dark = SahaayTokens._from(Shared(Palette.dark));

  /// Motion when the user asked for reduced motion: nothing moves or
  /// resizes; content cross-fades briefly or changes at once.
  static const reducedMotion = MotionTokens(
    press: MotionSpec(Duration.zero, Curves.easeOut),
    appear: MotionSpec(Duration(milliseconds: 120), Curves.easeOut),
    disappear: MotionSpec(Duration(milliseconds: 120), Curves.easeOut),
    expand: MotionSpec(Duration.zero, Curves.easeOut),
    collapse: MotionSpec(Duration.zero, Curves.easeOut),
    reduced: true,
  );

  final Brightness brightness;
  final ScreenTokens screen;
  final TopBarTokens topBar;
  final SectionTokens section;
  final CardTokens card;
  final PhotoTileTokens photoTile;
  final TimeCardTokens timeCard;
  final TakePanelTokens takePanel;
  final FieldTokens field;
  final ButtonTokens button;
  final RowTokens row;
  final SwitchRowTokens switchRow;
  final DangerRowTokens dangerRow;
  final TagTokens tag;
  final SheetTokens sheet;
  final DialogTokens dialog;
  final SnackbarTokens snackbar;
  final EmptyStateTokens emptyState;
  final ErrorStateTokens errorState;
  final FocusTokens focus;
  final MotionTokens motion;

  /// These tokens adjusted for the user's accessibility settings.
  SahaayTokens resolve({
    required bool reduceMotion,
    required bool highContrast,
  }) {
    if (!reduceMotion && !highContrast) return this;
    return _copy(
      topBar: highContrast ? topBar.withoutFrost() : topBar,
      sheet: reduceMotion ? sheet.withoutSpring() : sheet,
      motion: reduceMotion ? reducedMotion : motion,
    );
  }

  SahaayTokens _copy({
    required TopBarTokens topBar,
    required SheetTokens sheet,
    required MotionTokens motion,
  }) => SahaayTokens(
    brightness: brightness,
    screen: screen,
    topBar: topBar,
    section: section,
    card: card,
    photoTile: photoTile,
    timeCard: timeCard,
    takePanel: takePanel,
    field: field,
    button: button,
    row: row,
    switchRow: switchRow,
    dangerRow: dangerRow,
    tag: tag,
    sheet: sheet,
    dialog: dialog,
    snackbar: snackbar,
    emptyState: emptyState,
    errorState: errorState,
    focus: focus,
    motion: motion,
  );

  /// Tokens are complete sets per appearance; they are not edited piecemeal.
  @override
  SahaayTokens copyWith() => this;

  /// Blends colours and text styles so a light/dark switch animates
  /// smoothly; sizes, shapes and motion switch at the midpoint.
  @override
  SahaayTokens lerp(SahaayTokens? other, double t) {
    if (other == null) return this;
    final b = other;
    return SahaayTokens(
      brightness: t < 0.5 ? brightness : b.brightness,
      screen: ScreenTokens.lerp(screen, b.screen, t),
      topBar: TopBarTokens.lerp(topBar, b.topBar, t),
      section: SectionTokens.lerp(section, b.section, t),
      card: CardTokens.lerp(card, b.card, t),
      photoTile: PhotoTileTokens.lerp(photoTile, b.photoTile, t),
      timeCard: TimeCardTokens.lerp(timeCard, b.timeCard, t),
      takePanel: TakePanelTokens.lerp(takePanel, b.takePanel, t),
      field: FieldTokens.lerp(field, b.field, t),
      button: ButtonTokens.lerp(button, b.button, t),
      row: RowTokens.lerp(row, b.row, t),
      switchRow: SwitchRowTokens.lerp(switchRow, b.switchRow, t),
      dangerRow: DangerRowTokens.lerp(dangerRow, b.dangerRow, t),
      tag: TagTokens.lerp(tag, b.tag, t),
      sheet: SheetTokens.lerp(sheet, b.sheet, t),
      dialog: DialogTokens.lerp(dialog, b.dialog, t),
      snackbar: SnackbarTokens.lerp(snackbar, b.snackbar, t),
      emptyState: StateMessageTokens.lerp(emptyState, b.emptyState, t),
      errorState: StateMessageTokens.lerp(errorState, b.errorState, t),
      focus: FocusTokens.lerp(focus, b.focus, t),
      motion: t < 0.5 ? motion : b.motion,
    );
  }
}

/// `context.sahaay`: the design-system tokens for this part of the tree,
/// adjusted for the user's reduced motion and high contrast settings.
extension SahaayContext on BuildContext {
  SahaayTokens get sahaay {
    final tokens = Theme.of(this).extension<SahaayTokens>();
    assert(
      tokens != null,
      'No SahaayTokens in the theme. Add SahaayTokens.light or '
      'SahaayTokens.dark to ThemeData.extensions.',
    );
    return tokens!.resolve(
      reduceMotion: MediaQuery.maybeDisableAnimationsOf(this) ?? false,
      highContrast: MediaQuery.maybeHighContrastOf(this) ?? false,
    );
  }
}
