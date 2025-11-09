// lib/f-themes/themes/typography_extension.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  // Styles
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle titleLarge;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
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

  // ---------- Light ----------
  factory AppTypography.light({double scale = 1.0}) {
    // Display: Poppins, Body: Manrope
    final display = GoogleFonts.poppins;
    final body = GoogleFonts.manrope;

    return AppTypography(
      displayLarge: _scale(
          display(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          scale),
      displayMedium: _scale(
          display(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          scale),
      titleLarge: _scale(
          display(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          scale),

      bodyLarge:
          _scale(body(fontSize: 16, color: AppColors.textPrimary), scale),
      bodyMedium:
          _scale(body(fontSize: 14, color: AppColors.textSecondary), scale),
      bodySmall:
          _scale(body(fontSize: 12, color: AppColors.textSecondary), scale),

      buttonText: _scale(
          body(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white),
          scale),
      caption: _scale(
          body(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary),
          scale),

      // Accent—keep subtle (or point to display/body if you don’t want an accent family)
      accentHeading: _scale(
          display(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary),
          scale),
      accentText: _scale(
          display(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primary),
          scale),
    );
  }

  // ---------- Dark ----------
  factory AppTypography.dark({double scale = 1.0}) {
    final display = GoogleFonts.poppins;
    final body = GoogleFonts.manrope;

    return AppTypography(
      displayLarge: _scale(
          display(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppDarkColors.textPrimary),
          scale),
      displayMedium: _scale(
          display(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppDarkColors.textPrimary),
          scale),
      titleLarge: _scale(
          display(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppDarkColors.textPrimary),
          scale),
      bodyLarge:
          _scale(body(fontSize: 16, color: AppDarkColors.textPrimary), scale),
      bodyMedium:
          _scale(body(fontSize: 14, color: AppDarkColors.textSecondary), scale),
      bodySmall:
          _scale(body(fontSize: 12, color: AppDarkColors.textSecondary), scale),
      buttonText: _scale(
          body(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppDarkColors.textPrimary),
          scale),
      caption: _scale(
          body(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppDarkColors.textSecondary),
          scale),
      accentHeading: _scale(
          display(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppDarkColors.primary),
          scale),
      accentText: _scale(
          display(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppDarkColors.primary),
          scale),
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
