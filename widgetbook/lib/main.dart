import 'package:flutter/material.dart';
import 'package:sahaay_design/sahaay_design.dart';
import 'package:widgetbook/widgetbook.dart';

import 'catalogue/catalogue.dart';
import 'reduced_motion_addon.dart';

void main() {
  registerSahaayDesignLicenses();
  runApp(const SahaayCatalogue());
}

/// Sahaay's component catalogue (`docs/design-system.md` §14.1).
class SahaayCatalogue extends StatelessWidget {
  const SahaayCatalogue({super.key});

  @override
  Widget build(BuildContext context) => Widgetbook.material(
    directories: catalogue,
    addons: [
      // Outermost first: the device sets the screen, then the user's
      // settings (theme, text size, reduced motion) apply inside it.
      ViewportAddon([
        IosViewports.iPhoneSE,
        IosViewports.iPhone13,
        IosViewports.iPhone13ProMax,
      ]),
      MaterialThemeAddon(
        themes: [
          WidgetbookTheme(name: 'Light', data: SahaayTheme.light()),
          WidgetbookTheme(name: 'Dark', data: SahaayTheme.dark()),
        ],
      ),
      TextScaleAddon(min: 1, max: 2, divisions: 10),
      ReducedMotionAddon(),
    ],
  );
}
