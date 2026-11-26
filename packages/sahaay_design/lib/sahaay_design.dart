/// Sahaay's design system (`docs/design-system.md`).
///
/// The only public entry point. Foundations and shared values under `src/`
/// stay private; features use `context.sahaay`, the component token groups
/// and, as they are built, the theme and components.
library;

export 'src/licenses.dart' show registerSahaayDesignLicenses;
export 'src/theme/sahaay_theme.dart';
export 'src/tokens/components.dart';
export 'src/tokens/sahaay_tokens.dart' show SahaayContext, SahaayTokens;
