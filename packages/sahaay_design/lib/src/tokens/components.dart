import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

// Component token groups (`docs/design-system.md` §11.8). Each group is read
// as `context.sahaay.<component>.<part>`. Values come from the shared layer,
// so components that should match cannot drift apart.

Color _c(Color a, Color b, double t) => Color.lerp(a, b, t)!;
TextStyle _s(TextStyle a, TextStyle b, double t) => TextStyle.lerp(a, b, t)!;
T _snap<T>(T a, T b, double t) => t < 0.5 ? a : b;

/// A duration with its curve.
@immutable
final class MotionSpec {
  const MotionSpec(this.duration, this.curve);

  final Duration duration;
  final Curve curve;
}

/// The shared motion group (§9).
@immutable
final class MotionTokens {
  const MotionTokens({
    required this.press,
    required this.appear,
    required this.disappear,
    required this.expand,
    required this.collapse,
    this.reduced = false,
  });

  /// Press feedback: a tint change.
  final MotionSpec press;

  /// Content appearing.
  final MotionSpec appear;

  /// Content leaving.
  final MotionSpec disappear;

  /// Content opening.
  final MotionSpec expand;

  /// Content closing.
  final MotionSpec collapse;

  /// Whether the user asked for reduced motion. When true, components
  /// cross-fade instead of moving or resizing.
  final bool reduced;
}

/// A translucent, frosted material.
@immutable
final class Frost {
  const Frost({required this.blur, required this.tint});

  /// Blur radius applied to the content behind.
  final double blur;

  /// The translucent colour laid over the blurred content.
  final Color tint;

  static Frost lerp(Frost a, Frost b, double t) =>
      Frost(blur: _snap(a.blur, b.blur, t), tint: _c(a.tint, b.tint, t));
}

@immutable
final class ScreenTokens {
  const ScreenTokens({
    required this.background,
    required this.edge,
    required this.title,
    required this.subtitle,
    required this.subtitleGap,
    required this.sectionGap,
    required this.titleMaxScale,
  });

  final Color background;

  /// Space between the screen edge and its content.
  final double edge;
  final TextStyle title;
  final TextStyle subtitle;

  /// Space between the title and the subtitle.
  final double subtitleGap;

  /// Space between two sections.
  final double sectionGap;

  /// The most the screen title grows with the user's text size.
  final double titleMaxScale;

  static ScreenTokens lerp(ScreenTokens a, ScreenTokens b, double t) =>
      ScreenTokens(
        background: _c(a.background, b.background, t),
        edge: _snap(a.edge, b.edge, t),
        title: _s(a.title, b.title, t),
        subtitle: _s(a.subtitle, b.subtitle, t),
        subtitleGap: _snap(a.subtitleGap, b.subtitleGap, t),
        sectionGap: _snap(a.sectionGap, b.sectionGap, t),
        titleMaxScale: _snap(a.titleMaxScale, b.titleMaxScale, t),
      );
}

@immutable
final class TopBarTokens {
  const TopBarTokens({
    required this.frost,
    required this.solidBackground,
    required this.title,
    required this.icon,
  });

  /// The frosted material, or `null` when the bar must be solid (high
  /// contrast).
  final Frost? frost;

  /// The background when [frost] is `null`.
  final Color solidBackground;
  final TextStyle title;
  final Color icon;

  TopBarTokens withoutFrost() => TopBarTokens(
    frost: null,
    solidBackground: solidBackground,
    title: title,
    icon: icon,
  );

  static TopBarTokens lerp(TopBarTokens a, TopBarTokens b, double t) {
    final (fa, fb) = (a.frost, b.frost);
    return TopBarTokens(
      frost: fa != null && fb != null
          ? Frost.lerp(fa, fb, t)
          : _snap(fa, fb, t),
      solidBackground: _c(a.solidBackground, b.solidBackground, t),
      title: _s(a.title, b.title, t),
      icon: _c(a.icon, b.icon, t),
    );
  }
}

@immutable
final class SectionTokens {
  const SectionTokens({required this.title, required this.titleGap});

  final TextStyle title;

  /// Space between the section title and its content.
  final double titleGap;

  static SectionTokens lerp(SectionTokens a, SectionTokens b, double t) =>
      SectionTokens(
        title: _s(a.title, b.title, t),
        titleGap: _snap(a.titleGap, b.titleGap, t),
      );
}

@immutable
final class CardTokens {
  const CardTokens({
    required this.background,
    required this.pressedBackground,
    required this.shape,
    required this.padding,
    required this.gap,
  });

  final Color background;
  final Color pressedBackground;
  final OutlinedBorder shape;
  final EdgeInsets padding;

  /// Space between sibling cards.
  final double gap;

  static CardTokens lerp(CardTokens a, CardTokens b, double t) => CardTokens(
    background: _c(a.background, b.background, t),
    pressedBackground: _c(a.pressedBackground, b.pressedBackground, t),
    shape: _snap(a.shape, b.shape, t),
    padding: _snap(a.padding, b.padding, t),
    gap: _snap(a.gap, b.gap, t),
  );
}

@immutable
final class PhotoTileTokens {
  const PhotoTileTokens({
    required this.photoShape,
    required this.name,
    required this.detail,
    required this.minWidth,
    required this.gap,
  });

  final OutlinedBorder photoShape;
  final TextStyle name;
  final TextStyle detail;

  /// The narrowest a tile may be at 100% text size; grows with text size.
  final double minWidth;

  /// Space between tiles, and between a photo and its name.
  final double gap;

  static PhotoTileTokens lerp(PhotoTileTokens a, PhotoTileTokens b, double t) =>
      PhotoTileTokens(
        photoShape: _snap(a.photoShape, b.photoShape, t),
        name: _s(a.name, b.name, t),
        detail: _s(a.detail, b.detail, t),
        minWidth: _snap(a.minWidth, b.minWidth, t),
        gap: _snap(a.gap, b.gap, t),
      );
}

@immutable
final class TimeCardTokens {
  const TimeCardTokens({
    required this.time,
    required this.schedule,
    required this.note,
    required this.background,
    required this.pressedBackground,
    required this.shape,
    required this.padding,
  });

  final TextStyle time;
  final TextStyle schedule;

  /// The quantity and instruction.
  final TextStyle note;
  final Color background;
  final Color pressedBackground;
  final OutlinedBorder shape;
  final EdgeInsets padding;

  static TimeCardTokens lerp(TimeCardTokens a, TimeCardTokens b, double t) =>
      TimeCardTokens(
        time: _s(a.time, b.time, t),
        schedule: _s(a.schedule, b.schedule, t),
        note: _s(a.note, b.note, t),
        background: _c(a.background, b.background, t),
        pressedBackground: _c(a.pressedBackground, b.pressedBackground, t),
        shape: _snap(a.shape, b.shape, t),
        padding: _snap(a.padding, b.padding, t),
      );
}

@immutable
final class TakePanelTokens {
  const TakePanelTokens({
    required this.background,
    required this.shape,
    required this.padding,
    required this.photoShape,
    required this.name,
    required this.instruction,
  });

  final Color background;
  final OutlinedBorder shape;
  final EdgeInsets padding;
  final OutlinedBorder photoShape;
  final TextStyle name;

  /// The quantity and instruction.
  final TextStyle instruction;

  static TakePanelTokens lerp(TakePanelTokens a, TakePanelTokens b, double t) =>
      TakePanelTokens(
        background: _c(a.background, b.background, t),
        shape: _snap(a.shape, b.shape, t),
        padding: _snap(a.padding, b.padding, t),
        photoShape: _snap(a.photoShape, b.photoShape, t),
        name: _s(a.name, b.name, t),
        instruction: _s(a.instruction, b.instruction, t),
      );
}

@immutable
final class FieldTokens {
  const FieldTokens({
    required this.label,
    required this.labelGap,
    required this.background,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.shape,
    required this.gap,
    required this.errorText,
    required this.errorOutline,
  });

  final TextStyle label;

  /// Space between the label and the control.
  final double labelGap;
  final Color background;
  final TextStyle value;
  final TextStyle placeholder;
  final Color icon;
  final OutlinedBorder shape;

  /// Space between adjacent fields.
  final double gap;
  final TextStyle errorText;
  final Color errorOutline;

  static FieldTokens lerp(FieldTokens a, FieldTokens b, double t) =>
      FieldTokens(
        label: _s(a.label, b.label, t),
        labelGap: _snap(a.labelGap, b.labelGap, t),
        background: _c(a.background, b.background, t),
        value: _s(a.value, b.value, t),
        placeholder: _s(a.placeholder, b.placeholder, t),
        icon: _c(a.icon, b.icon, t),
        shape: _snap(a.shape, b.shape, t),
        gap: _snap(a.gap, b.gap, t),
        errorText: _s(a.errorText, b.errorText, t),
        errorOutline: _c(a.errorOutline, b.errorOutline, t),
      );
}

@immutable
final class ButtonTokens {
  const ButtonTokens({
    required this.background,
    required this.pressedBackground,
    required this.label,
    required this.shape,
    required this.minHeight,
    required this.disabledBackground,
    required this.disabledLabel,
  });

  final Color background;
  final Color pressedBackground;
  final TextStyle label;
  final OutlinedBorder shape;
  final double minHeight;
  final Color disabledBackground;
  final TextStyle disabledLabel;

  static ButtonTokens lerp(ButtonTokens a, ButtonTokens b, double t) =>
      ButtonTokens(
        background: _c(a.background, b.background, t),
        pressedBackground: _c(a.pressedBackground, b.pressedBackground, t),
        label: _s(a.label, b.label, t),
        shape: _snap(a.shape, b.shape, t),
        minHeight: _snap(a.minHeight, b.minHeight, t),
        disabledBackground: _c(a.disabledBackground, b.disabledBackground, t),
        disabledLabel: _s(a.disabledLabel, b.disabledLabel, t),
      );
}

@immutable
final class RowTokens {
  const RowTokens({
    required this.background,
    required this.pressedBackground,
    required this.label,
    required this.icon,
    required this.chevron,
    required this.minHeight,
    required this.groupGap,
  });

  final Color background;
  final Color pressedBackground;
  final TextStyle label;
  final Color icon;
  final Color chevron;
  final double minHeight;

  /// Space between two groups of rows.
  final double groupGap;

  static RowTokens lerp(RowTokens a, RowTokens b, double t) => RowTokens(
    background: _c(a.background, b.background, t),
    pressedBackground: _c(a.pressedBackground, b.pressedBackground, t),
    label: _s(a.label, b.label, t),
    icon: _c(a.icon, b.icon, t),
    chevron: _c(a.chevron, b.chevron, t),
    minHeight: _snap(a.minHeight, b.minHeight, t),
    groupGap: _snap(a.groupGap, b.groupGap, t),
  );
}

@immutable
final class SwitchRowTokens {
  const SwitchRowTokens({
    required this.trackOn,
    required this.trackOff,
    required this.thumb,
    required this.stateNote,
  });

  final Color trackOn;
  final Color trackOff;
  final Color thumb;

  /// The note shown under the row when it is off, such as "Paused".
  final TextStyle stateNote;

  static SwitchRowTokens lerp(SwitchRowTokens a, SwitchRowTokens b, double t) =>
      SwitchRowTokens(
        trackOn: _c(a.trackOn, b.trackOn, t),
        trackOff: _c(a.trackOff, b.trackOff, t),
        thumb: _c(a.thumb, b.thumb, t),
        stateNote: _s(a.stateNote, b.stateNote, t),
      );
}

@immutable
final class DangerRowTokens {
  const DangerRowTokens({required this.label, required this.icon});

  final TextStyle label;
  final Color icon;

  static DangerRowTokens lerp(DangerRowTokens a, DangerRowTokens b, double t) =>
      DangerRowTokens(
        label: _s(a.label, b.label, t),
        icon: _c(a.icon, b.icon, t),
      );
}

@immutable
final class TagTokens {
  const TagTokens({
    required this.background,
    required this.label,
    required this.icon,
    required this.shape,
  });

  final Color background;
  final TextStyle label;
  final Color icon;
  final OutlinedBorder shape;

  static TagTokens lerp(TagTokens a, TagTokens b, double t) => TagTokens(
    background: _c(a.background, b.background, t),
    label: _s(a.label, b.label, t),
    icon: _c(a.icon, b.icon, t),
    shape: _snap(a.shape, b.shape, t),
  );
}

@immutable
final class SheetTokens {
  const SheetTokens({
    required this.background,
    required this.shape,
    required this.handle,
    required this.scrim,
    required this.shadow,
    required this.spring,
  });

  final Color background;
  final OutlinedBorder shape;
  final Color handle;
  final Color scrim;
  final List<BoxShadow> shadow;

  /// The no-bounce spring for opening, closing and dragging, or `null` when
  /// the user asked for reduced motion (the sheet cross-fades instead).
  final SpringDescription? spring;

  SheetTokens withoutSpring() => SheetTokens(
    background: background,
    shape: shape,
    handle: handle,
    scrim: scrim,
    shadow: shadow,
    spring: null,
  );

  static SheetTokens lerp(SheetTokens a, SheetTokens b, double t) =>
      SheetTokens(
        background: _c(a.background, b.background, t),
        shape: _snap(a.shape, b.shape, t),
        handle: _c(a.handle, b.handle, t),
        scrim: _c(a.scrim, b.scrim, t),
        shadow: BoxShadow.lerpList(a.shadow, b.shadow, t) ?? const [],
        spring: _snap(a.spring, b.spring, t),
      );
}

@immutable
final class DialogTokens {
  const DialogTokens({
    required this.background,
    required this.shape,
    required this.title,
    required this.message,
    required this.scrim,
    required this.shadow,
  });

  final Color background;
  final OutlinedBorder shape;
  final TextStyle title;
  final TextStyle message;
  final Color scrim;
  final List<BoxShadow> shadow;

  static DialogTokens lerp(DialogTokens a, DialogTokens b, double t) =>
      DialogTokens(
        background: _c(a.background, b.background, t),
        shape: _snap(a.shape, b.shape, t),
        title: _s(a.title, b.title, t),
        message: _s(a.message, b.message, t),
        scrim: _c(a.scrim, b.scrim, t),
        shadow: BoxShadow.lerpList(a.shadow, b.shadow, t) ?? const [],
      );
}

@immutable
final class SnackbarTokens {
  const SnackbarTokens({required this.background, required this.message});

  final Color background;
  final TextStyle message;

  static SnackbarTokens lerp(SnackbarTokens a, SnackbarTokens b, double t) =>
      SnackbarTokens(
        background: _c(a.background, b.background, t),
        message: _s(a.message, b.message, t),
      );
}

/// Shared by [EmptyStateTokens] and [ErrorStateTokens].
@immutable
final class StateMessageTokens {
  const StateMessageTokens({required this.icon, required this.message});

  final Color icon;
  final TextStyle message;

  static StateMessageTokens lerp(
    StateMessageTokens a,
    StateMessageTokens b,
    double t,
  ) => StateMessageTokens(
    icon: _c(a.icon, b.icon, t),
    message: _s(a.message, b.message, t),
  );
}

/// Shown when a collection has nothing in it yet.
typedef EmptyStateTokens = StateMessageTokens;

/// Shown in place of content that could not be loaded.
typedef ErrorStateTokens = StateMessageTokens;

@immutable
final class FocusTokens {
  const FocusTokens({required this.ring, required this.width});

  /// The visible focus ring.
  final Color ring;
  final double width;

  static FocusTokens lerp(FocusTokens a, FocusTokens b, double t) =>
      FocusTokens(
        ring: _c(a.ring, b.ring, t),
        width: _snap(a.width, b.width, t),
      );
}
