import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';

/// The app's themes: Sahaay's design system (`packages/sahaay_design`).
abstract final class AppTheme {
  static ThemeData light() => SahaayTheme.light();

  static ThemeData dark() => SahaayTheme.dark();
}
