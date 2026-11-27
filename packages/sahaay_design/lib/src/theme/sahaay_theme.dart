import 'package:flutter/material.dart';

import '../foundations/palette.dart';
import '../foundations/radii.dart';
import '../foundations/typefaces.dart';
import '../tokens/sahaay_tokens.dart';
import 'lift_transition.dart';

/// The app theme (`docs/design-system.md` §13): `ThemeData` built from the
/// design tokens, with [SahaayTokens] attached for `context.sahaay`.
///
/// The Material widgets that components build on are themed here, so they
/// look right without per-widget styling. Page transitions stay the
/// platform default.
abstract final class SahaayTheme {
  static ThemeData light() => _build(Palette.light, SahaayTokens.light);

  static ThemeData dark() => _build(Palette.dark, SahaayTokens.dark);

  static ThemeData _build(Palette p, SahaayTokens t) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.action,
      onPrimary: p.onAction,
      secondary: p.action,
      onSecondary: p.onAction,
      error: p.danger,
      onError: p.page,
      surface: p.page,
      onSurface: p.text,
      onSurfaceVariant: p.textSoft,
      surfaceContainerLowest: p.page,
      surfaceContainerLow: p.card,
      surfaceContainer: p.card,
      surfaceContainerHigh: p.raised,
      surfaceContainerHighest: p.raised,
      outline: p.textSoft,
      outlineVariant: p.cardPressed,
      inverseSurface: p.text,
      onInverseSurface: p.page,
      scrim: p.scrim,
      shadow: p.shadow,
      // No Material tint over surfaces: warm paper stays warm paper.
      surfaceTint: Colors.transparent,
    );

    bool pressed(Set<WidgetState> s) => s.contains(WidgetState.pressed);
    bool disabled(Set<WidgetState> s) => s.contains(WidgetState.disabled);
    bool selected(Set<WidgetState> s) => s.contains(WidgetState.selected);

    return ThemeData(
      // Every screen change lifts in as a card (§18.3).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: LiftPageTransitionsBuilder(),
          TargetPlatform.iOS: LiftPageTransitionsBuilder(),
          TargetPlatform.macOS: LiftPageTransitionsBuilder(),
        },
      ),
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: Typefaces.reading,
      package: Typefaces.package,
      scaffoldBackgroundColor: t.screen.background,
      canvasColor: t.screen.background,
      // Press feedback is a tint change owned by components, not a ripple.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      focusColor: t.focus.ring.withValues(alpha: 0.16),
      iconTheme: IconThemeData(color: p.text),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.action,
        selectionColor: p.action.withValues(alpha: 0.3),
        selectionHandleColor: p.action,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.topBar.solidBackground,
        foregroundColor: t.topBar.icon,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: t.topBar.title,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => disabled(s)
                ? t.button.disabledBackground
                : pressed(s)
                ? t.button.pressedBackground
                : t.button.background,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => disabled(s)
                ? t.button.disabledLabel.color
                : t.button.label.color,
          ),
          textStyle: WidgetStatePropertyAll(t.button.label),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(t.button.shape),
          minimumSize: WidgetStatePropertyAll(Size(64, t.button.minHeight)),
          elevation: const WidgetStatePropertyAll(0),
          animationDuration: t.motion.press.duration,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(p.action),
          textStyle: WidgetStatePropertyAll(
            t.button.label.copyWith(color: p.action),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(t.button.shape),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(t.switchRow.thumb),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => selected(s) ? t.switchRow.trackOn : t.switchRow.trackOff,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.field.background,
        hintStyle: t.field.placeholder,
        labelStyle: t.field.label,
        errorStyle: t.field.errorText,
        prefixIconColor: t.field.icon,
        suffixIconColor: t.field.icon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        // Input borders cannot use continuous corners; the radius matches
        // the field shape.
        border: _fieldBorder(Colors.transparent, 0),
        enabledBorder: _fieldBorder(Colors.transparent, 0),
        focusedBorder: _fieldBorder(t.focus.ring, t.focus.width),
        errorBorder: _fieldBorder(t.field.errorOutline, 2),
        focusedErrorBorder: _fieldBorder(t.field.errorOutline, t.focus.width),
        disabledBorder: _fieldBorder(Colors.transparent, 0),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.dialog.background,
        shape: t.dialog.shape,
        titleTextStyle: t.dialog.title,
        contentTextStyle: t.dialog.message,
        barrierColor: t.dialog.scrim,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.sheet.background,
        modalBackgroundColor: t.sheet.background,
        modalBarrierColor: t.sheet.scrim,
        shape: t.sheet.shape,
        showDragHandle: true,
        dragHandleColor: t.sheet.handle,
        elevation: 0,
        modalElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.snackbar.background,
        contentTextStyle: t.snackbar.message,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.action),
      extensions: [t],
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(Radii.field)),
        borderSide: width == 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
}
