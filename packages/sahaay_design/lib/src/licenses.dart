import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled fonts' SIL Open Font License texts to the app's licence
/// page, as the licence requires. Call once at start-up, before `runApp`.
void registerSahaayDesignLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, path) in _licenses) {
      final text = await rootBundle.loadString(path);
      yield LicenseEntryWithLineBreaks([font], text);
    }
  });
}

const _licenses = [
  ('Barlow Condensed', 'packages/sahaay_design/fonts/barlow_condensed/OFL.txt'),
  ('Nunito', 'packages/sahaay_design/fonts/nunito/OFL.txt'),
];
