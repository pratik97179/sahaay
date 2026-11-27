import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/app/app_theme.dart';
import 'package:sahaay_design/sahaay_design.dart';

void main() {
  for (final (name, theme, brightness) in [
    ('light', AppTheme.light(), Brightness.light),
    ('dark', AppTheme.dark(), Brightness.dark),
  ]) {
    group('$name app theme', () {
      test("is built from Sahaay's design system", () {
        expect(theme.brightness, brightness);
        expect(theme.extension<SahaayTokens>(), isNotNull);
        expect(
          theme.colorScheme,
          (brightness == Brightness.light
                  ? SahaayTheme.light()
                  : SahaayTheme.dark())
              .colorScheme,
        );
      });
    });
  }
}
