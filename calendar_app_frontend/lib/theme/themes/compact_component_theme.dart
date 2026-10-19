import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

/// Desktop density without scaling content or reducing mobile hit targets.
ThemeData compactComponentTheme(ThemeData base) {
  final text = base.textTheme;
  final button = ButtonStyle(
    textStyle: WidgetStatePropertyAll(text.labelLarge),
    minimumSize:
        const WidgetStatePropertyAll(Size(64, HexoraDimensions.button)),
    padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HexoraDimensions.radius))),
    visualDensity: VisualDensity.standard,
  );
  return base.copyWith(
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexoraDimensions.radius)),
    ),
    dividerTheme: DividerThemeData(
      color: base.colorScheme.outlineVariant
          .withValues(alpha: HexoraTableTokens.separatorOpacity),
      thickness: HexoraTableTokens.separatorWidth,
      space: HexoraTableTokens.gap,
    ),
    listTileTheme: base.listTileTheme.copyWith(
      minTileHeight: HexoraTableTokens.rowMinHeight,
      titleTextStyle: text.bodyMedium,
      subtitleTextStyle: text.bodySmall,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: HexoraTableTokens.cellPadding),
    ),
    searchBarTheme: base.searchBarTheme.copyWith(
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(text.bodyMedium),
      hintStyle: WidgetStatePropertyAll(text.bodySmall),
      shape: button.shape,
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      textStyle: text.bodyMedium,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexoraDimensions.radius)),
    ),
    datePickerTheme: base.datePickerTheme.copyWith(
      headerHeadlineStyle: text.titleLarge,
      dayStyle: text.bodyMedium,
      weekdayStyle: text.labelMedium,
    ),
    iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
      iconSize: const WidgetStatePropertyAll(HexoraTableTokens.icon),
      minimumSize:
          const WidgetStatePropertyAll(Size.square(HexoraDimensions.button)),
      padding:
          const WidgetStatePropertyAll(EdgeInsets.all(HexoraDimensions.space)),
      shape: button.shape,
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? base.colorScheme.onSurface.withValues(alpha: .38)
              : base.colorScheme.onSurfaceVariant),
    )),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: button.copyWith(
      textStyle: WidgetStatePropertyAll(text.labelMedium),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
    )),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.merge(button) ?? button),
    filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.merge(button) ?? button),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.merge(button) ?? button),
    textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.merge(button) ?? button),
    appBarTheme:
        base.appBarTheme.copyWith(toolbarHeight: HexoraDimensions.toolbar),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: HexoraTableTokens.cellPadding,
            vertical: HexoraTableTokens.gap),
        labelStyle: text.labelMedium,
        floatingLabelStyle: text.labelMedium,
        hintStyle:
            text.bodySmall?.copyWith(color: base.colorScheme.onSurfaceVariant)),
    dataTableTheme: base.dataTableTheme.copyWith(
        headingTextStyle: text.labelMedium,
        dataTextStyle: text.bodyMedium,
        headingRowHeight: HexoraTableTokens.headingHeight,
        dataRowMinHeight: HexoraTableTokens.rowMinHeight,
        dataRowMaxHeight: double.infinity,
        horizontalMargin: HexoraTableTokens.pagePadding,
        columnSpacing: HexoraTableTokens.cellPadding * 2,
        dividerThickness: HexoraTableTokens.separatorWidth),
    dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: text.titleLarge, contentTextStyle: text.bodyMedium),
    tabBarTheme: base.tabBarTheme.copyWith(
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12)),
  );
}
