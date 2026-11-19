// lib/theme/themes/typography_extension.dart
import 'package:flutter/material.dart';
import 'hexora_design_tokens.dart';
export 'hexora_design_tokens.dart';
import 'package:hexora/theme/colors/app_colors.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  // Styles
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle titleLarge;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  // Button widgets supply foreground colors for their variant and state.
  final TextStyle buttonText;
  final TextStyle caption;
  final TextStyle accentHeading;
  final TextStyle accentText;

  const AppTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.titleLarge,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.buttonText,
    required this.caption,
    required this.accentHeading,
    required this.accentText,
  });

  static TextStyle _scale(TextStyle s, double f) =>
      s.copyWith(fontSize: (s.fontSize ?? 14) * f);

  static TextTheme materialTextTheme({required Brightness brightness}) {
    final base = ThemeData(brightness: brightness, useMaterial3: true)
        .textTheme
        .apply(fontFamily: HexoraTypography.fontFamily);
    TextStyle heading(TextStyle? style, double size) => style!.copyWith(
        fontSize: size, fontWeight: FontWeight.w600, letterSpacing: 0);
    TextStyle body(TextStyle? style, double size,
            [FontWeight weight = FontWeight.w400]) =>
        style!.copyWith(fontSize: size, fontWeight: weight, letterSpacing: 0);
    return base.copyWith(
      displayLarge: heading(base.displayLarge, HexoraTypography.pageTitle),
      displayMedium: heading(base.displayMedium, HexoraTypography.pageTitle),
      displaySmall: heading(base.displaySmall, HexoraTypography.pageTitle),
      headlineLarge: heading(base.headlineLarge, HexoraTypography.pageTitle),
      headlineMedium: heading(base.headlineMedium, HexoraTypography.pageTitle),
      headlineSmall: heading(base.headlineSmall, HexoraTypography.pageTitle),
      titleLarge: heading(base.titleLarge, HexoraTypography.pageTitle),
      titleMedium: heading(base.titleMedium, HexoraTypography.sectionTitle),
      titleSmall: heading(base.titleSmall, HexoraTypography.body),
      bodyLarge: body(base.bodyLarge, HexoraTypography.body),
      bodyMedium: body(base.bodyMedium, HexoraTypography.body),
      bodySmall: body(base.bodySmall, HexoraTypography.label),
      labelLarge: body(base.labelLarge, HexoraTypography.body, FontWeight.w500),
      labelMedium:
          body(base.labelMedium, HexoraTypography.label, FontWeight.w500),
      labelSmall: body(base.labelSmall, HexoraTypography.caption),
    );
  }

  factory AppTypography.light({double scale = 1.0}) => _create(
      AppColors.textPrimary, AppColors.textSecondary, AppColors.primary, scale);
  factory AppTypography.dark({double scale = 1.0}) => _create(
      AppDarkColors.textPrimary,
      AppDarkColors.textSecondary,
      AppDarkColors.primary,
      scale);

  static AppTypography _create(
      Color primary, Color secondary, Color accent, double scale) {
    TextStyle style(double size, Color? color,
            [FontWeight weight = FontWeight.w400]) =>
        _scale(
            TextStyle(
                fontFamily: HexoraTypography.fontFamily,
                fontSize: size,
                fontWeight: weight,
                color: color,
                height: 1.4,
                letterSpacing: 0),
            scale);
    return AppTypography(
      displayLarge: style(HexoraTypography.pageTitle, primary, FontWeight.w600),
      displayMedium:
          style(HexoraTypography.pageTitle, primary, FontWeight.w600),
      titleLarge: style(HexoraTypography.pageTitle, primary, FontWeight.w600),
      bodyLarge: style(HexoraTypography.body, primary),
      bodyMedium: style(HexoraTypography.body, secondary),
      bodySmall: style(HexoraTypography.label, secondary),
      buttonText: style(HexoraTypography.body, null, FontWeight.w500),
      caption: style(HexoraTypography.caption, secondary),
      accentHeading:
          style(HexoraTypography.sectionTitle, accent, FontWeight.w600),
      accentText: style(HexoraTypography.body, accent, FontWeight.w500),
    );
  }

  @override
  AppTypography copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? titleLarge,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? buttonText,
    TextStyle? caption,
    TextStyle? accentHeading,
    TextStyle? accentText,
  }) {
    return AppTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      titleLarge: titleLarge ?? this.titleLarge,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      buttonText: buttonText ?? this.buttonText,
      caption: caption ?? this.caption,
      accentHeading: accentHeading ?? this.accentHeading,
      accentText: accentText ?? this.accentText,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    TextStyle lerpStyle(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;

    return AppTypography(
      displayLarge: lerpStyle(displayLarge, other.displayLarge),
      displayMedium: lerpStyle(displayMedium, other.displayMedium),
      titleLarge: lerpStyle(titleLarge, other.titleLarge),
      bodyLarge: lerpStyle(bodyLarge, other.bodyLarge),
      bodyMedium: lerpStyle(bodyMedium, other.bodyMedium),
      bodySmall: lerpStyle(bodySmall, other.bodySmall),
      buttonText: lerpStyle(buttonText, other.buttonText),
      caption: lerpStyle(caption, other.caption),
      accentHeading: lerpStyle(accentHeading, other.accentHeading),
      accentText: lerpStyle(accentText, other.accentText),
    );
  }

  static AppTypography of(BuildContext context) =>
      Theme.of(context).extension<AppTypography>()!;
}
