import 'package:flutter/material.dart';

/// Centralized spacing and sizing for the notifications inbox so the list rows,
/// section labels, details panel and expenses table stay visually consistent
/// and compact. Prefer these tokens over ad-hoc values in the widgets below.
abstract final class NotifDensity {
  // ── List rows ──────────────────────────────────────────────────────────────
  /// Gap between consecutive notification rows (spec target: 2–4 px).
  static const double rowGap = 3;
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

  /// Subtle fill behind the selected notification row.
  static Color selectedRowFill(ColorScheme cs) =>
      cs.primary.withValues(alpha: 0.08);

  /// Faint tint marking an unread (but unselected) row.
  static Color unreadRowFill(ColorScheme cs) =>
      cs.primary.withValues(alpha: 0.035);

  /// Muted color shared by uppercase section labels.
  static Color sectionLabelColor(ColorScheme cs) =>
      cs.onSurfaceVariant.withValues(alpha: 0.75);
}
