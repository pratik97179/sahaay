/// Sahaay's design system (`docs/design-system.md`).
///
/// The only public entry point. Foundations and shared values under `src/`
/// stay private; features use `context.sahaay`, the component token groups
/// and, as they are built, the theme and components.
library;

export 'src/components/actions/action_rows.dart';
export 'src/components/actions/primary_button.dart';
export 'src/components/feedback/confirm_dialog.dart';
export 'src/components/feedback/snackbar.dart';
export 'src/components/feedback/state_message.dart';
export 'src/components/feedback/tag.dart';
export 'src/components/fields/picker_field.dart';
export 'src/components/fields/text_input_field.dart';
export 'src/components/items/item_card.dart' show ItemCard;
export 'src/components/items/photo_tile.dart';
export 'src/components/items/take_panel.dart';
export 'src/components/items/time_card.dart';
export 'src/components/layout/screen.dart';
export 'src/components/layout/section.dart';
export 'src/components/sheets/picker_sheet.dart' show showSahaaySheet;
export 'src/components/sheets/pickers.dart';
export 'src/day/day_light.dart';
export 'src/day/day_marks.dart';
export 'src/day/hold_to_delete.dart';
export 'src/licenses.dart' show registerSahaayDesignLicenses;
export 'src/theme/sahaay_theme.dart';
export 'src/tokens/components.dart';
export 'src/tokens/sahaay_tokens.dart' show SahaayContext, SahaayTokens;
