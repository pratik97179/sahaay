import 'package:flutter/material.dart';

import '../day/day_light.dart';
import '../foundations/typefaces.dart';
import 'screen_change_transition.dart';

/// The app theme (`docs/design-system.md` §3): warm paper, light only.
///
/// Screens draw their own surfaces; this sets the page colour, the text
/// font, the screen change and the few Material parts the app still uses.
abstract final class SahaayTheme {
  static ThemeData light() {
    const paper = DayLight.screen;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: paper.ink,
          brightness: Brightness.light,
        ).copyWith(
          primary: paper.ink,
          onPrimary: paper.page,
          surface: paper.page,
          onSurface: paper.ink,
          onSurfaceVariant: paper.soft,
          // No Material tint over surfaces: warm paper stays warm paper.
          surfaceTint: Colors.transparent,
        );
    return ThemeData(
      // One screen change everywhere: grow and fade about the centre (§3).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ScreenChangeTransitionsBuilder(),
          TargetPlatform.iOS: ScreenChangeTransitionsBuilder(),
          TargetPlatform.macOS: ScreenChangeTransitionsBuilder(),
        },
      ),
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: Typefaces.reading,
      package: Typefaces.package,
      scaffoldBackgroundColor: paper.page,
      canvasColor: paper.page,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: paper.ink,
        selectionColor: paper.ink.withValues(alpha: 0.2),
        selectionHandleColor: paper.ink,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: paper.ink,
        contentTextStyle: TextStyle(
          fontFamily: Typefaces.reading,
          package: Typefaces.package,
          color: paper.page,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
    );
  }
}
