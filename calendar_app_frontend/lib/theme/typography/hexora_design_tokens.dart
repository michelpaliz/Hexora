import 'dart:ui' show FontFeature;

abstract final class HexoraTypography {
  static const fontFamily = 'Inter';
  static const numericFeatures = [FontFeature.tabularFigures()];
  static const double pageTitle = 18;
  static const double sectionTitle = 14;
  static const double body = 13;
  static const double label = 12;
  static const double caption = 11;
}

abstract final class HexoraDimensions {
  static const double space = 4;
  static const double toolbar = 52;
  static const double button = 32;
  static const double touchTarget = 48;
  static const double radius = 8;
  static const double calendarPanel = 304;
  static const double calendarDayHeader = 48;
}

abstract final class HexoraTableTokens {
  static const double rowMinHeight = 52;
  static const double compactRowMinHeight = rowMinHeight;
  static const double headingHeight = 36;
  static const double pagePadding = 16;
  static const double cellPadding = 12;
  static const double rowPadding = 4;
  static const double gap = 8;
  static const double icon = 18;
  static const double actionColumn = 104;
  static const double searchWidth = 280;
  static const double separatorOpacity = .18;
  static const double separatorWidth = .5;
  static const double badgeHorizontalPadding = 6;
  static const double badgeVerticalPadding = 2;
}

abstract final class HexoraDocumentTokens {
  static const double rowHeight = 60;
  static const double statusColumn = 120;
  static const double amountColumn = 144;
  static const double icon = 17;
  static const double statusIconSlot = 18;
  static const double monthHeadingHeight = 22;
  static const double tabsHeight = 36;
  static const double filterHeight = 34;
}
