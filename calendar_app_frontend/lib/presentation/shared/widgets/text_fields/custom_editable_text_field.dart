import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/theme/colors/theme_colors.dart';

class CustomEditableTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final int? maxLength;
  final bool isMultiline;
  final IconData? prefixIcon;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final Color? iconColor; // Optional override for icon
  final Color? backgroundColor; // Optional override for fill color
  final TextStyle? counterStyle; // External counter style override

  const CustomEditableTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.maxLength,
    this.isMultiline = false,
    this.prefixIcon,
    this.labelStyle,
    this.textStyle,
    this.iconColor,
    this.backgroundColor,
    this.counterStyle,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final fill = backgroundColor ?? ThemeColors.inputFillLighter(context);
    final onFill = ThemeColors.contrastOn(fill);
    final textColor = ThemeColors.textPrimary(context);

    final radius = BorderRadius.circular(12.0);
    OutlineInputBorder baseBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
            borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: isMultiline ? null : 1,
      cursorColor: cs.primary,
      style: textStyle ??
          t.bodyLarge.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
            height: isMultiline ? 1.35 : null,
          ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: labelStyle ??
            t.bodyMedium.copyWith(
              color: onFill.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
        floatingLabelStyle: t.bodyMedium.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.25,
        ),
        filled: true,
        fillColor: fill,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: iconColor ?? onFill, size: 20),

        counterStyle:
            counterStyle ?? t.caption.copyWith(color: onFill.withValues(alpha: 0.85)),

        // Borders
        border: baseBorder(cs.outlineVariant.withValues(alpha: 0.4)),
        enabledBorder: baseBorder(cs.outlineVariant.withValues(alpha: 0.4)),
        focusedBorder: baseBorder(cs.primary, 1.6),
        disabledBorder: baseBorder(cs.outlineVariant.withValues(alpha: 0.25)),
        errorBorder: baseBorder(cs.error),
        focusedErrorBorder: baseBorder(cs.error, 1.6),
      ),
    );
  }
}
