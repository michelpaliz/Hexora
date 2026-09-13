import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

/// Native mobile theme. Desktop and web keep their existing themes.
class MobileTheme {
  MobileTheme._();

  static bool isActive(BuildContext context) =>
      Theme.of(context).extension<MobileStatusColors>() != null;

  static ThemeData build(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final background = Color(dark ? 0xFF0F141A : 0xFFF6F8FB);
    final card = Color(dark ? 0xFF1A222C : 0xFFFFFFFF);
    final raised = Color(dark ? 0xFF24303D : 0xFFEDF2F7);
    final border = Color(dark ? 0xFF354252 : 0xFFDCE3EB);
    final text = Color(dark ? 0xFFF3F6FA : 0xFF182230);
    final secondaryText = Color(dark ? 0xFFB5C0CF : 0xFF526173);
    final primary = Color(dark ? 0xFF64B5F6 : 0xFF1565C0);
    final onPrimary = Color(dark ? 0xFF08243A : 0xFFFFFFFF);
    final selected = Color(dark ? 0xFF193A56 : 0xFFDCEBFB);
    final onSelected = Color(dark ? 0xFFBADDFF : 0xFF124F91);
    final error = Color(dark ? 0xFFFFB4AB : 0xFFB3261E);
    final cs = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: base.brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: selected,
      onPrimaryContainer: onSelected,
      secondary: primary,
      onSecondary: onPrimary,
      secondaryContainer: selected,
      onSecondaryContainer: onSelected,
      tertiary: Color(dark ? 0xFFF2C078 : 0xFF815500),
      onTertiary: Color(dark ? 0xFF392600 : 0xFFFFFFFF),
      tertiaryContainer: Color(dark ? 0xFF3B2D18 : 0xFFFFEBC2),
      onTertiaryContainer: Color(dark ? 0xFFF2C078 : 0xFF654200),
      surface: background,
      onSurface: text,
      onSurfaceVariant: secondaryText,
      surfaceDim: background,
      surfaceBright: raised,
      surfaceContainerLowest: background,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: raised,
      surfaceContainerHighest: raised,
      outline: Color(dark ? 0xFF738398 : 0xFF738093),
      outlineVariant: border,
      surfaceTint: Colors.transparent,
      error: error,
      onError: Color(dark ? 0xFF601410 : 0xFFFFFFFF),
      errorContainer: Color(dark ? 0xFF46221F : 0xFFFCE4E1),
      onErrorContainer: error,
    );
    final textTheme = base.textTheme.apply(bodyColor: text, displayColor: text);
    final typography = base.extension<AppTypography>()!;
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: border),
    );
    final buttonText = textTheme.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return base.copyWith(
      colorScheme: cs,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: card,
      dividerColor: border,
      disabledColor: secondaryText.withValues(alpha: 0.38),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge
            ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 16),
        bodySmall:
            textTheme.bodySmall?.copyWith(fontSize: 14, color: secondaryText),
        labelLarge: buttonText,
      ),
      extensions: [
        ...base.extensions.values.where((e) => e is! AppTypography),
        typography.copyWith(
          displayLarge: typography.displayLarge.copyWith(color: text),
          displayMedium: typography.displayMedium.copyWith(color: text),
          titleLarge: typography.titleLarge.copyWith(color: text, fontSize: 20),
          bodyLarge: typography.bodyLarge.copyWith(color: text, fontSize: 16),
          bodyMedium: typography.bodyMedium.copyWith(color: text, fontSize: 16),
          bodySmall:
              typography.bodySmall.copyWith(color: secondaryText, fontSize: 14),
          caption:
              typography.caption.copyWith(color: secondaryText, fontSize: 14),
          buttonText: typography.buttonText.copyWith(fontSize: 16),
          accentHeading: typography.accentHeading.copyWith(color: primary),
          accentText: typography.accentText.copyWith(color: primary),
        ),
        MobileStatusColors(
          success: Color(dark ? 0xFF83D5A5 : 0xFF216E45),
          warning: cs.tertiary,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge
            ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: text, size: 24),
        systemOverlayStyle:
            (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
          color: card,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: shape),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        minimumSize: const Size(48, 48),
        elevation: 0,
        shape: buttonShape,
        textStyle: buttonText,
      )),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: buttonShape,
        textStyle: buttonText,
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: cs.outline),
        minimumSize: const Size(48, 48),
        shape: buttonShape,
        textStyle: buttonText,
      )),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(48, 48),
        textStyle: buttonText,
      )),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: secondaryText,
      )),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: selected,
        secondarySelectedColor: selected,
        checkmarkColor: onSelected,
        // RawChip resolves stateful colors, not stateful TextStyles.
        labelStyle: TextStyle(
          fontFamily: textTheme.bodyMedium?.fontFamily,
          fontSize: 14,
          color: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? secondaryText.withValues(alpha: 0.38)
                  : states.contains(WidgetState.selected)
                      ? onSelected
                      : secondaryText),
        ),
        secondaryLabelStyle: TextStyle(color: onSelected, fontSize: 14),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.all(16),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: primary, width: 2)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: error)),
        focusedErrorBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: error, width: 2)),
        hintStyle: TextStyle(color: secondaryText),
        labelStyle: TextStyle(color: secondaryText),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: secondaryText,
        indicatorColor: primary,
        dividerColor: border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: selected,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? onSelected
                  : secondaryText,
            )),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: secondaryText,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: shape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: raised,
        modalBackgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      dialogTheme: DialogThemeData(
          backgroundColor: raised,
          surfaceTintColor: Colors.transparent,
          shape: shape),
      popupMenuTheme: PopupMenuThemeData(
          color: raised,
          surfaceTintColor: Colors.transparent,
          shape: buttonShape),
      listTileTheme: ListTileThemeData(
        textColor: text,
        iconColor: secondaryText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

@immutable
class MobileStatusColors extends ThemeExtension<MobileStatusColors> {
  const MobileStatusColors({required this.success, required this.warning});
  final Color success;
  final Color warning;

  @override
  MobileStatusColors copyWith({Color? success, Color? warning}) =>
      MobileStatusColors(
          success: success ?? this.success, warning: warning ?? this.warning);

  @override
  MobileStatusColors lerp(covariant MobileStatusColors? other, double t) =>
      other == null
          ? this
          : MobileStatusColors(
              success: Color.lerp(success, other.success, t)!,
              warning: Color.lerp(warning, other.warning, t)!);
}
