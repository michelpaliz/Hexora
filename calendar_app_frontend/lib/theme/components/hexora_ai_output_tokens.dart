import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/app_colors.dart';

/// Shared surfaces and dimensions for structured Hexora AI output.
abstract final class HexoraAiOutputTokens {
  static const Color panelBackground = AppColors.dashboardTopBar;
  static const Color panelForeground = AppColors.navigationForeground;
  static const Color panelMutedForeground = AppDarkColors.textSecondary;
  static const Color panelBorder = AppDarkColors.border;

  static const Color tableSurface = AppColors.surface;
  static const Color tableHeader = Color(0xFFF1F5FA);
  static const Color tableForeground = Color(0xFF344052);
  static const Color tableHeaderForeground = Color(0xFF24364B);
  static const Color tableBorder = Color(0xFFDCE4F0);
  static const Color tableRowHover = Color(0xFFEEF5FF);
  static const Color tableRowSelected = Color(0xFFE5F0FF);
  static const Color tableRowWarning = Color(0xFFFFFBF3);

  static const double surfaceRadius = 9;
  static const double workspacePadding = 10;
  static const double headerHeight = 38;
  static const double rowMinHeight = 42;
  static const double rowMaxHeight = 48;
  static const double actionRowMinHeight = 46;
  static const double actionRowMaxHeight = 48;
  static const double cellFontSize = 12;
  static const double headerFontSize = 11.5;
}
