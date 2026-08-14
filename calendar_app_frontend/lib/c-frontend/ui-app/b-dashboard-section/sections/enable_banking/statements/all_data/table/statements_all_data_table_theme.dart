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
    if (cs.brightness == Brightness.dark) {
      return _coolBlueDark(elevated: false);
    }
    return StatementsTableTheme(
      headerBg: const Color(0xFFF8FAFC),
      headerText: const Color(0xFF374151),
      rowBg: cs.surface,
      rowBgAlt: const Color(0xFFFCFDFE),
      rowHover: const Color(0xFFF8FAFC),
      rowSelected: cs.primaryContainer.withValues(alpha: 0.26),
      border: const Color(0xFFE5E7EB),
      textPrimary: cs.onSurface,
      textSecondary: cs.onSurfaceVariant,
      amountPositive: cs.primary,
      amountNegative: cs.error,
      chipBg: const Color(0xFFF1F5F9),
      chipText: cs.onSurfaceVariant,
    );
  }

  factory StatementsTableTheme.softDark(ColorScheme cs) {
    if (cs.brightness == Brightness.dark) {
      return _coolBlueDark(elevated: true);
    }
    return StatementsTableTheme(
      headerBg: const Color(0xFFD9E2EE),
      headerText: cs.onSurfaceVariant,
      rowBg: const Color(0xFFF3F6FA),
      rowBgAlt: const Color(0xFFEEF2F7),
      rowHover: const Color(0xFFF8FAFC),
      rowSelected: cs.primaryContainer.withValues(alpha: 0.22),
      border: const Color(0xFFD7DEE8),
      textPrimary: cs.onSurface,
      textSecondary: cs.onSurfaceVariant,
      amountPositive: cs.primary.withValues(alpha: 0.85),
      amountNegative: cs.error.withValues(alpha: 0.9),
      chipBg: const Color(0xFFE8EDF4),
      chipText: cs.onSurfaceVariant,
    );
  }

  static StatementsTableTheme _coolBlueDark({required bool elevated}) {
    return StatementsTableTheme(
      headerBg: elevated ? const Color(0xFF1D2B40) : const Color(0xFF172235),
      headerText: const Color(0xFFDCEAFF),
      rowBg: elevated ? const Color(0xFF162131) : const Color(0xFF111925),
      rowBgAlt: elevated ? const Color(0xFF162131) : const Color(0xFF111925),
      rowHover: elevated ? const Color(0xFF223650) : const Color(0xFF1B2D45),
      rowSelected: elevated ? const Color(0xFF1D466F) : const Color(0xFF183B62),
      border: elevated ? const Color(0xFF3A506B) : const Color(0xFF2D4058),
      textPrimary: const Color(0xFFE8EEF7),
      textSecondary: const Color(0xFFA9B8CC),
      amountPositive: const Color(0xFF64B5FF),
      amountNegative: const Color(0xFFFF6B7C),
      chipBg: elevated ? const Color(0xFF223247) : const Color(0xFF1C293A),
      chipText: const Color(0xFFC7D5E8),
    );
  }
}
