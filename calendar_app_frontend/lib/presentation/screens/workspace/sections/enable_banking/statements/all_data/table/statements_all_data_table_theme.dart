import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

/// Banking retains its surface toggle while using the application palette.
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
  final Color headerBg, headerText, rowBg, rowBgAlt, rowHover, rowSelected;
  final Color border,
      textPrimary,
      textSecondary,
      amountPositive,
      amountNegative;
  final Color chipBg, chipText;

  factory StatementsTableTheme.light(ColorScheme cs) =>
      StatementsTableTheme._fromScheme(cs, elevated: false);
  factory StatementsTableTheme.softDark(ColorScheme cs) =>
      StatementsTableTheme._fromScheme(cs, elevated: true);

  factory StatementsTableTheme._fromScheme(ColorScheme cs,
      {required bool elevated}) {
    final surface = elevated ? cs.surfaceContainerLow : cs.surface;
    return StatementsTableTheme(
      headerBg: cs.surfaceContainerLow,
      headerText: cs.onSurfaceVariant,
      rowBg: surface,
      rowBgAlt: surface,
      rowHover: Color.alphaBlend(cs.primary.withValues(alpha: .04), surface),
      rowSelected: Color.alphaBlend(cs.primary.withValues(alpha: .10), surface),
      border: cs.outlineVariant
          .withValues(alpha: HexoraTableTokens.separatorOpacity),
      textPrimary: cs.onSurface,
      textSecondary: cs.onSurfaceVariant,
      amountPositive: cs.primary,
      amountNegative: cs.error,
      chipBg: cs.surfaceContainerHighest,
      chipText: cs.onSurfaceVariant,
    );
  }
}
