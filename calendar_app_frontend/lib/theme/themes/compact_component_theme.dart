import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

/// Desktop density without scaling content or reducing mobile hit targets.
ThemeData compactComponentTheme(ThemeData base) {
  final text = base.textTheme;
  final isLight = base.brightness == Brightness.light;
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(HexoraDimensions.radius),
    borderSide: BorderSide(
      color: isLight ? AppColors.inputBorder : base.colorScheme.outlineVariant,
    ),
  );
  final button = ButtonStyle(
    textStyle: WidgetStatePropertyAll(
      text.labelLarge?.copyWith(
        fontFamily: 'Inter',
        fontSize: HexoraTypography.label,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ),
    minimumSize: const WidgetStatePropertyAll(
        Size(64, HexoraDimensions.buttonStandard)),
    padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
            horizontal: HexoraTableTokens.cellPadding, vertical: 4)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HexoraDimensions.radius))),
    visualDensity: VisualDensity.standard,
    iconSize: const WidgetStatePropertyAll(HexoraDimensions.buttonIconSize),
  );
  return base.copyWith(
    cardTheme: base.cardTheme.copyWith(
      color: isLight ? AppColors.formSection : base.cardTheme.color,
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
      iconSize: const WidgetStatePropertyAll(HexoraDimensions.buttonIconSize),
      minimumSize: const WidgetStatePropertyAll(
          Size.square(HexoraDimensions.buttonStandard)),
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
      backgroundColor: isLight
          ? WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.selectedControl
                  : Colors.transparent)
          : null,
      foregroundColor: isLight
          ? WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? base.colorScheme.onSurface.withValues(alpha: 0.38)
                  : states.contains(WidgetState.selected)
                      ? AppColors.inputFocus
                      : base.colorScheme.onSurface)
          : null,
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
        filled: true,
        fillColor: isLight
            ? WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.disabled)
                    ? const Color(0xFFE7EDF6)
                    : AppColors.inputBackground)
            : base.inputDecorationTheme.fillColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: HexoraTableTokens.cellPadding,
            vertical: HexoraTableTokens.gap),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: text.labelMedium?.copyWith(
          color: base.colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: text.labelMedium?.copyWith(
          color: isLight ? AppColors.inputFocus : base.colorScheme.primary,
        ),
        hintStyle:
            text.bodySmall?.copyWith(color: base.colorScheme.onSurfaceVariant),
        border: isLight ? inputBorder : base.inputDecorationTheme.border,
        enabledBorder:
            isLight ? inputBorder : base.inputDecorationTheme.enabledBorder,
        disabledBorder: isLight
            ? inputBorder.copyWith(
                borderSide: BorderSide(
                  color: AppColors.inputBorder.withValues(alpha: 0.65),
                ),
              )
            : base.inputDecorationTheme.disabledBorder,
        focusedBorder: isLight
            ? inputBorder.copyWith(
                borderSide: const BorderSide(
                  color: AppColors.inputFocus,
                  width: 1.5,
                ),
              )
            : base.inputDecorationTheme.focusedBorder,
        errorBorder: isLight
            ? inputBorder.copyWith(
                borderSide: BorderSide(color: base.colorScheme.error),
              )
            : base.inputDecorationTheme.errorBorder,
        focusedErrorBorder: isLight
            ? inputBorder.copyWith(
                borderSide:
                    BorderSide(color: base.colorScheme.error, width: 1.5),
              )
            : base.inputDecorationTheme.focusedErrorBorder),
    chipTheme: isLight
        ? base.chipTheme.copyWith(
            backgroundColor: AppColors.inputBackground,
            selectedColor: AppColors.selectedControl,
            side: const BorderSide(color: AppColors.inputBorder),
          )
        : base.chipTheme,
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
    // Raw SnackBars across the app get the same floating card as the typed
    // helpers in snack_helper.dart (showErrorSnack/showFailureSnack/...).
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: base.colorScheme.surface,
      elevation: 10,
      width: 480,
      contentTextStyle: text.bodyMedium?.copyWith(
          color: base.colorScheme.onSurface, fontWeight: FontWeight.w500),
      actionTextColor: base.colorScheme.primary,
      closeIconColor: base.colorScheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: base.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    // One quiet scrollbar style for every list: thin and muted until hovered
    // or dragged, so nested panes don't show competing heavy thumbs.
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.dragged)
              ? 8
              : 4),
      radius: const Radius.circular(4),
      crossAxisMargin: 2,
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          base.colorScheme.onSurfaceVariant.withValues(
              alpha: states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.dragged)
                  ? 0.45
                  : 0.22)),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12)),
  );
}
