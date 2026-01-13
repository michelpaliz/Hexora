import 'package:flutter/material.dart';

class StatementsTableTheme {
  const StatementsTableTheme({
    required this.headerBg,
    required this.headerText,
    required this.rowBg,
    required this.rowBgAlt,
    required this.rowHover,
    required this.rowSelected,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.amountPositive,
    required this.amountNegative,
    required this.chipBg,
    required this.chipText,
  });

  final Color headerBg;
  final Color headerText;
  final Color rowBg;
  final Color rowBgAlt;
  final Color rowHover;
  final Color rowSelected;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color amountPositive;
  final Color amountNegative;
  final Color chipBg;
  final Color chipText;

  factory StatementsTableTheme.light(ColorScheme cs) {
    return StatementsTableTheme(
      headerBg: cs.surfaceContainerHigh,
      headerText: cs.onSurfaceVariant,
      rowBg: cs.surfaceContainerHighest.withOpacity(0.06),
      rowBgAlt: cs.surfaceContainerHighest.withOpacity(0.12),
      rowHover: cs.primary.withOpacity(0.06),
      rowSelected: cs.primaryContainer.withOpacity(0.18),
      border: cs.outlineVariant.withOpacity(0.35),
      textPrimary: cs.onSurface,
      textSecondary: cs.onSurfaceVariant,
      amountPositive: cs.primary,
      amountNegative: cs.error,
      chipBg: cs.surfaceContainerHighest,
      chipText: cs.onSurfaceVariant,
    );
  }

  factory StatementsTableTheme.softDark(ColorScheme cs) {
    return StatementsTableTheme(
      headerBg: const Color(0xFFDDE4EF),
      headerText: cs.onSurfaceVariant,
      rowBg: const Color(0xFFE7ECF4),
      rowBgAlt: const Color(0xFFDDE5F1),
      rowHover: cs.primary.withOpacity(0.08),
      rowSelected: cs.primaryContainer.withOpacity(0.22),
      border: cs.outlineVariant.withOpacity(0.5),
      textPrimary: cs.onSurface,
      textSecondary: cs.onSurfaceVariant,
      amountPositive: cs.primary.withOpacity(0.85),
      amountNegative: cs.error.withOpacity(0.9),
      chipBg: const Color(0xFFE3E9F2),
      chipText: cs.onSurfaceVariant,
    );
  }
}
