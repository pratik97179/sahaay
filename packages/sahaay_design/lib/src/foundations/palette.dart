import 'dart:ui';

/// Raw colour values for one appearance (`docs/design-system.md` §5).
///
/// Private to the design system: components and features use tokens, never
/// these values. Values are provisional and are tuned in the catalogue;
/// `test/foundations/contrast_test.dart` keeps every text pair at WCAG AA.
final class Palette {
  const Palette._({
    required this.page,
    required this.card,
    required this.raised,
    required this.text,
    required this.textSoft,
    required this.action,
    required this.onAction,
    required this.danger,
  });

  /// Warm paper: a soft warm off-white page.
  static const light = Palette._(
    page: Color(0xFFF6F2EA),
    card: Color(0xFFECE6DA),
    raised: Color(0xFFE3DBCC),
    text: Color(0xFF2B2622),
    textSoft: Color(0xFF5F574F),
    action: Color(0xFF4A6A5A),
    onAction: Color(0xFFFFFFFF),
    danger: Color(0xFF944639),
  );

  /// Warm paper at night: a warm charcoal, not near-black.
  static const dark = Palette._(
    page: Color(0xFF1F1C19),
    card: Color(0xFF2B2723),
    raised: Color(0xFF36312C),
    text: Color(0xFFF0EAE2),
    textSoft: Color(0xFFB8AFA5),
    action: Color(0xFFA9C4B4),
    onAction: Color(0xFF1F2A24),
    danger: Color(0xFFE3A597),
  );

  /// The screen background.
  final Color page;

  /// A card or grouped area, one warm step off the page.
  final Color card;

  /// The one stronger surface on a screen, such as the take panel.
  final Color raised;

  /// Main readable text: a warm off-black (light) or warm off-white (dark).
  final Color text;

  /// Notes, details and labels.
  final Color textSoft;

  /// Sage: primary actions, selection and focus only.
  final Color action;

  /// Text and icons on [action].
  final Color onAction;

  /// Muted brick: errors and destructive actions only.
  final Color danger;
}
