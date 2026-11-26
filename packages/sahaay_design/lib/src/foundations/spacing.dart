/// The spacious rhythm on a 4-point grid (`docs/design-system.md` §6.1).
abstract final class Spacing {
  /// Between the screen edge and its content.
  static const double screenEdge = 24;

  /// Between two independent sections.
  static const double betweenSections = 64;

  /// Between a section title and its content.
  static const double underSectionTitle = 20;

  /// Between sibling items.
  static const double betweenItems = 16;

  /// Between a card's edge and its content.
  static const double insideCard = 24;

  /// Between adjacent fields.
  static const double betweenFields = 28;

  /// Between a field label and its control.
  static const double underLabel = 8;

  /// Between an icon and its text, or related inline elements.
  static const double besideIcon = 12;

  /// Between rows inside one group: a thin strip of page colour instead of
  /// a dividing line.
  static const double betweenRows = 2;
}
