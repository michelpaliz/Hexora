import 'package:flutter/material.dart';

/// Centralized spacing and sizing for the notifications inbox so the list rows,
/// section labels, details panel and expenses table stay visually consistent
/// and compact. Prefer these tokens over ad-hoc values in the widgets below.
abstract final class NotifDensity {
  // ── List rows ──────────────────────────────────────────────────────────────
  /// Gap between consecutive notification rows: rows sit on the canvas, so a
  /// hairline gap is enough to separate them.
  static const double rowGap = 1;
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(8, 6, 4, 6);
  static const double rowRadius = 8;
  static const double iconBox = 30;
  static const double iconGlyph = 16;
  static const double iconTextGap = 10;

  // ── Section headings ────────────────────────────────────────────────────────
  static const EdgeInsets sectionHeaderPadding =
      EdgeInsets.fromLTRB(2, 8, 2, 3);
  static const double sectionLabelSize = 10;
  static const double sectionLabelSpacing = 0.8;

  // ── Details panel ────────────────────────────────────────────────────────────
  static const EdgeInsets detailsPadding = EdgeInsets.fromLTRB(14, 10, 14, 12);
  static const EdgeInsets detailRowPadding =
      EdgeInsets.symmetric(vertical: 4.5);
  static const EdgeInsets footerPadding = EdgeInsets.fromLTRB(14, 8, 14, 8);

  // ── Expenses table ──────────────────────────────────────────────────────────
  static const double tableHeadingHeight = 32;
  static const double tableRowMinHeight = 36;
  static const double tableRowMaxHeight = 44;
  static const double tableHorizontalMargin = 10;
  static const double tableColumnSpacing = 14;
  static const double tableDividerThickness = 0.6;

  /// The only prominent row fill: the selected notification. Unread status is
  /// carried by a blue dot and title weight, never by a background.
  static Color selectedRowFill(ColorScheme cs) => cs.primary
      .withValues(alpha: cs.brightness == Brightness.dark ? 0.20 : 0.11);

  /// Transient hover tint, clearly lighter than the selected fill.
  static Color hoverRowFill(ColorScheme cs) =>
      cs.primary.withValues(alpha: 0.045);

  /// Muted, uniform timestamp colour (no pill/background).
  static Color timestampColor(ColorScheme cs) =>
      cs.onSurfaceVariant.withValues(alpha: 0.8);

  /// Duration for selection/hover colour changes and the details fade.
  static const Duration transition = Duration(milliseconds: 150);

  /// Muted color shared by uppercase section labels.
  static Color sectionLabelColor(ColorScheme cs) =>
      cs.onSurfaceVariant.withValues(alpha: 0.75);
}
