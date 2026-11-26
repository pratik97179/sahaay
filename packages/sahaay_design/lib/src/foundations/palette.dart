import 'dart:ui';

/// Raw colour values for one appearance (`docs/design-system.md` §5).
///
/// Private to the design system: components and features use tokens, never
/// these values. Values are provisional and are tuned in the catalogue;
/// the contrast tests keep every text pair at WCAG AA.
final class Palette {
  const Palette._({
    required this.brightness,
    required this.page,
    required this.card,
    required this.cardPressed,
    required this.raised,
    required this.text,
    required this.textSoft,
    required this.textDisabled,
    required this.action,
    required this.actionPressed,
    required this.onAction,
    required this.danger,
    required this.scrim,
    required this.shadow,
  });

  /// Warm paper: a soft warm off-white page.
  static const light = Palette._(
    brightness: Brightness.light,
    page: Color(0xFFF6F2EA),
    card: Color(0xFFECE6DA),
    cardPressed: Color(0xFFE5DED1),
    raised: Color(0xFFE3DBCC),
    text: Color(0xFF2B2622),
    textSoft: Color(0xFF5F574F),
    textDisabled: Color(0xFF9A9087),
    action: Color(0xFF4A6A5A),
    actionPressed: Color(0xFF3F5C4E),
    onAction: Color(0xFFFFFFFF),
    danger: Color(0xFF944639),
    scrim: Color(0x66000000),
    shadow: Color(0x1F3A2E22),
  );

  /// Warm paper at night: a warm charcoal, not near-black.
  static const dark = Palette._(
    brightness: Brightness.dark,
    page: Color(0xFF1F1C19),
    card: Color(0xFF2B2723),
    cardPressed: Color(0xFF332E29),
    raised: Color(0xFF36312C),
    text: Color(0xFFF0EAE2),
    textSoft: Color(0xFFB8AFA5),
    textDisabled: Color(0xFF6F675F),
    action: Color(0xFFA9C4B4),
    actionPressed: Color(0xFFBCD3C6),
    onAction: Color(0xFF1F2A24),
    danger: Color(0xFFE3A597),
    scrim: Color(0x99000000),
    // Shadows don't read on a dark page; floating things use [raised].
    shadow: Color(0x00000000),
  );

  /// Which appearance these values belong to.
  final Brightness brightness;

  /// The screen background.
  final Color page;

  /// A card or grouped area, one warm step off the page. Also the background
  /// of editable fields.
  final Color card;

  /// A card while it is being pressed.
  final Color cardPressed;

  /// The one stronger surface on a screen, such as the take panel. In dark
  /// appearance, also the surface of floating things in place of a shadow.
  final Color raised;

  /// Main readable text: a warm off-black (light) or warm off-white (dark).
  final Color text;

  /// Notes, details and labels.
  final Color textSoft;

  /// Text that cannot currently be used.
  final Color textDisabled;

  /// Sage: primary actions, selection and focus only.
  final Color action;

  /// A primary action while it is being pressed.
  final Color actionPressed;

  /// Text and icons on [action].
  final Color onAction;

  /// Muted brick: errors and destructive actions only.
  final Color danger;

  /// The dimmed layer behind sheets and dialogs.
  final Color scrim;

  /// The soft shadow under floating things; transparent in dark appearance.
  final Color shadow;
}
